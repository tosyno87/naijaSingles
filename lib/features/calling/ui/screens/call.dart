import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';

// This is a simplified placeholder for the original CallPage
// Original implementation used Agora SDK which has been removed

class CallPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  final String channelName;

  /// non-modifiable client role of the page
  final dynamic role; // Changed from ClientRoleType
  final String callType;

  /// Creates a call page with given channel name.
  const CallPage({
    Key? key,
    required this.channelName,
    required this.role,
    required this.callType,
  }) : super(key: key);

  @override
  CallPageState createState() => CallPageState();
}

class CallPageState extends State<CallPage> {
  bool muted = false;
  bool onSpeaker = false;

  @override
  void initState() {
    super.initState();
    // Agora initialization removed
  }

  @override
  void dispose() {
    // Agora cleanup removed
    super.dispose();
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    // Actual mute functionality removed
  }

  void _onSpeaker() {
    setState(() {
      onSpeaker = !onSpeaker;
    });
    // Actual speaker functionality removed
  }

  Widget _audioToolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            shape: const CircleBorder(),
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
            shape: const CircleBorder(),
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
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.call_outlined,
                size: 80,
                color: primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                widget.callType == 'VideoCall' 
                    ? 'Video calling is temporarily disabled'
                    : 'Audio calling is temporarily disabled',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text('Channel: ${widget.channelName}'),
              const Spacer(),
              _audioToolbar(),
            ],
          ),
        ),
      ),
    );
  }
}
