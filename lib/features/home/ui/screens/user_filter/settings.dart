// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import 'package:hookup4u2/common/widets/text_button.dart';
import 'package:hookup4u2/features/ads/google_ads.dart';
import 'package:hookup4u2/features/home/ui/widgets/street_view_enable.dart';
import 'package:hookup4u2/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../common/constants/colors.dart';
import '../../../../../common/providers/street_view_provider.dart';
import '../../../../../common/providers/theme_provider.dart';
import '../../../../../common/widets/change_language_widget.dart';
import '../../../../../common/widets/custom_snackbar.dart';
import '../../../../../common/widets/theme_change.dart';
import '../../../bloc/searchuser_bloc.dart';
import '../../widgets/age_range.dart';
import '../../widgets/delete_account.dart';
import '../../widgets/distance_widget.dart';
import '../../widgets/logout_dialog.dart';
import '../../widgets/show_me.dart';
import '../../widgets/update_address.dart';
import 'bloc/userfilter_bloc.dart';

class SettingPage extends StatefulWidget {
  final UserModel currentUser;
  final bool isPurchased;
  final Map items;
  const SettingPage(
      {required this.currentUser,
      required this.isPurchased,
      required this.items,
      super.key});

  @override
  SettingPageState createState() => SettingPageState();
}

class SettingPageState extends State<SettingPage> {
  Map<String, dynamic> changeValues = {};
  final BannerAd myBanner = BannerAd(
    adUnitId: AdHelper.bannerAdUnitId,
    size: AdSize.banner,
    request: const AdRequest(),
    listener: const BannerAdListener(),
  );
  late AdWidget adWidget;

