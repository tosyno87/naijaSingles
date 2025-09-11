import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../common/constants/colors.dart';
import '../../../../../common/providers/theme_provider.dart';

class TimerWidget extends StatefulWidget {
  final int start;
  final String phoneNumber;
  final String resendText;
  final VoidCallback onResendOtp;

  const TimerWidget({
    super.key,
    required this.start,
    required this.phoneNumber,
    required this.resendText,
    required this.onResendOtp,
  });

  @override
  TimerWidgetState createState() => TimerWidgetState();
}

class TimerWidgetState extends State<TimerWidget> {
  Timer? _timer;
  int _currentTimerValue = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  void _startTimer() {
    _currentTimerValue = widget.start;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentTimerValue > 0) {
          _currentTimerValue--;
        } else {
          _cancelTimer();
        }
      });
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: widget.resendText,
        style: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
          fontSize: 15,
        ),
        children: [
          WidgetSpan(
            child: GestureDetector(
              onTap: () {
                if (_currentTimerValue <= 0) {
                  widget.onResendOtp();
                  _startTimer();
                }
              },
              child: Text(
                _currentTimerValue > 0
                    ? "Resend OTP in".tr(args: [
                        "0:${_currentTimerValue.toString().padLeft(2, '0')} sec"
                      ]).toString()
                    : "Resend".tr().toString(),
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
