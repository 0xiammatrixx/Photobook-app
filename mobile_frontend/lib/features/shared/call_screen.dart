import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:mobile_frontend/providers/call_provider.dart';

const _orange = Color(0xFFFF7A33);

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Timer? _tickTimer;
  late CallProvider _callProvider;
  bool _actionTaken = false; // prevents double-tap on accept/decline

  @override
  void initState() {
    super.initState();
    _callProvider = context.read<CallProvider>();
    print('📞 [CallScreen] initState — status: ${_callProvider.status}, peer: ${_callProvider.peerName}, video: ${_callProvider.isVideoCall}');
    _callProvider.addListener(_handleChange);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _handleChange() {
    final status = _callProvider.status;
    if (status == CallStatus.idle && mounted && Navigator.of(context).canPop()) {
      print('📞 [CallScreen] _handleChange — status is idle, popping screen');
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _callProvider.removeListener(_handleChange);
    _tickTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _statusLabel(CallProvider call) {
    switch (call.status) {
      case CallStatus.outgoing:
        return 'Calling...';
      case CallStatus.incoming:
        return call.isVideoCall ? 'Incoming video call' : 'Incoming voice call';
      case CallStatus.connected:
        return _formatDuration(call.callDuration);
      case CallStatus.ended:
        return call.lastError ?? 'Call ended';
      case CallStatus.idle:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = context.watch<CallProvider>();
    final showRemoteVideo =
        call.isVideoCall && call.status == CallStatus.connected;
    final showLocalPreview = call.isVideoCall &&
        (call.status == CallStatus.connected ||
            call.status == CallStatus.outgoing);

    return PopScope(
      canPop: false, // use the call controls, not back-swipe
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              if (showRemoteVideo)
                Positioned.fill(
                  child: RTCVideoView(
                    call.remoteRenderer,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              if (showLocalPreview)
                Positioned(
                  top: 24,
                  right: 16,
                  width: 110,
                  height: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: RTCVideoView(
                      call.localRenderer,
                      mirror: true,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              if (!showRemoteVideo)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.white24,
                        backgroundImage: call.peerAvatarUrl != null
                            ? NetworkImage(call.peerAvatarUrl!)
                            : null,
                        child: call.peerAvatarUrl == null
                            ? const Icon(Icons.person,
                                size: 56, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        call.peerName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusLabel(call),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: _controls(call),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls(CallProvider call) {
    if (call.status == CallStatus.incoming) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _roundButton(
            icon: Icons.call_end,
            color: _actionTaken ? Colors.grey : Colors.red,
            onTap: _actionTaken
                ? null
                : () {
                    _actionTaken = true;
                    call.declineCall();
                  },
          ),
          _roundButton(
            icon: Icons.call,
            color: _actionTaken ? Colors.grey : Colors.green,
            onTap: _actionTaken
                ? null
                : () {
                    _actionTaken = true;
                    call.acceptCall();
                  },
          ),
        ],
      );
    }

    if (call.status == CallStatus.ended || call.status == CallStatus.idle) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _roundButton(
              icon: call.isMuted ? Icons.mic_off : Icons.mic,
              color: Colors.white24,
              onTap: call.toggleMute,
            ),
            if (call.isVideoCall)
              _roundButton(
                icon: call.isCameraOff ? Icons.videocam_off : Icons.videocam,
                color: Colors.white24,
                onTap: call.toggleCamera,
              )
            else
              _roundButton(
                icon: call.isSpeakerOn ? Icons.volume_up : Icons.hearing,
                color: Colors.white24,
                onTap: call.toggleSpeaker,
              ),
            if (call.isVideoCall)
              _roundButton(
                icon: Icons.cameraswitch,
                color: Colors.white24,
                onTap: call.switchCamera,
              ),
          ],
        ),
        const SizedBox(height: 24),
        _roundButton(
          icon: Icons.call_end,
          color: Colors.red,
          size: 64,
          onTap: call.endCall,
        ),
      ],
    );
  }

  Widget _roundButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}