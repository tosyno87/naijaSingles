import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/bloc/user/user_bloc.dart';
import '../../common/constants/app_colors.dart';
import '../../common/data/repo/user_search_repo.dart';
import '../../common/widgets/state_views/state_views.dart';
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
    unawaited(_loadCurrentUser());
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = context.read<UserBloc>().currentUser;

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
    } on Object catch (e) {
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

      final users = await UserSearchRepo.getUserList(
        _currentUser!,
        intentFilter: _currentUser!.lookingFor,
      );

      if (mounted && !_disposed) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } on Object catch (e) {
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
      return const Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: AppLoadingView(message: 'Loading your tribe...'),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: AppErrorView(
          title: 'Unable to load connect feed',
          message: _error!,
          onRetry: _loadCurrentUser,
        ),
      );
    }

    if (_currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: AppEmptyView(
          title: 'Please log in',
          subtitle: 'Sign in to explore profiles in Connect.',
          icon: Icons.person_off,
        ),
      );
    }

    return TribeConnectScreen(
      currentUser: _currentUser!,
      users: _users,
      onFiltersApplied: _loadUsers,
    );
  }
}
