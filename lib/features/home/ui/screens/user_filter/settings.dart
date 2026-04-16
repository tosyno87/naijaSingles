import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../common/bloc/streetview/streetview_bloc.dart';
import '../../../../../common/constants/app_colors.dart';
import '../../../../../common/routes/route_name.dart';
import '../../../../../common/widgets/change_language_widget.dart';
import '../../../../../common/widgets/custom_snackbar.dart';
import '../../../../../common/widgets/text_button.dart';
import '../../../../../common/widgets/theme_change.dart';
import '../../../../../models/user_model.dart';
import '../../../../discovery/data/services/discovery_service.dart';
import '../../../../match/bloc/match_user_bloc.dart';
import '../../../bloc/searchuser_bloc.dart';
import '../../widgets/delete_account.dart';
import '../../widgets/logout_dialog.dart';
import '../../widgets/street_view_enable.dart';
import 'bloc/userfilter_bloc.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({
    required this.currentUser,
    required this.isPurchased,
    required this.items,
    super.key,
  });
  final UserModel currentUser;
  final bool isPurchased;
  final Map items;

  @override
  SettingPageState createState() => SettingPageState();
}

class SettingPageState extends State<SettingPage> {
  Map<String, dynamic> changeValues = {};

  Future<bool> _onWillPop(BuildContext context) async {
    final currentstate = BlocProvider.of<UserfilterBloc>(context).state;
    if (currentstate == UpdatingUserFilter()) {
      log('coming under updating state');
      return false;
    }

    if (changeValues.isNotEmpty) {
      return (await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Save Changes?'.tr().toString()),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    log('change---$changeValues');
                  },
                  child: Text(
                    'Close'.tr().toString(),
                    style: const TextStyle(color: AppColors.primaryGreen),
                  ),
                ),
                BlocBuilder<UserfilterBloc, UserfilterState>(
                  builder: (context, state) {
                    if (state is UpdatingUserFilter) {
                      return const CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      );
                    }
                    return TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);

                        log('not empty changesvalue');
                        BlocProvider.of<UserfilterBloc>(context)
                            .add(ChangefilterRequest(details: changeValues));
                        context.read<SearchUserBloc>().add(
                              LoadUserEvent(currentUser: widget.currentUser),
                            );
                      },
                      child: Text(
                        'Save'.tr().toString(),
                        style: const TextStyle(color: AppColors.primaryGreen),
                      ),
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
    freeR = widget.items['free_radius'] != null
        ? (int.parse(widget.items['free_radius']) * 0.621371)
            .round() // Convert km to miles
        : 248; // 400km = 248 miles
    paidR = widget.items['paid_radius'] != null
        ? (int.parse(widget.items['paid_radius']) * 0.621371)
            .round() // Convert km to miles
        : 248; // 400km = 248 miles
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log(widget.currentUser.toString());
    log('my phone number is ${widget.currentUser.phoneNumber.toString()}');
    return BlocListener<UserfilterBloc, UserfilterState>(
      listener: (context, state) {
        if (state is UserFilterUpdationFailed) {
          CustomSnackbar.showSnackBarSimple(
            'Filter not applied..'.tr().toString(),
            context,
          );
        } else if (state is UserFilterUpdated) {
          CustomSnackbar.showSnackBarSimple(
            'Changes saved.'.tr().toString(),
            context,
          );
          log('filter succesfully applied ....'.tr().toString());

          changeValues.clear();
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
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
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).scaffoldBackgroundColor
              : AppColors.backgroundColor,
          appBar: AppBar(
            centerTitle: false,
            title: Text(
              'Settings'.tr().toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            elevation: 0,
            scrolledUnderElevation: 0.5,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).scaffoldBackgroundColor
                : AppColors.backgroundColor,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          body: ColoredBox(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).scaffoldBackgroundColor
                : AppColors.backgroundColor,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 12, 15, 6),
                    child: Text(
                      'Account Settings'.tr().toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 4,
                      ),
                      title: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: InkWell(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text('Phone Number'.tr().toString()),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 20,
                                  ),
                                  child: Text(
                                    widget.currentUser.phoneNumber!.isNotEmpty
                                        ? '${widget.currentUser.phoneNumber}'
                                        : 'Add phone number'.tr().toString(),
                                    style: const TextStyle(
                                      color: AppColors.secondaryColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: AppColors.primaryGreen,
                                  size: 15,
                                ),
                              ],
                            ),
                            onTap: () {
                              unawaited(
                                Navigator.pushNamed(
                                  context,
                                  RouteName.updatePhoneScreen,
                                  arguments: widget.currentUser,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      subtitle: Text(
                        'Verify a phone number to secure your account'
                            .tr()
                            .toString(),
                      ),
                    ),
                    const LanguageWidget(),
                    BlocProvider<MatchUserBloc>(
                      create: (_) => MatchUserBloc(
                        getMatches: DiscoveryService.getMatches,
                      ),
                      child: BlocProvider<StreetViewBloc>(
                        create: (BuildContext context) =>
                            StreetViewBloc(widget.currentUser.id!),
                        child: StreetViewButtonWigdet(
                          currentUser: widget.currentUser,
                        ),
                      ),
                    ),
                    // for theme change and set labelLarge
                    const ChangeThemeButtonWidget(),
                    TextButtonWidget(
                      text: 'Invite your friends',
                      onTap: () async {
                        await SharePlus.instance.share(
                          ShareParams(
                            text:
                                'check out my website https://deligence.com', //Replace with your dynamic link and msg for invite users
                          ),
                        );
                      },
                      icon: Icons.share_outlined,
                    ),

                    TextButtonWidget(
                      text: 'Logout',
                      onTap: () async {
                        showLogoutDialog(context);
                      },
                      icon: Icons.logout_outlined,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: SizedBox(
                          height: 50,
                          width: 100,
                          child: Image.asset(
                            'assets/images/afropeep_logo_transparent.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const DeleteAccountWidget(),
                    const SizedBox(
                      height: 80,
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
