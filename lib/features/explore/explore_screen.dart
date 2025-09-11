import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:naijasingles/common/providers/user_provider.dart';
import 'package:naijasingles/features/explore/screens/tribe_connect_screen.dart';
import 'package:naijasingles/models/user_model.dart';
import 'package:naijasingles/common/data/repo/user_search_repo.dart';
import 'package:naijasingles/common/constants/app_colors.dart';

class ExploreScreen extends StatefulWidget {
  final bool showBackButton;

  const ExploreScreen({
    Key? key,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;
      
      if (user != null) {
        setState(() {
          _currentUser = user;
        });
        await _loadUsers();
      } else {
        setState(() {
          _error = 'Please log in to explore profiles';
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error loading current user: $e');
      setState(() {
        _error = 'Failed to load user data';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    if (_currentUser == null) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final users = await UserSearchRepo.getUserList(_currentUser!);
      
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      log('Error loading users: $e');
      setState(() {
        _error = 'Failed to load profiles';
        _isLoading = false;
      });
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
              CircularProgressIndicator(
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
                child: Text('Retry'),
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
