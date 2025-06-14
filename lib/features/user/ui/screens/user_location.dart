// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/common/widgets/custom_snackbar.dart';
import 'package:naijasingles/services/firestore_database.dart';
import 'package:naijasingles/services/location/bloc/userlocation_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/data/repo/phone_auth_repo.dart';
import '../../../../common/data/repo/user_location_repo.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/providers/user_provider.dart';
import '../../../../common/utils/welcome_dialog.dart';
import '../../../../common/widgets/custom_button.dart';
import '../../../../common/widgets/hookup_circularbar.dart';
import '../../../auth/auth_status/bloc/registration/bloc/registration_bloc.dart';

class AllowLocation extends StatelessWidget {
  const AllowLocation({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = firebaseAuthInstance;
    var userData = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['userData'];
    var profilePic = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['profilePic'] as File;
    final ValueNotifier<bool> isProcessing = ValueNotifier(false);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UserLocationReporistory>(
            create: (context) => UserLocationReporistoryImpl()),
        RepositoryProvider<PhoneAuthRepository>(
            create: (context) => PhoneAuthRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<UserLocationBloc>(
            create: (context) => UserLocationBloc(
                userLocationReporistory:
                    RepositoryProvider.of<UserLocationReporistory>(context)),
          ),
          BlocProvider<RegistrationBloc>(
            create: (context) => RegistrationBloc(
                phoneAuthRepository:
                    RepositoryProvider.of<PhoneAuthRepository>(context)),
          ),
        ],
        child: ValueListenableBuilder(
            valueListenable: isProcessing,
            builder: (context, bool isInProcess, _) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),
                          // Green-themed location illustration
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0x1527AE60),
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
                          Text(
                            "Enable Location",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF222222),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Subtitle with muted gray color
                          Text(
                            "We'll use your location to help you find people nearby.",
                            style: TextStyle(
                              fontSize: 16,
                              color: const Color(0xFF888888),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const Spacer(flex: 1),
                          
                          // Primary green button
                          BlocConsumer<RegistrationBloc, RegistrationStates>(
                            listener: (context, state) {
                              if (state is RegistrationLoading) {
                                CustomSnackbar.showSnackBarSimple(
                                    "Loading...".tr().toString(), context);
                              }
                              if (state is RegistrationFailed) {
                                isProcessing.value = false;
                                CustomSnackbar.showSnackBarSimple(
                                    state.message, context);
                              }
                              if (state is RegistrationSuccess) {
                                log("userregistrationsuccess");
                                Provider.of<UserProvider>(context, listen: false)
                                    .currentUser = state.user;
                                isProcessing.value = false;
                                showWelcomDialog(context);
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
                                    log("location successfully get");

                                    userData.addAll(
                                      {
                                        'location': {
                                          'latitude': state.latitude,
                                          'longitude': state.longitude,
                                          'address': state.formattedAddress,
                                        },
                                        'maximum_distance': 20,
                                        'age_range': {
                                          'min': "20",
                                          'max': "50",
                                        },
                                        'lastvisited':
                                            FieldValue.serverTimestamp(),
                                        'createdAt': FieldValue.serverTimestamp()
                                      },
                                    );
                                    log("added user finally $userData.toString()");
                                    UploadTask? task =
                                        await FireStoreClass.uploadprofile(
                                            currentUserId: auth.currentUser!.uid,
                                            file: profilePic);
                                    if (task != null) {
                                      context.read<RegistrationBloc>().add(
                                          RegistrationRequest(
                                              userdata: userData));
                                    } else {
                                      CustomSnackbar.showSnackBarSimple(
                                          "Failed to upload Image"
                                              .tr()
                                              .toString(),
                                          context);
                                    }
                                  }
                                  if (state is UserLocationFailed) {
                                    isProcessing.value = false;
                                    log(state.message);
                                    CustomSnackbar.showSnackBarSimple(
                                        state.message, context);
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
                                        borderRadius: BorderRadius.circular(12),
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "ENABLE LOCATION",
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
                          
                          // Secondary "Skip for now" button
                          TextButton(
                            onPressed: () {
                              if (!isProcessing.value) {
                                Navigator.pushNamed(
                                  context,
                                  RouteName.searchLocationpage,
                                  arguments: {
                                    'userData': userData,
                                    'profilePic': profilePic
                                  },
                                );
                              }
                            },
                            child: Text(
                              "Skip for now",
                              style: TextStyle(
                                color: const Color(0xFF888888),
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
              );
            }),
      ),
    );
  }
}
