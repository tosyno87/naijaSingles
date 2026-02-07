import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/user_model.dart';
import '../../constants/constants.dart';
import '../../utils/app_logger.dart';

part 'user_event.dart';
part 'user_state.dart';

/// BLoC for managing current user state (listens to Firestore user doc and auth).
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(const UserInitial()) {
    on<UserListenStarted>(_onUserListenStarted);
    on<UserListenStopped>(_onUserListenStopped);
    on<UserDataUpdated>(_onUserDataUpdated);
    on<UserAuthStateChanged>(_onUserAuthStateChanged);

    // Start listening automatically when bloc is created
    add(const UserListenStarted());
  }

  final FirebaseAuth _auth = firebaseAuthInstance;
  final CollectionReference _userCollection =
      firebaseFireStoreInstance.collection('users');

  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<User?>? _authStateSubscription;

  /// Get current user from state
  UserModel? get currentUser {
    if (state is UserLoaded) {
      return (state as UserLoaded).user;
    }
    return null;
  }

  Future<void> _onUserListenStarted(
    UserListenStarted event,
    Emitter<UserState> emit,
  ) async {
    // Cancel any existing subscription before starting a new one
    await _userSubscription?.cancel();
    _userSubscription = null;

    // Listen for authentication state changes
    await _authStateSubscription?.cancel();
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User logged in - start listening to user details
        add(const UserListenStarted());
      } else {
        // User is logged out - cancel any active subscriptions and clear user data
        add(const UserListenStopped());
        add(const UserDataUpdated(null));
      }
    });

    // Start listening to current user details
    await _listenCurrentUserDetails(emit);
  }

  Future<void> _onUserListenStopped(
    UserListenStopped event,
    Emitter<UserState> emit,
  ) async {
    await _userSubscription?.cancel();
    _userSubscription = null;
    await _authStateSubscription?.cancel();
    _authStateSubscription = null;
    emit(const UserLoaded(null));
  }

  void _onUserDataUpdated(
    UserDataUpdated event,
    Emitter<UserState> emit,
  ) {
    emit(UserLoaded(event.user));
  }

  void _onUserAuthStateChanged(
    UserAuthStateChanged event,
    Emitter<UserState> emit,
  ) {
    if (!event.isAuthenticated) {
      emit(const UserLoaded(null));
    }
  }

  Future<void> _listenCurrentUserDetails(Emitter<UserState> emit) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        emit(const UserLoading());
        // Listen to the specific document directly using the user's UID as the document ID
        _userSubscription = _userCollection.doc(user.uid).snapshots().listen(
          (documentSnapshot) {
            try {
              if (documentSnapshot.exists) {
                final userData = UserModel.fromDocument(documentSnapshot);
                add(UserDataUpdated(userData));
              } else {
                AppLogger.warning(
                    'User document does not exist for UID: ${user.uid}');
                add(const UserDataUpdated(null));
              }
            } on Exception catch (e) {
              AppLogger.error('Error parsing user document', error: e);
              // Don't set currentUser to null here, keep existing data
            }
          },
          onError: (error) {
            // Only log errors if user is still authenticated
            // Permission errors when user is logged out are expected
            if (_auth.currentUser != null) {
              AppLogger.error(
                'Error listening to user details',
                error: error,
              );
              add(const UserAuthStateChanged(false));
            }
          },
        );
      } on Exception catch (e) {
        AppLogger.error('Exception in listenCurrentUserdetails', error: e);
        emit(UserError(e.toString()));
      }
    } else {
      // User is not authenticated - ensure user data is cleared
      emit(const UserLoaded(null));
      AppLogger.debug('No authenticated user found');
    }
  }

  /// Cancel all subscriptions (call when bloc is closed)
  @override
  Future<void> close() async {
    await _userSubscription?.cancel();
    await _authStateSubscription?.cancel();
    return super.close();
  }
}
