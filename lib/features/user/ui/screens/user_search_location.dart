import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/bloc/user/user_bloc.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/data/repo/phone_auth_repo.dart';
import '../../../../common/data/repo/user_location_repo.dart';
import '../../../../common/utils/welcome_dialog.dart';
import '../../../../common/widgets/custom_snackbar.dart';
import '../../../../services/firestore_database.dart';
import '../../../../services/location/bloc/userlocation_bloc.dart';
import '../../../auth/auth_status/bloc/registration/bloc/registration_bloc.dart';
import 'update_user_location.dart';

class SearchLocation extends StatefulWidget {
  const SearchLocation({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SearchLocationState createState() => _SearchLocationState();
}

class _SearchLocationState extends State<SearchLocation>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth auth = firebaseAuthInstance;

  final TextEditingController _city = TextEditingController();
  Map? selectedLocation;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    );

    unawaited(_animationController!.forward());

    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isTyping = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _focusNode.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['userData'];
    final profilePic = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['profilePic'] as File;

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
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF222222),
                size: 22,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: Stack(
                children: [
                  // Background subtle map illustration
                  Positioned(
                    top: -50,
                    right: -100,
                    child: Opacity(
                      opacity: 0.05,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('asset/pattern.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 20),

                        // Title and subtitle with fade animation
                        FadeTransition(
                          opacity: _fadeAnimation!,
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Where are you located?',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF222222),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'This helps us find matches near you.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF888888),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Location icon and input field with animation
                        FadeTransition(
                          opacity: _fadeAnimation!,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _isTyping
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF27AE60)
                                            .withValues(alpha: 0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: TextField(
                              readOnly: true,
                              focusNode: _focusNode,
                              controller: _city,
                              decoration: InputDecoration(
                                hintText: 'Enter your city or state',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF888888),
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 16, right: 8),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFF27AE60),
                                    size: 24,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF27AE60),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UpdateLocation(
                                      selectedLocation: selectedLocation ?? {},
                                    ),
                                  ),
                                );
                                log('after pop address is ${result.toString()}');
                                if (result != null) {
                                  selectedLocation = result;
                                  log('after pop selected is ${selectedLocation.toString()}');
                                  _city.text = result['address'] ?? '';
                                  if (mounted) setState(() {});
                                }
                              },
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Progress indicator
                        FadeTransition(
                          opacity: _fadeAnimation!,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.6,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEEEEE),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.3,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF27AE60),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Continue labelLarge with animation
                        FadeTransition(
                          opacity: _fadeAnimation!,
                          child: BlocConsumer<RegistrationBloc,
                              RegistrationStates>(
                            listener: (context, registrationState) {
                              if (registrationState is RegistrationSuccess) {
                                log('userregistrationsuccess');
                                context.read<UserBloc>().add(
                                    UserDataUpdated(registrationState.user));
                                unawaited(showWelcomDialog(context));
                              }
                            },
                            builder: (context, registrationState) {
                              if (registrationState is RegistrationLoading) {
                                return Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF27AE60),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF27AE60)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                );
                              } else {
                                return GestureDetector(
                                  onTap: _city.text.isNotEmpty
                                      ? () async {
                                          userData.addAll(
                                            {
                                              'location': {
                                                'latitude': selectedLocation?[
                                                        'position']
                                                    ['coordinates'][1],
                                                'longitude': selectedLocation?[
                                                        'position']
                                                    ['coordinates'][0],
                                                'address': selectedLocation?[
                                                    'address'],
                                              },
                                              'maximum_distance': 20,
                                              'age_range': {
                                                'min': '20',
                                                'max': '50',
                                              },
                                              'lastvisited':
                                                  FieldValue.serverTimestamp(),
                                              'createdAt':
                                                  FieldValue.serverTimestamp(),
                                            },
                                          );
                                          await FireStoreClass.uploadprofile(
                                            currentUserId:
                                                auth.currentUser!.uid,
                                            file: profilePic,
                                          );
                                          if (!context.mounted) return;
                                          context.read<RegistrationBloc>().add(
                                                RegistrationRequest(
                                                  userdata: userData,
                                                ),
                                              );
                                          log(r'added user finally $userData.toString()');
                                        }
                                      : () {
                                          CustomSnackbar.showSnackBarSimple(
                                            'Please select location to continue'
                                                .tr()
                                                .toString(),
                                            context,
                                          );
                                        },
                                  child: Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: _city.text.isNotEmpty
                                          ? const Color(0xFF27AE60)
                                          : const Color(0xFFCCCCCC),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: _city.text.isNotEmpty
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF27AE60)
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Continue',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
