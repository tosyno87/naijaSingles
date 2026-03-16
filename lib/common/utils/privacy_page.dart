import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../bloc/theme/theme_bloc.dart';
import '../constants/app_colors.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({required this.url, required this.tittle, super.key});
  final String url;
  final String tittle;

  @override
  PrivacyPolicyPageState createState() => PrivacyPolicyPageState();
}

class PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  late final WebViewController controller;
  var loadingPercentage = 0;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    final isDarkMode = context.read<ThemeBloc>().isDarkMode;
    controller = WebViewController();
    unawaited(_initController(isDarkMode));
  }

  Future<void> _initController(bool isDarkMode) async {
    _loadError = null;
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(Colors.white);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          if (mounted) {
            setState(() {
              loadingPercentage = 0;
              _loadError = null;
            });
          }
        },
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              loadingPercentage = progress;
              _loadError = null;
            });
          }
        },
        onPageFinished: (url) {
          if (mounted) {
            setState(() {
              loadingPercentage = 100;
              _loadError = null;
            });
          }
        },
        onWebResourceError: (WebResourceError error) {
          if (mounted) {
            setState(() {
              _loadError = error.description.isEmpty
                  ? 'Unable to load this page'
                  : error.description;
            });
          }
        },
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('https://www.yt.com/')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
    await controller.loadRequest(Uri.parse(widget.url));
  }

  Future<void> _retry() async {
    final isDarkMode = context.read<ThemeBloc>().isDarkMode;
    await _initController(isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          widget.tittle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        centerTitle: false,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (_loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: controller),
          if (loadingPercentage < 100 && _loadError == null)
            LinearProgressIndicator(
              value: loadingPercentage / 100.0,
              color: AppColors.primaryGreen,
            ),
        ],
      ),
    );
  }
}
