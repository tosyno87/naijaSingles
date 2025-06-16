import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/providers/user_provider.dart';
import '../../../../common/utils/upload_media.dart';
import '../../../../common/widgets/custom_button.dart';
import '../../../../common/widgets/custom_snackbar.dart';
import '../../../../services/firestore_database.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  File? _image;
  bool _loading = false;

  Future<void> _pickImage() async {
    final file =
        await UploadMedia.getImage(context: context, checktype: 'profile');
    if (file != null && mounted) {
      setState(() {
        _image = file;
      });
    }
  }

  Future<void> _submit() async {
    if (_image == null) return;
    setState(() {
      _loading = true;
    });
    final user =
        Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user != null && user.id != null) {
      final url = await FireStoreClass.uploadVerification(
          userId: user.id!, file: _image!);
      if (url != null && mounted) {
        CustomSnackbar.showSnackBarSimple(
            'Verification image uploaded', context);
        Navigator.pop(context);
      } else if (mounted) {
        CustomSnackbar.showSnackBarSimple('Upload failed', context);
      }
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Upload a selfie or ID to verify your account',
                style: TextStyle(
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor),
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_image!, fit: BoxFit.cover),
                        )
                      : const Center(
                          child: Icon(Icons.camera_alt, size: 60),
                        ),
                ),
              ),
              const SizedBox(height: 40),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'SUBMIT',
                      onTap: _image != null ? _submit : () {},
                      color: primaryColor,
                      active: _image != null,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
