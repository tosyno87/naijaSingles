import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../common/constants/app_colors.dart';
import '../../common/data/repo/user_search_repo.dart';
import '../../common/providers/user_provider.dart';
import '../../models/user_model.dart';
import 'screens/tribe_connect_screen.dart';

class ExploreScreen extends StatefulWidget {

  const ExploreScreen({
    super.key,
    this.showBackButton = false,
  });
  final bool showBackButton;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _error;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user != null) {
        if (mounted && !_disposed) {
          setState(() {
            _currentUser = user;
          });
        }
        await _loadUsers();
      } else {
        if (mounted && !_disposed) {
          setState(() {
            _error = 'Please log in to explore profiles';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      log('Error loading current user: $e');
      if (mounted && !_disposed) {
        setState(() {
          _error = 'Failed to load user data';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUsers() async {
    if (_currentUser == null || _disposed) return;

    try {
      if (mounted && !_disposed) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final users = await UserSearchRepo.getUserList(_currentUser!);

      if (mounted && !_disposed) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error loading users: $e');
      if (mounted && !_disposed) {
        setState(() {
          _error = 'Failed to load profiles';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your tribe...',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: AppColors.error.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCurrentUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 60,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Please log in to explore profiles',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TribeConnectScreen(
      currentUser: _currentUser!,
      users: _users,
    );
  }
}
