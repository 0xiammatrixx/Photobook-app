import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_frontend/services/chat_socket.dart';

enum CallStatus { idle, outgoing, incoming, connected, ended }

void _log(String msg) {
  final ts = DateTime.now().toIso8601String().substring(11, 23);
  // ignore: avoid_print
  print('📞 [$ts] CallProvider: $msg');
}

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

  /// Auto-decline incoming calls after this duration if not answered.
  /// Needed because the server may not relay `call:end` events — without
  /// this, the callee would ring forever after the caller hangs up.
  Timer? _incomingTimeout;
  static const _incomingTimeoutDuration = Duration(seconds: 60);

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
    if (_signalingRegistered) {
      _log('registerSignaling already registered, skipping');
      return;
    }
    _signalingRegistered = true;
    _log('registerSignaling — setting call handlers on ChatSocket singleton');
    _socket.setCallHandlers(
      onCallOffer: _onRemoteOffer,
      onCallAnswer: _onRemoteAnswer,
      onIceCandidate: _onRemoteIceCandidate,
      onCallEnd: _onRemoteEnd,
      onCallDecline: _onRemoteDecline,
    );
    _log('registerSignaling — handlers set. Socket connected: ${_socket.isConnected}');
  }

  Future<bool> requestCallPermissions(bool video) async {
    final permissions = <Permission>[
      Permission.microphone,
      if (video) Permission.camera,
    ];
    _log('requestCallPermissions(video: $video) — requesting: ${permissions.map((p) => p.toString()).join(', ')}');
    final statuses = await permissions.request();
    for (final entry in statuses.entries) {
      _log('  permission ${entry.key}: ${entry.value.isGranted ? "GRANTED" : entry.value.isPermanentlyDenied ? "PERMANENTLY DENIED" : "DENIED"}');
    }
    final granted = statuses.values.every((s) => s.isGranted);
    if (!granted) {
      final permanentlyDenied = statuses.values.any((s) => s.isPermanentlyDenied);
      if (permanentlyDenied) {
        lastError = 'Microphone/camera access is permanently denied. '
            'Please open Settings > PhotoBook and enable permissions.';
      } else {
        lastError = 'Camera/microphone permission is required for calls.';
      }
      _log('requestCallPermissions — DENIED (permanently: $permanentlyDenied), setting lastError: $lastError');
      notifyListeners();
    }
    _log('requestCallPermissions — returning $granted');
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
    _log('startCall(convId=$conversationId, peer=$peerUserId, video=$isVideo) — current status: $status, socket connected: ${_socket.isConnected}');

    if (status != CallStatus.idle) {
      _log('startCall BLOCKED — status is $status, not idle. Setting error.');
      lastError = 'Cannot start call: already in state $status';
      notifyListeners();
      return;
    }

    if (!_socket.isConnected) {
      _log('startCall WARNING — socket is NOT connected. Call signaling will fail.');
      lastError = 'Not connected to chat server. Please wait and try again.';
      _failAndClose(lastError!);
      return;
    }

    // ── Set outgoing state BEFORE requesting permissions ──
    // This is critical: requestCallPermissions() calls notifyListeners()
    // on denial, and CallScreen._handleChange pops the screen when it
    // sees status==idle. By setting outgoing first, the CallScreen sees
    // "outgoing" and stays put, then _failAndClose transitions through
    // ended→idle which triggers the proper delayed pop.
    this.conversationId = conversationId;
    this.peerUserId = peerUserId;
    this.peerName = peerName;
    this.peerAvatarUrl = peerAvatarUrl;
    isVideoCall = isVideo;
    status = CallStatus.outgoing;
    lastError = null;
    _log('startCall — status set to outgoing, now requesting permissions');
    notifyListeners();

    final granted = await requestCallPermissions(isVideo);
    if (!granted) {
      _log('startCall ABORTED — permissions denied');
      _failAndClose(lastError ?? 'Camera/microphone permission is required.');
      return;
    }
    _log('startCall — status set to outgoing, notifying listeners');
    notifyListeners();

    try {
      _log('startCall — initializing renderers...');
      await _ensureRenderers();
      _log('startCall — creating peer connection...');
      _pc = await _createPeerConnection();
      _log('startCall — getting local media (video=$isVideo)...');
      await _getLocalMedia(video: isVideo);

      _log('startCall — creating offer...');
      final offer = await _pc!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': isVideo,
      });
      await _pc!.setLocalDescription(offer);
      _log('startCall — offer created, sending via socket...');

      _socket.sendCallOffer(
        conversationId: conversationId,
        offer: {'sdp': offer.sdp, 'type': offer.type, 'isVideo': isVideo},
      );
      _log('startCall — offer sent successfully');
      notifyListeners();
    } catch (e, stack) {
      _log('startCall FAILED — $e');
      _log('startCall stack: $stack');
      lastError = 'Could not start the call: $e';
      _cleanup();
    }
  }

  void _onRemoteOffer(String fromUserId, String convId, Map offer) {
    _log('_onRemoteOffer(from=$fromUserId, conv=$convId, isVideo=${offer['isVideo']}) — current status: $status, onIncomingCall set: ${onIncomingCall != null}');

    if (status != CallStatus.idle) {
      _log('_onRemoteOffer IGNORED — already in status $status, no busy signal in schema');
      return;
    }
    conversationId = convId;
    peerUserId = fromUserId;
    final info = resolvePeerInfo?.call(fromUserId);
    _log('_onRemoteOffer resolved peer info: name=${info?['name']}, avatarUrl=${info?['avatarUrl'] != null}');
    peerName = info?['name'] ?? peerName;
    peerAvatarUrl = info?['avatarUrl'] ?? peerAvatarUrl;
    isVideoCall = offer['isVideo'] == true;
    _pendingOfferSdp = Map<String, dynamic>.from(offer);
    status = CallStatus.incoming;
    _log('_onRemoteOffer — status set to incoming, calling onIncomingCall...');
    notifyListeners();
    onIncomingCall?.call();

    // Start auto-decline timer in case the server doesn't relay call:end
    _incomingTimeout?.cancel();
    _incomingTimeout = Timer(_incomingTimeoutDuration, () {
      if (status == CallStatus.incoming) {
        _log('_onRemoteOffer — incoming call timed out after ${_incomingTimeoutDuration.inSeconds}s, auto-declining');
        lastError = 'Call timed out';
        declineCall();
      }
    });

    _log('_onRemoteOffer — onIncomingCall invoked');
  }

  Future<void> acceptCall() async {
    _log('acceptCall() — pendingOfferSdp: ${_pendingOfferSdp != null}, convId: $conversationId, isVideo: $isVideoCall, status: $status');

    if (_pendingOfferSdp == null || conversationId == null) {
      _log('acceptCall ABORTED — no pending offer or conversationId');
      return;
    }

    // ── Prevent re-entry ──
    // The CallScreen buttons stay visible while status==incoming, and
    // acceptCall is async — without this guard, tapping Accept multiple
    // times creates duplicate peer connections & media streams, floods
    // the remote side with answers, and leaks resources.
    if (status != CallStatus.incoming) {
      _log('acceptCall ABORTED — status is $status, not incoming (already accepting?)');
      return;
    }

    // Snapshot and null out immediately so the guard blocks re-entry
    // even before the first await completes.
    final Map<String, dynamic> offerSdp = _pendingOfferSdp!;
    _pendingOfferSdp = null;
    status = CallStatus.outgoing; // transitional — flips to connected when ICE links
    notifyListeners();

    final granted = await requestCallPermissions(isVideoCall);
    if (!granted) {
      _log('acceptCall ABORTED — permissions denied, declining');
      declineCall();
      return;
    }

    try {
      _log('acceptCall — initializing renderers...');
      await _ensureRenderers();
      _log('acceptCall — creating peer connection...');
      _pc = await _createPeerConnection();
      _log('acceptCall — getting local media (video=$isVideoCall)...');
      await _getLocalMedia(video: isVideoCall);

      final desc = RTCSessionDescription(
        offerSdp['sdp'],
        offerSdp['type'],
      );
      _log('acceptCall — setting remote description...');
      await _pc!.setRemoteDescription(desc);
      for (final c in _pendingRemoteCandidates) {
        await _pc!.addCandidate(c);
      }
      _pendingRemoteCandidates.clear();

      _log('acceptCall — creating answer...');
      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      _log('acceptCall — sending answer via socket...');
      _socket.sendCallAnswer(
        conversationId: conversationId!,
        answer: {'sdp': answer.sdp, 'type': answer.type},
      );
      _log('acceptCall — answer sent, waiting for ICE connection');
      notifyListeners();
    } catch (e, stack) {
      _log('acceptCall FAILED — $e');
      _log('acceptCall stack: $stack');
      lastError = 'Could not answer the call: $e';
      declineCall();
    }
  }

  void declineCall() {
    _log('declineCall() — convId: $conversationId');
    if (conversationId != null) {
      _socket.sendCallDecline(conversationId!);
    }
    _cleanup();
  }

  void endCall({bool notifyPeer = true}) {
    _log('endCall(notifyPeer=$notifyPeer) — convId: $conversationId');
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
    _log('_onRemoteAnswer(from=$fromUserId, conv=$convId)');
    if (_pc == null) {
      _log('_onRemoteAnswer — no peer connection, ignoring');
      return;
    }
    final desc = RTCSessionDescription(answer['sdp'], answer['type']);
    await _pc!.setRemoteDescription(desc);
    _log('_onRemoteAnswer — remote description set');
  }

  Future<void> _onRemoteIceCandidate(
    String fromUserId,
    String convId,
    Map candidate,
  ) async {
    _log('_onRemoteIceCandidate(from=$fromUserId, conv=$convId)');
    if (candidate['candidate'] == null) return;
    final ice = RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    );
    if (_pc == null) {
      _log('_onRemoteIceCandidate — PC not ready, queuing (queue size: ${_pendingRemoteCandidates.length + 1})');
      _pendingRemoteCandidates.add(ice);
    } else {
      await _pc!.addCandidate(ice);
      _log('_onRemoteIceCandidate — candidate added');
    }
  }

  void _onRemoteEnd(String convId, String fromUserId) {
    _log('_onRemoteEnd(conv=$convId, from=$fromUserId) — our convId: $conversationId');
    if (conversationId == convId) {
      _log('_onRemoteEnd — match, cleaning up');
      _cleanup();
    }
  }

  void _onRemoteDecline(String convId, String fromUserId) {
    _log('_onRemoteDecline(conv=$convId, from=$fromUserId) — our convId: $conversationId');
    if (conversationId == convId) {
      _log('_onRemoteDecline — match, cleaning up');
      _cleanup();
    }
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
    _log('_cleanup() — current status: $status');
    _incomingTimeout?.cancel();
    _incomingTimeout = null;
    status = CallStatus.ended;
    notifyListeners();

    _log('_cleanup — stopping tracks...');
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;
    _log('_cleanup — closing peer connection...');
    _pc?.close();
    _pc = null;
    if (_renderersReady) {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    }
    _pendingRemoteCandidates.clear();
    _pendingOfferSdp = null;
    _connectedAt = null;

    _log('_cleanup — scheduling reset to idle in 800ms');
    Future.delayed(const Duration(milliseconds: 800), () {
      _log('_cleanup delayed — resetting to idle (was: $status)');
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

  void _failAndClose(String message) {
    _log('_failAndClose("$message")');
    _incomingTimeout?.cancel();
    _incomingTimeout = null;
    lastError = message;
    status = CallStatus.ended;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1200), () {
      _log('_failAndClose delayed — resetting to idle');
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
    _incomingTimeout?.cancel();
    _cleanup();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }
}