// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hookup4u2/common/widets/custom_button.dart';

import 'package:hookup4u2/features/user/ui/screens/update_user_location.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/data/repo/phone_auth_repo.dart';
import '../../../../common/data/repo/user_location_repo.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/providers/user_provider.dart';
import '../../../../common/utlis/welcome_dialog.dart';
import '../../../../common/widets/custom_snackbar.dart';
import '../../../../common/widets/hookup_circularbar.dart';

import '../../../../services/firestore_database.dart';
import '../../../../services/location/bloc/userlocation_bloc.dart';
import '../../../auth/auth_status/bloc/registration/bloc/registration_bloc.dart';

class SearchLocation extends StatefulWidget {
  const SearchLocation({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SearchLocationState createState() => _SearchLocationState();
}

class _SearchLocationState extends State<SearchLocation> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth auth = firebaseAuthInstance;

  final TextEditingController _city = TextEditingController();
  Map? selectedLocation;

  @override
  Widget build(BuildContext context) {
    var userData = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['userData'];
    var profilePic = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['profilePic'] as File;
    final themeProvider = Provider.of<ThemeProvider>(context);
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
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).primaryColor,
          floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
          floatingActionButton: SizedBox(
            height: 45,
            width: 45,
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 50),
              child: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: FloatingActionButton(
                  elevation: 1,
                  backgroundColor:
                      themeProvider.isDarkMode ? Colors.black : Colors.white,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: IconButton(
                    iconSize: 20,
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black,
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 50, top: 120),
                    child: Text(
                      "Select\nyour state".tr().toString(),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: TextField(
                            autofocus: false,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: "Enter your city name".tr().toString(),
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: primaryColor)),
                              helperText: "This is how it will appear in App."
                                  .tr()
                                  .toString(),
                              helperStyle:
                                  TextStyle(color: secondryColor, fontSize: 15),
                            ),
                            controller: _city,
                            onTap: () async {
                              var result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => UpdateLocation(
                                            selectedLocation:
                                                selectedLocation ?? {},
                                          )));
                              log("after pop address is ${result.toString()}");
                              if (result != null) {
                                selectedLocation = result;
                                log("after pop selected is ${selectedLocation.toString()}");
                                _city.text = result['address'] ?? "";
                                if (mounted) setState(() {});
                              }
                            }),
                      ),
                      const SizedBox(
                        height: 130,
                      ),
                      _city.text.isNotEmpty
                          ? BlocConsumer<RegistrationBloc, RegistrationStates>(
                              listener: (context, registrationState) {
                                if (registrationState is RegistrationSuccess) {
                                  log("userregistrationsuccess");
                                  Provider.of<UserProvider>(context,
                                          listen: false)
                                      .currentUser = registrationState.user;
                                  // Navigate to a new screen when the registration is successful
                                  showWelcomDialog(context);
                                }
                              },
                              builder: (context, registrationState) {
                                if (registrationState is RegistrationLoading) {
                                  // Show a loading indicator while the registration is in progress
                                  return const Hookup4uBar();
                                } else {
                                  // Show the "Allow Location" button if the registration is not in progress
                                  return CustomButton(
                                    text: "CONTINUE".tr().toString(),
                                    onTap: () async {
                                      userData.addAll(
                                        {
                                          'location': {
                                            'latitude':
                                                selectedLocation?['position']
                                                    ['coordinates'][1],
                                            'longitude':
                                                selectedLocation?['position']
                                                    ['coordinates'][0],
                                            'address':
                                                selectedLocation?['address'],
                                          },
                                          'maximum_distance': 20,
                                          'age_range': {
                                            'min': "20",
                                            'max': "50",
                                          },
                                          'lastvisited':
                                              FieldValue.serverTimestamp(),
                                          'createdAt':
                                              FieldValue.serverTimestamp()
                                        },
                                      );
                                      // UPLOAD PROFILE FIRST
                                      await FireStoreClass.uploadprofile(
                                          currentUserId: auth.currentUser!.uid,
                                          file: profilePic);
                                      context.read<RegistrationBloc>().add(
                                            RegistrationRequest(
                                                userdata: userData),
                                          );
                                      log("added user finally $widget.userData.toString()");
                                    },
                                    color: textColor,
                                    active: true,
                                  );
                                }
                              },
                            )
                          : CustomButton(
                              text: "CONTINUE".tr().toString(),
                              onTap: () {
                                CustomSnackbar.showSnackBarSimple(
                                  "please select location to continue"
                                      .tr()
                                      .toString(),
                                  context,
                                );
                              },
                              color: secondryColor,
                              active: themeProvider.isDarkMode ? true : false)
                    ],
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
