import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:naijasingles/features/explore/explore_screen.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    log("Building ExplorePage");
    return const Scaffold(
      body: SafeArea(
        child: ExploreScreen(),
      ),
    );
  }
}
