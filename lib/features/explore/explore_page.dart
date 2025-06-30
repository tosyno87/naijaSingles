import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:naijasingles/features/explore/explore_screen.dart';

class ExplorePage extends StatelessWidget {
  // Add parameter to control back labelLarge visibility
  final bool showBackButton;
  
  const ExplorePage({
    Key? key,
    this.showBackButton = false, // Default to false (no back labelLarge)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    log("Building ExplorePage");
    return Scaffold(
      body: SafeArea(
        child: ExploreScreen(
          showBackButton: showBackButton,
        ),
      ),
    );
  }
}
