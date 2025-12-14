import 'dart:developer';
import 'package:flutter/material.dart';
import 'explore_screen.dart';

class ExplorePage extends StatelessWidget {

  const ExplorePage({
    super.key,
    this.showBackButton = false, // Default to false (no back labelLarge)
  });
  // Add parameter to control back labelLarge visibility
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    log('Building ExplorePage');
    return Scaffold(
      body: SafeArea(
        child: ExploreScreen(
          showBackButton: showBackButton,
        ),
      ),
    );
  }
}
