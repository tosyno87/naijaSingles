// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers, use_build_context_synchronously

import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../config/app_config.dart';

class CallPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  final String channelName;

  /// non-modifiable client role of the page
  final ClientRoleType role;
  final String callType;

  /// Creates a call page with given channel name.
  const CallPage(
      {Key? key,
      required this.channelName,
      required this.role,
      required this.callType})
      : super(key: key);

  @override
  CallPageState createState() => CallPageState();
}

class CallPageState extends State<CallPage> {
  final _infoStrings = <String>[];
  bool muted = false;
  bool onSpeaker = false;
  bool disable = true;
  late RtcEngine _engine;
  late AgoraClient client;
  int? _remoteUid;
  bool localUserJoined = false;

  @override
  void initState() {
    // Instantiate the client
    client = AgoraClient(
        agoraConnectionData: AgoraConnectionData(
          appId: agoraAppId,
          channelName: widget.channelName,
        ),
        agoraRtmChannelEventHandler: AgoraRtmChannelEventHandler(
          onMemberLeft: (member) async {
            await _engine.leaveChannel();
            await _engine.release();
            Navigator.pop(context);
          },
        ));
    widget.callType == 'VideoCall' ? initAgora() : initialize();

    super.initState();
  }

  @override
  void dispose() {
    widget.callType == 'VideoCall'
        ? client.engine.release()
        : _engine.release();
    super.dispose();
  }

  void initAgora() async {
    await client.initialize();
  }

  Future<void> initialize() async {
    if (agoraAppId.isEmpty) {
      debugPrint('app id is missing $_infoStrings');
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }

    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    debugPrint("engine initiliaze");
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication));
    widget.callType == "VideoCall"
        ? await _engine.enableVideo()
        : await _engine.enableAudio();

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
    );

    await _engine.joinChannel(
      token: '',
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
    debugPrint("engine initiliaze");
    debugPrint("engine initiliaze with channel id ${widget.channelName}");
  }

  /// register agora event handlers
  void _addAgoraEventHandlers() {
    _engine.registerEventHandler(RtcEngineEventHandler(
      onError: (ErrorCodeType err, String msg) {
        final info = 'onError: ${err.value()}';
        _infoStrings.add(info);
        debugPrint('app id ERROR $_infoStrings');
      },
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        localUserJoined = true;
        final info =
            'onJoinChannel: ${connection.channelId}, uid: ${connection.localUid}';
        _infoStrings.add(info);
        debugPrint('app id is SUCCESS $_infoStrings');
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        debugPrint('leaveChannel ${stats.toJson()}');

        _infoStrings.add('onLeaveChannel');
      },
      onUserJoined:
          (RtcConnection connection, int remoteUid, int elapsed) async {
        debugPrint('userJoined ${connection.localUid}');

        // setState(() {
        _remoteUid = remoteUid;
        debugPrint('app id is USER JOIN $_infoStrings');

        final info = 'userJoined: ${connection.localUid}';
        _infoStrings.add(info);
        // });
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        debugPrint('userOffline $reason \n ${connection.localUid}');

        final info = 'userOffline: $remoteUid';
        _infoStrings.add(info);
        _remoteUid = null;
        Navigator.pop(context);
      },
    ));
    debugPrint("engine initiliaze and register");
  }

  Widget remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoViewer(
        client: client,
        layoutType: Layout.oneToOne,
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _audioToolbar() {
    if (widget.role == ClientRoleType.clientRoleAudience) return Container();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: muted ? primaryColor : Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : primaryColor,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: _onSpeaker,
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: onSpeaker ? primaryColor : Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              onSpeaker ? Icons.volume_up : Icons.volume_down,
              color: onSpeaker ? Colors.white : primaryColor,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
          ),
        ],
      ),
    );
  }

  void _onCallEnd(BuildContext context) async {
    await _engine.leaveChannel();
    await _engine.release();
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onSpeaker() {
    setState(() {
      onSpeaker = !onSpeaker;
    });
    _engine.setEnableSpeakerphone(onSpeaker).then((value) {
      _engine.setInEarMonitoringVolume(400);
    }).catchError((err) {
      debugPrint('setEnableSpeakerphone $err');
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("call ${widget.callType}");
    final themeProvider = Provider.of<ThemeProvider>(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
        body: widget.callType == 'VideoCall'
            ? Stack(
                children: [
                  AgoraVideoViewer(
                    client: client,
                  ),
                  AgoraVideoButtons(client: client),
                ],
              )
            : Center(
                child: Stack(
                  children: <Widget>[
                    Container(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: primaryColor,
                      ),
                    ),
                    // _panel(),
                    _audioToolbar()
                  ],
                ),
              ),
      ),
    );
  }
}
