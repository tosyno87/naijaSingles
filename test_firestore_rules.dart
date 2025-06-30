import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// This is a test script to verify Firestore security rules
// Run this with: flutter run -t test_firestore_rules.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Connect to Firebase emulator
  FirebaseFirestore.instance.settings = const Settings(
    host: 'localhost:8080',
    sslEnabled: false,
    persistenceEnabled: false,
  );
  
  FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  
  runApp(const FirestoreRulesTestApp());
}

class FirestoreRulesTestApp extends StatelessWidget {
  const FirestoreRulesTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Rules Test',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFFDF6EC),
      ),
      home: const FirestoreRulesTestScreen(),
    );
  }
}

class FirestoreRulesTestScreen extends StatefulWidget {
  const FirestoreRulesTestScreen({Key? key}) : super(key: key);

  @override
  State<FirestoreRulesTestScreen> createState() => _FirestoreRulesTestScreenState();
}

class _FirestoreRulesTestScreenState extends State<FirestoreRulesTestScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _testResult = '';
  bool _isRunningTest = false;
  User? _currentUser;
  
  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }
  
  void _checkCurrentUser() {
    setState(() {
      _currentUser = _auth.currentUser;
    });
  }
  
  Future<void> _createTestUser(String email, String password) async {
    try {
      setState(() {
        _isRunningTest = true;
        _testResult = 'Creating test user...';
      });
      
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _checkCurrentUser();
      
      setState(() {
        _testResult = 'Test user created successfully!';
        _isRunningTest = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error creating test user: $e';
        _isRunningTest = false;
      });
    }
  }
  
  Future<void> _signIn(String email, String password) async {
    try {
      setState(() {
        _isRunningTest = true;
        _testResult = 'Signing in...';
      });
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _checkCurrentUser();
      
      setState(() {
        _testResult = 'Signed in successfully!';
        _isRunningTest = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error signing in: $e';
        _isRunningTest = false;
      });
    }
  }
  
  Future<void> _signOut() async {
    try {
      setState(() {
        _isRunningTest = true;
        _testResult = 'Signing out...';
      });
      
      await _auth.signOut();
      
      _checkCurrentUser();
      
      setState(() {
        _testResult = 'Signed out successfully!';
        _isRunningTest = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error signing out: $e';
        _isRunningTest = false;
      });
    }
  }
  
  Future<void> _testCreateUserDocument() async {
    if (_currentUser == null) {
      setState(() {
        _testResult = 'Error: No user signed in';
      });
      return;
    }
    
    try {
      setState(() {
        _isRunningTest = true;
        _testResult = 'Testing create user document...';
      });
      
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'name': 'Test User',
        'email': _currentUser!.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _testResult = 'User document created successfully!';
        _isRunningTest = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error creating user document: $e';
        _isRunningTest = false;
      });
    }
  }
  
  Future<void> _testCreateChatThread() async {
    if (_currentUser == null) {
      setState(() {
        _testResult = 'Error: No user signed in';
      });
      return;
    }
    
    try {
      setState(() {
        _isRunningTest = true;
        _testResult = 'Testing create chat thread...';
      });
      
      final threadRef = _firestore.collection('chatThreads').doc();
      await threadRef.set({
        'threadId': threadRef.id,
        'userIds': [_currentUser!.uid, 'otherUserId'],
        'userNames': {
          _currentUser!.uid: 'Test User',
          'otherUserId': 'Other User'
        },
        'lastMessage': null,
        'lastMessageText': "Say hi!",
        'lastMessageSenderId': null,
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCount': {
          _currentUser!.uid: 0,
          'otherUserId': 0
        }
      });
      
      setState(() {
        _testResult = 'Chat thread created successfully! ID: ${threadRef.id}';
        _isRunningTest = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error creating chat thread: $e';
        _isRunningTest = false;
      });
    }
  }
  
  Future<void> _testSendMessage() async {
    if (_currentUser == null) {
      setState(() {
        _testResult = 'Error: No user signed in';
      });
      return;
    }
    
    try {
      setState(() {
        _isRunningTest = true;
        _testResult = 'Testing send message...';
      });
      
      // First, get a thread where this user is a participant
      final threadsSnapshot = await _firestore
          .collection('chatThreads')
          .where('userIds', arrayContains: _currentUser!.uid)
          .limit(1)
          .get();
      
      if (threadsSnapshot.docs.isEmpty) {
        setState(() {
          _testResult = 'Error: No chat threads found for this user';
          _isRunningTest = false;
        });
        return;
      }
      
      final threadId = threadsSnapshot.docs.first.id;
      
      // Send a message
      await _firestore
          .collection('chatThreads')
          .doc(threadId)
          .collection('messages')
          .add({
            'senderId': _currentUser!.uid,
            'text': 'Test message',
            'timestamp': FieldValue.serverTimestamp(),
            'read': false
          });
      
      setState(() {
        _testResult = 'Message sent successfully!';
        _isRunningTest = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error sending message: $e';
        _isRunningTest = false;
      });
    }
  }
  
  Future<void> _testAccessOtherUserDocument() async {
    try {
      setState(() {
        _isRunningTest = true;
        _testResult = 'Testing access to other user document...';
      });
      
      // Try to access a document that doesn't belong to the current user
      await _firestore.collection('users').doc('otherUserId').get();
      
      setState(() {
        _testResult = 'WARNING: Could access other user document!';
        _isRunningTest = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Success: Access denied to other user document (expected)';
        _isRunningTest = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Rules Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentUser != null
                          ? 'Signed in as: ${_currentUser!.email}'
                          : 'Not signed in',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Results',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      width: double.infinity,
                      child: _isRunningTest
                          ? const Center(child: CircularProgressIndicator())
                          : Text(_testResult),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication Tests',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isRunningTest
                          ? null
                          : () => _createTestUser('test@example.com', 'password123'),
                      child: const Text('Create Test User'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isRunningTest
                          ? null
                          : () => _signIn('test@example.com', 'password123'),
                      child: const Text('Sign In'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isRunningTest ? null : _signOut,
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firestore Rules Tests',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isRunningTest ? null : _testCreateUserDocument,
                      child: const Text('Test Create User Document'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isRunningTest ? null : _testCreateChatThread,
                      child: const Text('Test Create Chat Thread'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isRunningTest ? null : _testSendMessage,
                      child: const Text('Test Send Message'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isRunningTest ? null : _testAccessOtherUserDocument,
                      child: const Text('Test Access Other User Document'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
