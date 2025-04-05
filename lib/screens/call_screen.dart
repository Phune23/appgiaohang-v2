import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/call_service.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String token;
  final bool isOutgoing;
  final VoidCallback? onCallEnded; // Add callback
  final VoidCallback? onCallRejected; // Add rejection callback

  const CallScreen({
    required this.channelName,
    required this.token,
    this.isOutgoing = true,
    this.onCallEnded,
    this.onCallRejected,
  });

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  bool _isInCall = false;
  int? _remoteUid; // Add this to track remote user

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      print('Initializing call with:');
      print('Channel: ${widget.channelName}');
      
      // Validate token and channel name first
      if (widget.channelName.isEmpty || widget.token.isEmpty) {
        throw Exception('Invalid channel name or token');
      }

      await _callService.initializeAgora();

      _callService.engine?.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          print("Successfully joined channel: ${connection.channelId}");
          if (mounted) {
            setState(() => _isInCall = true);
          }
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          print("Remote user $remoteUid joined");
          if (mounted) {
            setState(() => _remoteUid = remoteUid);
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          print("Remote user $remoteUid left: $reason");
          if (mounted) {
            setState(() => _remoteUid = null);
            _endCall();
          }
        },
        onConnectionStateChanged: (connection, state, reason) {
          print("Connection state changed to $state: $reason");
          if (state == ConnectionStateType.connectionStateFailed) {
            _handleError("Connection failed: ${reason.toString()}");
          }
        },
        onError: (err, msg) {
          print("Error occurred: $err - $msg");
          _handleError(msg);
        },
      ));

      await _callService.joinCall(widget.channelName, widget.token);
      
    } catch (e) {
      print("Call initialization error: $e");
      _handleError(e.toString());
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    
    print("Error occurred: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
    
    _endCall();
  }

  Future<void> _endCall() async {
    await _callService.leaveCall();
    if (widget.onCallEnded != null) {
      widget.onCallEnded!();
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _handleCallRejected() {
    if (widget.onCallRejected != null) {
      widget.onCallRejected!();
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _endCall();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Main video views
            if (_isInCall) ...[
              if (_remoteUid != null)
                AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _callService.engine!,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(channelId: widget.channelName),
                    useFlutterTexture: true,
                    useAndroidSurfaceView: true,
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        'Đang kết nối...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Local video view
              Positioned(
                top: 40,
                right: 16,
                width: 120,
                height: 180,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _callService.engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Controls overlay
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _callService.isMicOn ? Icons.mic : Icons.mic_off,
                      label: _callService.isMicOn ? 'Tắt mic' : 'Bật mic',
                      onPressed: () {
                        _callService.toggleMicrophone();
                        setState(() {});
                      },
                    ),
                    _buildControlButton(
                      icon: Icons.call_end,
                      color: Colors.red,
                      backgroundColor: Colors.red.shade100,
                      label: 'Kết thúc',
                      onPressed: _endCall,
                    ),
                    _buildControlButton(
                      icon: _callService.isCameraOn
                          ? Icons.videocam
                          : Icons.videocam_off,
                      label: _callService.isCameraOn ? 'Tắt camera' : 'Bật camera',
                      onPressed: () {
                        _callService.toggleCamera();
                        setState(() {});
                      },
                    ),
                    _buildControlButton(
                      icon: Icons.switch_camera,
                      label: 'Đổi camera',
                      onPressed: () {
                        _callService.switchCamera();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.white,
    Color backgroundColor = Colors.black54,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: color, size: 28),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}