  Future<bool> _onWillPop(BuildContext context) async {
    final currentstate = BlocProvider.of<UserfilterBloc>(context).state;
    if (currentstate == UpdatingUserFilter()) {
      log("coming under updating state");
      return false;
    }

    if (changeValues.isNotEmpty) {
      return (await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Save Changes?".tr().toString()),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    log("change---$changeValues");
                  },
                  child: Text(
                    "Close".tr().toString(),
                    style: TextStyle(color: primaryColor),
                  ),
                ),
                BlocBuilder<UserfilterBloc, UserfilterState>(
                  builder: (context, state) {
                    if (state is UpdatingUserFilter) {
                      return CircularProgressIndicator(
                        color: primaryColor,
                      );
                    }
                    return TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);

                        log("not empty changesvalue");
                        BlocProvider.of<UserfilterBloc>(context)
                            .add(ChangefilterRequest(details: changeValues));
                        context.read<SearchUserBloc>().add(
                            LoadUserEvent(currentUser: widget.currentUser));
                      },
                      child: Text("Save".tr().toString(),
                          style: TextStyle(color: primaryColor)),
                    );
                  },
                ),
              ],
            ),
          )) ??
          false;
    } else {
      return true;
    }
  }

  late int freeR;
  late int paidR;

  @override
  void initState() {
    super.initState();
    adWidget = AdWidget(ad: myBanner);
    myBanner.load();
    freeR = widget.items['free_radius'] != null
        ? int.parse(widget.items['free_radius'])
        : 400;
    paidR = widget.items['paid_radius'] != null
        ? int.parse(widget.items['paid_radius'])
        : 400;
    setState(() {
      if (!widget.isPurchased && widget.currentUser.maxDistance! > freeR) {
        widget.currentUser.maxDistance = freeR.round();
      } else if (widget.isPurchased &&
          widget.currentUser.maxDistance! >= paidR) {
        widget.currentUser.maxDistance = paidR.round();
      }
    });
  }

  @override
  void dispose() {
    myBanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    log(widget.currentUser.toString());
    log("my phone number is ${widget.currentUser.phoneNumber.toString()}");
    return BlocListener<UserfilterBloc, UserfilterState>(
      listener: (context, state) {
        if (state is UserFilterUpdationFailed) {
          CustomSnackbar.showSnackBarSimple(
              "Filter not applied..".tr().toString(), context);
        } else if (state is UserFilterUpdated) {
          CustomSnackbar.showSnackBarSimple(
              "Changes saved.".tr().toString(), context);
          log("filter succesfully applied ....".tr().toString());

          changeValues.clear();
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          if (didPop) {
            return;
          }
          final NavigatorState navigator = Navigator.of(context);
          final bool shouldPop = await _onWillPop(context);
          if (shouldPop) {
            navigator.pop();
          }
        },
        child: Scaffold(
          // backgroundColor: primaryColor,
          appBar: AppBar(
              centerTitle: false,
              title: Text(
                "Settings".tr().toString(),
                style: const TextStyle(color: Colors.white),
              ),
              automaticallyImplyLeading: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_outlined),
                  onPressed: () async {
                    showLogoutDialog(context);
                  },
                ),
              ],
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor),
          body: Container(
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
                color: Theme.of(context).primaryColor),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        "Account settings".tr().toString(),
                        style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Center(
                      child: Container(
                        alignment: Alignment.center,
                        width: myBanner.size.width.toDouble(),
                        height: myBanner.size.height.toDouble(),
                        child: adWidget,
                      ),
                    ),
                    ListTile(
                      title: Card(
                          child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: InkWell(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text("Phone Number".tr().toString()),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                ),
                                child: Text(
                                  widget.currentUser.phoneNumber!.isNotEmpty
                                      ? "${widget.currentUser.phoneNumber}"
                                      : "Add phone Number".tr().toString(),
                                  style: TextStyle(
                                      color: secondryColor,
                                      fontWeight: FontWeight.w400),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: primaryColor,
                                size: 15,
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                                context, RouteName.updatePhoneScreen,
                                arguments: widget.currentUser);
                            //      _ads.disable(_ad);
                          },
                        ),
                      )),
                      subtitle: Text(
                          "Verify a phone number to secure your account"
                              .tr()
                              .toString()),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        "Discovery settings".tr().toString(),
                        style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: UpdateAddressWidget(
                          currentUser: widget.currentUser,
                          hasSubscription: widget.isPurchased,
                          items: widget.items,
                        )),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 15,
                      ),
                      child: Text(
                        "Change your location to see members in other city"
                            .tr()
                            .toString(),
                        style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? secondryColor
                                : Colors.black54),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: ShowmeWidget(
                          currentUser: widget.currentUser,
                          changeValues: changeValues,
                        )),
                    Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: DistanceWidget(
                          changeValues: changeValues,
                          currentUser: widget.currentUser,
                          max: widget.isPurchased
                              ? paidR.toDouble()
                              : freeR.toDouble(),
                        )),
                    Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: AgeRangeWidget(
                          currentUser: widget.currentUser,
                          changeValues: changeValues,
                        )),
                    // remove notification should be used here already made notification widget

                    const LanguageWidget(),

                    // for streetview setting of users
                    ChangeNotifierProvider(
                        create: (context) {
                          return StreetViewProvider(widget.currentUser.id!);
                        },
                        child: StreetViewButtonWigdet(
                            currentUser: widget.currentUser)),
                    // for theme change and set button
                    const ChangeThemeButtonWidget(),
                    TextButtonWidget(
                      text: "Invite your friends",
                      onTap: () {
                        Share.share(
                            'check out my website https://deligence.com', //Replace with your dynamic link and msg for invite users
                            subject: 'Look what I made!'.tr().toString());
                      },
                      icon: Icons.share_outlined,
                    ),

                    TextButtonWidget(
                      text: "Logout",
                      onTap: () async {
                        showLogoutDialog(context);
                      },
                      icon: Icons.logout_outlined,
                    ),
                    Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: SizedBox(
                              height: 50,
                              width: 100,
                              child: Image.asset(
                                "asset/hookup4u-Logo-BP.png",
                                fit: BoxFit.contain,
                                color: themeProvider.isDarkMode
                                    ? Colors.white
                                    : primaryColor,
                              )),
                        )),
                    const DeleteAccountWidget(),
                    const SizedBox(
                      height: 80,
                    )
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
