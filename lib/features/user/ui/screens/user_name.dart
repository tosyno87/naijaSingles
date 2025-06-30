import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:naijasingles/common/widgets/custom_snackbar.dart';

import '../../../../common/routes/route_name.dart';
import '../../../../common/widgets/custom_button.dart';

class UserName extends StatefulWidget {
  const UserName({super.key});

  @override
  UserNameState createState() => UserNameState();
}

class UserNameState extends State<UserName> {
  Map<String, dynamic> userData = {}; //user personal info
  String username = '';
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto focus the text field after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              
              // Progress indicator
              Container(
                height: 4,
                width: screenSize.width * 0.15, // 15% of screen width
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Title - Option 2: Playful & Flirty
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Let's start with your name...",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "This is the first thing your future match will see!",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Text field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: TextFormField(
                  controller: _controller,
                  focusNode: _focusNode,
                  cursorColor: const Color(0xFF27AE60),
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    hintText: "Enter your first name",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  onChanged: (value) {
                    setState(() {
                      username = value.trim();
                    });
                  },
                ),
              ),
              
              const Spacer(),
              
              // Continue labelLarge
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: AnimatedOpacity(
                  opacity: username.isNotEmpty ? 1.0 : 0.7,
                  duration: const Duration(milliseconds: 200),
                  child: CustomButton(
                    active: username.isNotEmpty,
                    color: const Color(0xFF27AE60),
                    onTap: () {
                      if (username.isNotEmpty) {
                        userData.addAll({'UserName': username});
                        log(userData.toString());
                        Navigator.pushNamed(context, RouteName.userDobScreen,
                            arguments: userData);
                      } else {
                        CustomSnackbar.showSnackBarSimple(
                            "Please enter your name", context);
                      }
                    },
                    text: 'CONTINUE',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
