import 'package:flutter/material.dart';

import '../../../../../common/constants/colors.dart';

class CallPlaceholder extends StatelessWidget {
  final String channelName;
  final String callType;

  const CallPlaceholder({
    Key? key,
    required this.channelName,
    required this.callType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$callType - Coming Soon'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              callType == 'VideoCall' ? Icons.video_call_outlined : Icons.call,
              size: 80,
              color: primaryColor,
            ),
            const SizedBox(height: 20),
            const Text(
              'Calling feature is temporarily disabled',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Channel: $channelName'),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Return to Chat'),
            ),
          ],
        ),
      ),
    );
  }
}
