import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/bloc/user/user_bloc.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/data/repo/phone_auth_repo.dart';
import '../../../../common/data/repo/user_location_repo.dart';
import '../../../../common/utils/welcome_dialog.dart';
import '../../../../common/widgets/custom_snackbar.dart';
import '../../../../common/widgets/hookup_circularbar.dart';
import '../../../../services/firestore_database.dart';
import '../../../../services/location/bloc/userlocation_bloc.dart';
import '../../../auth/auth_status/bloc/registration/bloc/registration_bloc.dart';

class AllowLocation extends StatelessWidget {
  const AllowLocation({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = firebaseAuthInstance;
    final userData = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['userData'];
    final profilePic = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['profilePic'] as File;
    final ValueNotifier<bool> isProcessing = ValueNotifier(false);

    // Function to handle registration without location
    Future<void> proceedWithoutLocation() async {
      if (isProcessing.value) return;

      isProcessing.value = true;
      log('Proceeding without location');

      try {
        // Get default location
        final UserLocationReporistoryImpl locationRepo =
            UserLocationReporistoryImpl();
        final defaultLocation = await locationRepo.getDefaultLocation();

        // Add default location to user data
        userData.addAll({
          'location': {
            'latitude': defaultLocation['latitude'],
            'longitude': defaultLocation['longitude'],
            'address': defaultLocation['PlaceName'],
          },
          'maximum_distance': 20,
          'age_range': {
            'min': '20',
            'max': '50',
          },
          'lastvisited': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        log('Added default location to user data');

        // Upload profile picture
        try {
          final UploadTask? task = await FireStoreClass.uploadprofile(
            currentUserId: auth.currentUser!.uid,
            file: profilePic,
          );

          if (task != null) {
            if (!context.mounted) return;
            context
                .read<RegistrationBloc>()
                .add(RegistrationRequest(userdata: userData));
          } else {
            isProcessing.value = false;
            if (!context.mounted) return;
            CustomSnackbar.showSnackBarSimple(
              'Failed to upload image. Please try again.',
              context,
            );
          }
        } catch (e) {
          isProcessing.value = false;
          log('Error uploading profile: ${e.toString()}');
          if (!context.mounted) return;
          CustomSnackbar.showSnackBarSimple(
            'Error uploading profile: ${e.toString()}',
            context,
          );
        }
      } catch (e) {
        isProcessing.value = false;
        log('Error in proceedWithoutLocation: ${e.toString()}');
        if (!context.mounted) return;
        CustomSnackbar.showSnackBarSimple(
          'Error completing registration: ${e.toString()}',
          context,
        );
      }
    }

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UserLocationReporistory>(
          create: (context) => UserLocationReporistoryImpl(),
        ),
        RepositoryProvider<PhoneAuthRepository>(
          create: (context) => PhoneAuthRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<UserLocationBloc>(
            create: (context) => UserLocationBloc(
              userLocationReporistory:
                  RepositoryProvider.of<UserLocationReporistory>(context),
            ),
          ),
          BlocProvider<RegistrationBloc>(
            create: (context) => RegistrationBloc(
              phoneAuthRepository:
                  RepositoryProvider.of<PhoneAuthRepository>(context),
            ),
          ),
        ],
        child: ValueListenableBuilder(
          valueListenable: isProcessing,
          builder: (context, bool isInProcess, _) => Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Progress indicator (100% complete)
                    Container(
                      height: 4,
                      width: MediaQuery.of(context).size.width -
                          48, // Full width minus padding
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Green-themed location illustration
                    Container(
                      width: 180,
                      height: 180,
                      decoration: const BoxDecoration(
                        color: Color(0x1527AE60),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFF27AE60),
                        size: 90,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Title with larger, bolder font
                    const Text(
                      'Enable Location',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Subtitle with muted gray color
                    const Text(
                      "We'll use your location to help you find people nearby.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(),

                    // Primary green labelLarge
                    BlocConsumer<RegistrationBloc, RegistrationStates>(
                      listener: (context, state) {
                        if (state is RegistrationLoading) {
                          CustomSnackbar.showSnackBarSimple(
                            'Loading...'.tr().toString(),
                            context,
                          );
                        }
                        if (state is RegistrationFailed) {
                          isProcessing.value = false;
                          CustomSnackbar.showSnackBarSimple(
                            state.message,
                            context,
                          );
                        }
                        if (state is RegistrationSuccess) {
                          log('userregistrationsuccess');
                          context.read<UserBloc>().add(UserDataUpdated(state.user));
                          isProcessing.value = false;
                          unawaited(showWelcomDialog(context));
                        }
                      },
                      builder: (context, state) {
                        if (state is RegistrationLoading) {
                          return const Hookup4uBar();
                        }
                        return BlocConsumer<UserLocationBloc,
                            UserLocationStates>(
                          listener: (context, state) async {
                            if (state is UserLocationSuccess) {
                              log('location successfully get');
                              try {
                                userData.addAll(
                                  {
                                    'location': {
                                      'latitude': state.latitude,
                                      'longitude': state.longitude,
                                      'address': state.formattedAddress,
                                    },
                                    'maximum_distance': 20,
                                    'age_range': {
                                      'min': '20',
                                      'max': '50',
                                    },
                                    'lastvisited': FieldValue.serverTimestamp(),
                                    'createdAt': FieldValue.serverTimestamp(),
                                  },
                                );
                                log('added user finally $userData.toString()');

                                try {
                                  final UploadTask? task =
                                      await FireStoreClass.uploadprofile(
                                    currentUserId: auth.currentUser!.uid,
                                    file: profilePic,
                                  );

                                  if (task != null) {
                                    if (!context.mounted) return;
                                    context.read<RegistrationBloc>().add(
                                          RegistrationRequest(
                                            userdata: userData,
                                          ),
                                        );
                                  } else {
                                    isProcessing.value = false;
                                    if (!context.mounted) return;
                                    CustomSnackbar.showSnackBarSimple(
                                      'Failed to upload image. Please try again.',
                                      context,
                                    );
                                  }
                                } catch (e) {
                                  isProcessing.value = false;
                                  log('Error uploading profile: ${e.toString()}');
                                  if (!context.mounted) return;
                                  CustomSnackbar.showSnackBarSimple(
                                    'Error uploading profile: ${e.toString()}',
                                    context,
                                  );
                                }
                              } catch (e) {
                                isProcessing.value = false;
                                log('Error adding user data: ${e.toString()}');
                                CustomSnackbar.showSnackBarSimple(
                                  'Error adding user data: ${e.toString()}',
                                  context,
                                );
                              }
                            }
                            if (state is UserLocationFailed) {
                              isProcessing.value = false;
                              log('Location failed: ${state.message}');
                              CustomSnackbar.showSnackBarSimple(
                                state.message,
                                context,
                              );

                              // Show dialog to proceed with default location
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) => AlertDialog(
                                  title: const Text('Location Error'),
                                  content: const Text(
                                    "We couldn't access your location. Would you like to continue with a default location?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        unawaited(proceedWithoutLocation());
                                      },
                                      child: const Text('Continue'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          builder: (context, state) {
                            if (state is UserLocationLoading ||
                                state is UserLocationSuccess) {
                              return Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF27AE60),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              );
                            }
                            return GestureDetector(
                              onTap: () {
                                if (!isProcessing.value) {
                                  isProcessing.value = true;
                                  context
                                      .read<UserLocationBloc>()
                                      .add(const UserLocationRequest());
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF27AE60),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Center(
                                  child: Text(
                                    'ENABLE LOCATION',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Secondary "Skip for now" labelLarge
                    TextButton(
                      onPressed: () {
                        if (!isProcessing.value) {
                          unawaited(proceedWithoutLocation());
                        }
                      },
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
