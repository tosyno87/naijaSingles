import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../common/widgets/state_views/state_views.dart';
import '../../models/user_model.dart';
import '../dating/screens/user_detail_screen.dart';

/// Read-only profile opened from share links / deep links.
class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (!doc.exists) {
        setState(() {
          _error = 'Profile not found';
          _loading = false;
        });
        return;
      }
      setState(() {
        _user = UserModel.fromDocument(doc);
        _loading = false;
      });
    } on Object catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: AppLoadingView(message: 'Loading profile...'),
      );
    }
    if (_error != null || _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: AppErrorView(
          title: 'Profile unavailable',
          message: _error ?? 'Unknown error',
          onRetry: _load,
        ),
      );
    }

    return UserDetailScreen(user: _user!);
  }
}
