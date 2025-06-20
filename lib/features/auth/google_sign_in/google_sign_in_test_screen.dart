import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'simple_google_sign_in.dart';

class GoogleSignInTestScreen extends StatefulWidget {
  const GoogleSignInTestScreen({Key? key}) : super(key: key);

  @override
  State<GoogleSignInTestScreen> createState() => _GoogleSignInTestScreenState();
}

class _GoogleSignInTestScreenState extends State<GoogleSignInTestScreen> {
  String _status = 'Not signed in';
  User? _user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In Test'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Status: $_status',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (_user != null) ...[
                      const SizedBox(height: 8),
                      Text('User ID: ${_user!.uid}'),
                      Text('Email: ${_user!.email}'),
                      Text('Name: ${_user!.displayName}'),
                      if (_user!.photoURL != null)
                        CircleAvatar(
                          backgroundImage: NetworkImage(_user!.photoURL!),
                          radius: 30,
                        ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Google Sign-In Button
              SimpleGoogleSignInButton(
                onSignInComplete: (user) {
                  setState(() {
                    if (user != null) {
                      _status = 'Signed in successfully';
                      _user = user;
                    } else {
                      _status = 'Sign in failed or was canceled';
                    }
                  });
                  
                  // Show a snackbar with the result
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(user != null 
                          ? 'Signed in as ${user.displayName}'
                          : 'Sign in failed or was canceled'),
                      backgroundColor: user != null ? Colors.green : Colors.red,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Sign Out Button
              if (_user != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade900,
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    setState(() {
                      _status = 'Signed out';
                      _user = null;
                    });
                  },
                  child: const Text('Sign Out'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
