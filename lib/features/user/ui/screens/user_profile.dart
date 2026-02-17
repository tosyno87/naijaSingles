import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/bloc/user/user_bloc.dart' as common_user;
import '../../../../common/constants/adds.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/utils/crousle_slider.dart';
import '../../../../common/utils/upload_media.dart';
import '../../../../common/widgets/custom_button.dart';
import '../../../../common/widgets/custom_snackbar.dart';
import '../../../../common/widgets/image_widget.dart';
import '../../../payment/ui/payments_detail.dart';
import '../../../payment/ui/products.dart';
import '../../bloc/update_user_bloc.dart';
import '../../bloc/update_user_state.dart';
import '../../bloc/user_event.dart';
import '../widgets/user_info.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.isPuchased,
    required this.items,
    required this.purchases,
    super.key,
  });
  // final bool isPuchased;
  final bool isPuchased;
  final Map items;
  final List<PurchaseDetails> purchases;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

final PageController pageController = PageController();

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
    final currentUser = context.watch<common_user.UserBloc>().currentUser;
    return BlocListener<UserBloc, UserStates>(
      listener: (context, state) {
        if (state is UpdatingUserProfilePicture) {
          CustomSnackbar.showSnackBarSimple(
            'Uploading..'.tr().toString(),
            context,
          );
        } else if (state is UserProfilePictureUploaded) {
          log('coming in userprofile updated');
          CustomSnackbar.showSnackBarSimple(
            'Media added successfully..'.tr().toString(),
            context,
          );
        } else if (state is UserUpdationFailed) {
          CustomSnackbar.showSnackBarSimple(
            state.message.tr().toString(),
            context,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(50),
              topRight: Radius.circular(50),
            ),
            color: Theme.of(context).primaryColor,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  height: 10,
                ),
                Hero(
                  tag: 'abc',
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: AppColors.secondaryColor,
                      child: Material(
                        color: Theme.of(context).primaryColor,
                        child: Stack(
                          children: <Widget>[
                            InkWell(
                              onTap: () => showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) => Info(
                                  currentUser,
                                  currentUser,
                                  false,
                                ),
                              ),
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    80,
                                  ),
                                  child: CustomCNImage(
                                    height: 150,
                                    width: 150,
                                    imageUrl: currentUser!.imageUrl!.isNotEmpty
                                        ? currentUser.imageUrl![0]
                                        : '',
                                    main: true,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                color: AppColors.primaryGreen,
                                child: IconButton(
                                  alignment: Alignment.center,
                                  icon: const Icon(
                                    Icons.photo_camera,
                                    size: 25,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    final file = await UploadMedia.getImage(
                                      context: context,
                                      checktype: 'profile',
                                    );
                                    log('file after edit is $file');
                                    // ignore: use_build_context_synchronously
                                    BlocProvider.of<UserBloc>(context).add(
                                      UpdateUserProfilePictures(
                                        checktype: 'profile',
                                        photo: file!,
                                        currentUser: currentUser,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  currentUser.name != null && currentUser.age != null
                      ? '${currentUser.name}, ${currentUser.age}'
                          .tr()
                          .toString()
                      : ''.tr().toString(),
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 30,
                  ),
                ),
                Text(
                  currentUser.editInfo!['job_title'] != null
                      ? "${currentUser.editInfo!['job_title'].toString().trim()} ${currentUser.editInfo!['company'] != null ? "at ${currentUser.editInfo!['company'].toString().trim()}" : ""}"
                          .tr()
                          .toString()
                      : ''.tr().toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.white
                        : Colors.black54,
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                  ),
                ),
                Text(
                  currentUser.editInfo!['university'] != null
                      ? "${currentUser.editInfo!['university']}"
                          .tr()
                          .toString()
                          .trim()
                      : ''.tr().toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.white
                        : Colors.black54,
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * .40,
                  child: Stack(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Align(
                          child: Column(
                            children: <Widget>[
                              SizedBox(
                                height: 70,
                                width: 70,
                                child: FloatingActionButton(
                                  heroTag: UniqueKey(),
                                  splashColor: AppColors.secondaryColor,
                                  backgroundColor: AppColors.primaryGreen,
                                  child: const Icon(
                                    Icons.add_a_photo,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  onPressed: () async {
                                    if (currentUser.imageUrl!.length < 9) {
                                      final file = await UploadMedia.getImage(
                                        context: context,
                                        checktype: 'addMedia',
                                      );
                                      // ignore: use_build_context_synchronously
                                      BlocProvider.of<UserBloc>(context).add(
                                        UpdateUserProfilePictures(
                                          checktype: 'addMedia',
                                          photo: file!,
                                          currentUser: currentUser,
                                        ),
                                      );
                                    } else {
                                      CustomSnackbar.showSnackBarSimple(
                                        'You can upload upto 9 images'
                                            .tr()
                                            .toString(),
                                        context,
                                      );
                                    }
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  'Add media'.tr().toString(),
                                  style: const TextStyle(
                                    color: AppColors.secondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30, top: 30),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            children: <Widget>[
                              FloatingActionButton(
                                splashColor: AppColors.secondaryColor,
                                heroTag: UniqueKey(),
                                backgroundColor: Colors.white,
                                child: const Icon(
                                  Icons.settings,
                                  color: AppColors.secondaryColor,
                                  size: 28,
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    RouteName.settingPage,
                                    arguments: {
                                      'currentUser': currentUser,
                                      'isPurchased': widget.isPuchased,
                                      'items': widget.items,
                                    },
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  'Settings'.tr().toString(),
                                  style: const TextStyle(
                                    color: AppColors.secondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 30,
                          top: 30,
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            children: <Widget>[
                              FloatingActionButton(
                                heroTag: UniqueKey(),
                                splashColor: AppColors.secondaryColor,
                                backgroundColor: Colors.white,
                                child: const Icon(
                                  Icons.edit,
                                  color: AppColors.secondaryColor,
                                  size: 28,
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    RouteName.editProfileScreen,
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  'Edit Info'.tr().toString(),
                                  style: const TextStyle(
                                    color: AppColors.secondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 180),
                        child: SizedBox(
                          height: 120,
                          child: CustomPaint(
                            // painter: CurvePainter(),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      CarouselSlider(
                        adds: adds,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                CustomButton(
                  text: widget.isPuchased
                      ? 'Check Payment Details'.tr().toString()
                      : 'Subscribe Plan'.tr().toString(),
                  onTap: () async {
                    if (widget.isPuchased) {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) =>
                              PaymentDetails(widget.purchases),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) =>
                              Products(currentUser, null, widget.items),
                        ),
                      );
                    }
                  },
                  color: AppColors.textPrimary,
                  active: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
