import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/config.dart';

class CallService {
  static const String appId = "a4071bedee5f48ea91a1bed0a3bb7486";
  late RtcEngine _engine;
  RtcEngine? get engine => _engine;
  bool _isCameraOn = true;
  bool _isMicOn = true;
  bool _isFrontCamera = true;

  Future<void> initializeAgora() async {
    try {
      // Log permission status
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.camera,
      ].request();
      
      print('Permission status - Camera: ${statuses[Permission.camera]}, Mic: ${statuses[Permission.microphone]}');

      if (statuses[Permission.microphone] != PermissionStatus.granted ||
          statuses[Permission.camera] != PermissionStatus.granted) {
        print('Permission denied - Camera: ${statuses[Permission.camera]}, Mic: ${statuses[Permission.microphone]}');
        throw Exception('Camera and Microphone permissions are required');
      }

      _engine = createAgoraRtcEngine();
      
      print('Initializing Agora with app ID: ${appId.substring(0, 8)}...');
      
      await _engine.initialize(const RtcEngineContext(
        appId: appId,
        // Change to Communication profile for 1-to-1 calls
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Configure video encoder
      await _engine.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 320, height: 240),
          frameRate: 15,
          bitrate: 400,
          orientationMode: OrientationMode.orientationModeAdaptive,
          mirrorMode: VideoMirrorModeType.videoMirrorModeDisabled,
        ),
      );

      await _engine.enableVideo();
      await _engine.enableAudio();
      
      // Set hardware acceleration
      await _engine.setParameters(
        '{"che.hardware.encoding":"true","che.hardware.decoding":"true"}'
      );
      
      // Enable dual stream mode
      await _engine.enableDualStreamMode(enabled: true);
      
      // Camera settings
      await _engine.setCameraCapturerConfiguration(
        const CameraCapturerConfiguration(
          cameraDirection: CameraDirection.cameraFront,
        ),
      );
      
      print('Starting preview...');
      await _engine.startPreview();
      
      print('Agora initialization complete');

    } catch (e, stackTrace) {
      print('Error initializing Agora:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to initialize video call: ${e.toString()}');
    }
  }

  Future<String> generateToken(String channelName) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseurl}/agora/token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'channelName': channelName,
          'uid': 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['token'];
      } else {
        throw Exception('Failed to generate token');
      }
    } catch (e) {
      print('Error generating token: $e');
      throw Exception('Failed to generate token: $e');
    }
  }

  Future<void> joinCall(String channelName, String token) async {
    try {
      print('Attempting to join channel: $channelName');
      
      // Get a fresh token
      final freshToken = await generateToken(channelName);
      print('Generated fresh token: ${freshToken.substring(0, 10)}...');
      
      // Rest of the join call code...
      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        enableAudioRecordingOrPlayout: true, // Enable audio playback
      );

      print('Joining with options: ${options.toString()}');
      
      await _engine.joinChannel(
        token: freshToken, // Use the fresh token
        channelId: channelName,
        uid: 0,
        options: options,
      );

      print('Successfully joined channel');
    } catch (e, stackTrace) {
      print('Error joining call:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to join call: ${e.toString()}');
    }
  }

  Future<void> leaveCall() async {
    try {
      await _engine.leaveChannel();
      await _engine.stopPreview();
      await _engine.release();
    } catch (e) {
      print('Error leaving call: $e');
    }
  }

  Future<void> toggleCamera() async {
    _isCameraOn = !_isCameraOn;
    await _engine.enableLocalVideo(_isCameraOn);
  }

  Future<void> toggleMicrophone() async {
    _isMicOn = !_isMicOn;
    await _engine.enableLocalAudio(_isMicOn);
  }

  Future<void> switchCamera() async {
    await _engine.switchCamera();
    _isFrontCamera = !_isFrontCamera;
  }

  bool get isCameraOn => _isCameraOn;
  bool get isMicOn => _isMicOn;
  bool get isFrontCamera => _isFrontCamera;
}