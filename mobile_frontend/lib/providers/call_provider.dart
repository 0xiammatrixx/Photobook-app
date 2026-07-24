import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_frontend/services/chat_socket.dart';

enum CallStatus { idle, outgoing, incoming, connected, ended }

class CallProvider extends ChangeNotifier {
  final ChatSocket _socket = ChatSocket();

  CallStatus status = CallStatus.idle;
  bool isVideoCall = false;
  bool isMuted = false;
  bool isCameraOff = false;
  bool isSpeakerOn = true;
  String? lastError;

  String? conversationId;
  String? peerUserId;
  String? peerName;
  String? peerAvatarUrl;

  DateTime? _connectedAt;
  Duration get callDuration => _connectedAt == null
      ? Duration.zero
      : DateTime.now().difference(_connectedAt!);

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];
  Map<String, dynamic>? _pendingOfferSdp;
  bool _renderersReady = false;

  /// Set once from the app root (see main.dart) so an incoming call can
  /// pop a full-screen UI no matter which screen the person is on.
  VoidCallback? onIncomingCall;

  /// Set once from the app root — looks up a user's display name/avatar
  /// from already-loaded conversation data. Incoming call events only
  /// carry `fromUserId` (no name/avatar), so without this the callee's
  /// screen would just show a blank generic avatar.
  Map<String, String?>? Function(String userId)? resolvePeerInfo;

  bool _signalingRegistered = false;

  /// Call once at app startup — safe to call before or after the socket
  /// actually connects, since ChatSocket stores these handlers and reads
  /// them dynamically whenever an event arrives.
  void registerSignaling() {
    if (_signalingRegistered) return;
    _signalingRegistered = true;
    _socket.setCallHandlers(
      onCallOffer: _onRemoteOffer,
      onCallAnswer: _onRemoteAnswer,
      onIceCandidate: _onRemoteIceCandidate,
      onCallEnd: _onRemoteEnd,
      onCallDecline: _onRemoteDecline,
    );
  }

  Future<bool> requestCallPermissions(bool video) async {
    final permissions = <Permission>[
      Permission.microphone,
      if (video) Permission.camera,
    ];
    final statuses = await permissions.request();
    final granted = statuses.values.every((s) => s.isGranted);
    if (!granted) {
      lastError = 'Camera/microphone permission is required for calls.';
      notifyListeners();
    }
    return granted;
  }

  Future<void> _ensureRenderers() async {
    if (_renderersReady) return;
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    _renderersReady = true;
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };
    final pc = await createPeerConnection(config);

    pc.onIceCandidate = (candidate) {
      if (conversationId == null || candidate.candidate == null) return;
      _socket.sendIceCandidate(
        conversationId: conversationId!,
        candidate: {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
        notifyListeners();
      }
    };

    pc.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        if (status != CallStatus.connected) {
          status = CallStatus.connected;
          _connectedAt = DateTime.now();
          notifyListeners();
        }
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        // Fallback for the other side hanging up — there's no call:end
        // event in the documented schema, so this is how we notice if
        // the backend hasn't added one yet. Slower than a real signal.
        if (status != CallStatus.ended && status != CallStatus.idle) {
          endCall(notifyPeer: false);
        }
      }
    };

    return pc;
  }

  Future<void> _getLocalMedia({required bool video}) async {
    final constraints = {
      'audio': true,
      'video': video ? {'facingMode': 'user'} : false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    localRenderer.srcObject = _localStream;
    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }
  }

  Future<void> startCall({
    required String conversationId,
    required String peerUserId,
    required String peerName,
    String? peerAvatarUrl,
    required bool isVideo,
  }) async {
    if (status != CallStatus.idle) return;

    final granted = await requestCallPermissions(isVideo);
    if (!granted) {
      // Was previously a silent `return` — left the call screen (already
      // pushed by the caller) stuck showing nothing forever, with no
      // indication anything went wrong.
      _failAndClose(lastError ?? 'Camera/microphone permission is required.');
      return;
    }

    this.conversationId = conversationId;
    this.peerUserId = peerUserId;
    this.peerName = peerName;
    this.peerAvatarUrl = peerAvatarUrl;
    isVideoCall = isVideo;
    status = CallStatus.outgoing;
    lastError = null;
    notifyListeners();

    try {
      await _ensureRenderers();
      _pc = await _createPeerConnection();
      await _getLocalMedia(video: isVideo);

      final offer = await _pc!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': isVideo,
      });
      await _pc!.setLocalDescription(offer);

      _socket.sendCallOffer(
        conversationId: conversationId,
        offer: {'sdp': offer.sdp, 'type': offer.type, 'isVideo': isVideo},
      );
      notifyListeners();
    } catch (e) {
      lastError = 'Could not start the call: $e';
      _cleanup();
    }
  }

  void _onRemoteOffer(String fromUserId, String convId, Map offer) {
    if (status != CallStatus.idle) {
      // Already on/starting a call — there's no "busy" signal in the
      // schema, so the caller will just see this ring with no answer.
      return;
    }
    conversationId = convId;
    peerUserId = fromUserId;
    final info = resolvePeerInfo?.call(fromUserId);
    peerName = info?['name'] ?? peerName;
    peerAvatarUrl = info?['avatarUrl'] ?? peerAvatarUrl;
    isVideoCall = offer['isVideo'] == true;
    _pendingOfferSdp = Map<String, dynamic>.from(offer);
    status = CallStatus.incoming;
    notifyListeners();
    onIncomingCall?.call();
  }

  Future<void> acceptCall() async {
    if (_pendingOfferSdp == null || conversationId == null) return;

    final granted = await requestCallPermissions(isVideoCall);
    if (!granted) {
      declineCall();
      return;
    }

    try {
      await _ensureRenderers();
      _pc = await _createPeerConnection();
      await _getLocalMedia(video: isVideoCall);

      final desc = RTCSessionDescription(
        _pendingOfferSdp!['sdp'],
        _pendingOfferSdp!['type'],
      );
      await _pc!.setRemoteDescription(desc);
      for (final c in _pendingRemoteCandidates) {
        await _pc!.addCandidate(c);
      }
      _pendingRemoteCandidates.clear();

      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      _socket.sendCallAnswer(
        conversationId: conversationId!,
        answer: {'sdp': answer.sdp, 'type': answer.type},
      );
      // Status flips to `connected` once ICE actually connects (see
      // onIceConnectionState above) rather than here, to avoid a UI
      // flash of "connected" before media is actually flowing.
      notifyListeners();
    } catch (e) {
      lastError = 'Could not answer the call: $e';
      declineCall();
    }
  }

  void declineCall() {
    if (conversationId != null) {
      _socket.sendCallDecline(conversationId!);
    }
    _cleanup();
  }

  void endCall({bool notifyPeer = true}) {
    if (notifyPeer && conversationId != null) {
      _socket.sendCallEnd(conversationId!);
    }
    _cleanup();
  }

  Future<void> _onRemoteAnswer(
    String fromUserId,
    String convId,
    Map answer,
  ) async {
    if (_pc == null) return;
    final desc = RTCSessionDescription(answer['sdp'], answer['type']);
    await _pc!.setRemoteDescription(desc);
  }

  Future<void> _onRemoteIceCandidate(
    String fromUserId,
    String convId,
    Map candidate,
  ) async {
    if (candidate['candidate'] == null) return;
    final ice = RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    );
    if (_pc == null) {
      _pendingRemoteCandidates.add(ice);
    } else {
      await _pc!.addCandidate(ice);
    }
  }

  void _onRemoteEnd(String convId, String fromUserId) {
    if (conversationId == convId) _cleanup();
  }

  void _onRemoteDecline(String convId, String fromUserId) {
    if (conversationId == convId) _cleanup();
  }

  void toggleMute() {
    isMuted = !isMuted;
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !isMuted);
    notifyListeners();
  }

  void toggleCamera() {
    isCameraOff = !isCameraOff;
    _localStream?.getVideoTracks().forEach((t) => t.enabled = !isCameraOff);
    notifyListeners();
  }

  Future<void> switchCamera() async {
    final videoTracks = _localStream?.getVideoTracks() ?? [];
    if (videoTracks.isNotEmpty) {
      await Helper.switchCamera(videoTracks.first);
    }
  }

  Future<void> toggleSpeaker() async {
    isSpeakerOn = !isSpeakerOn;
    await Helper.setSpeakerphoneOn(isSpeakerOn);
    notifyListeners();
  }

  void _cleanup() {
    status = CallStatus.ended;
    notifyListeners();

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;
    _pc?.close();
    _pc = null;
    // Guard: these renderers may never have been initialize()'d if the
    // call failed before _ensureRenderers() ran (e.g. permission denied) —
    // setting srcObject on an uninitialized renderer throws and used to
    // abort the rest of this method, which is why "End Call" could crash
    // and leave the screen stuck on "Call ended".
    if (_renderersReady) {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    }
    _pendingRemoteCandidates.clear();
    _pendingOfferSdp = null;
    _connectedAt = null;

    // Let the UI show "Call ended" briefly before resetting to idle.
    Future.delayed(const Duration(milliseconds: 800), () {
      status = CallStatus.idle;
      conversationId = null;
      peerUserId = null;
      peerName = null;
      peerAvatarUrl = null;
      isMuted = false;
      isCameraOff = false;
      notifyListeners();
    });
  }

  /// Used when a call attempt fails before it really started (e.g.
  /// permission denied) — shows the reason briefly, then returns to idle
  /// the same way a normal call ending does, so the call screen always
  /// closes itself instead of getting stuck.
  void _failAndClose(String message) {
    lastError = message;
    status = CallStatus.ended;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1200), () {
      status = CallStatus.idle;
      conversationId = null;
      peerUserId = null;
      peerName = null;
      peerAvatarUrl = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _cleanup();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }
}