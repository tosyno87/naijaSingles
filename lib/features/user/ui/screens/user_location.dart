// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import 'package:hookup4u2/common/widets/custom_snackbar.dart';
import 'package:hookup4u2/services/firestore_database.dart';
import 'package:hookup4u2/services/location/bloc/userlocation_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/data/repo/phone_auth_repo.dart';
import '../../../../common/data/repo/user_location_repo.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/providers/user_provider.dart';
import '../../../../common/utlis/welcome_dialog.dart';
import '../../../../common/widets/custom_button.dart';
import '../../../../common/widets/hookup_circularbar.dart';
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
                  floatingActionButtonLocation:
                      FloatingActionButtonLocation.startTop,
                  backgroundColor: Theme.of(context).primaryColor,
                  floatingActionButton: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          height: 45,
                          width: 45,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 50),
                              child: FloatingActionButton(
                                heroTag: UniqueKey(),
                                elevation: 1,
                                backgroundColor: themeProvider.isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                onPressed: () {
                                  !isProcessing.value
                                      ? Navigator.pop(context)
                                      : null;
                                },
                                child: IconButton(
                                  color: themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                  iconSize: 20,
                                  icon: const Icon(Icons.arrow_back_ios),
                                  onPressed: () {
                                    !isProcessing.value
                                        ? Navigator.pop(context)
                                        : null;
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15, right: 25),
                          child: AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 5000),
                              child: SizedBox(
                                height: 42,
                                child: FloatingActionButton.extended(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  elevation: 10,
                                  heroTag: UniqueKey(),
                                  backgroundColor: Colors.white,
                                  onPressed: () {
                                    !isProcessing.value
                                        ? Navigator.pushNamed(context,
                                            RouteName.searchLocationpage,
                                            arguments: {
                                                'userData': userData,
                                                'profilePic': profilePic
                                              })
                                        : null;
                                  },
                                  label: Text(
                                    "Skip..".tr().toString(),
                                    style: TextStyle(color: primaryColor),
                                  ),
                                  icon: Icon(
                                    Icons.navigate_next,
                                    color: primaryColor,
                                  ),
                                ),
                              )),
                        ),
                      ],
                    ),
                  ),
                  body: SingleChildScrollView(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: Stack(children: <Widget>[
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(top: 50),
                              child: Center(
                                child: CircleAvatar(
                                  backgroundColor:
                                      secondryColor.withOpacity(.2),
                                  radius: 110,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 90,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                                padding: const EdgeInsets.only(top: 0),
                                child: RichText(
                                  text: TextSpan(
                                    text: "Enable location".tr().toString(),
                                    style: TextStyle(
                                        color: themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 40),
                                    children: [
                                      TextSpan(
                                          text:
                                              "\nYou'll need to provide a \nlocation\nin order to search users around you."
                                                  .tr()
                                                  .toString(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              color: secondryColor,
                                              textBaseline:
                                                  TextBaseline.alphabetic,
                                              fontSize: 18)),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                )),
                            const Padding(
                              padding: EdgeInsets.all(50.0),
                            ),
                          ],
                        ),
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
                              // Navigate to a new screen when the registration is successful
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
                                if (state is UserLocationLoading) {
                                  return const Hookup4uBar();
                                }
                                if (state is UserLocationSuccess) {
                                  return const Hookup4uBar();
                                }
                                return CustomButton(
                                  text: "Allow Location".tr().toString(),
                                  onTap: () async {
                                    isProcessing.value = true;
                                    context
                                        .read<UserLocationBloc>()
                                        .add(const UserLocationRequest());
                                  },
                                  color: textColor,
                                  active: true,
                                );
                              },
                            );
                          },
                        ),
                      ]),
                    ),
                  ));
            }),
      ),
    );
  }
}
