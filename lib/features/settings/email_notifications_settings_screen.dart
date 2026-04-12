import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/settings_list/settings_list.dart';

/// Marketing / product email opt-in (stored on user doc).
class EmailNotificationsSettingsScreen extends StatefulWidget {
  const EmailNotificationsSettingsScreen({super.key});

  @override
  State<EmailNotificationsSettingsScreen> createState() =>
      _EmailNotificationsSettingsScreenState();
}

class _EmailNotificationsSettingsScreenState
    extends State<EmailNotificationsSettingsScreen> {
  bool _loading = true;
  bool _enabled = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final v = doc.data()?['emailNotificationsEnabled'];
      setState(() {
        _enabled = v is bool ? v : true;
        _loading = false;
      });
    } on Object {
      setState(() {
        _loading = false;
        _error = 'Could not load preference';
      });
    }
  }

  Future<void> _save(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _enabled = value);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'emailNotificationsEnabled': value},
        SetOptions(merge: true),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Email notifications',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : settingsSwitchTheme(
              context: context,
              child: ListView(
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                    ),
                  SettingsSection(
                    title: 'Email',
                    consequence:
                        'Occasional updates about matches, features, and tips. You can turn this off anytime.',
                    children: [
                      SettingsToggleRow(
                        title: 'Product & tips email',
                        subtitle: 'Not related to push notifications',
                        value: _enabled,
                        onChanged: _error != null ? null : _save,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
