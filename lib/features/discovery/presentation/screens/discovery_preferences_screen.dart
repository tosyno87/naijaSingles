import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_spacing.dart';
import '../../../../common/widgets/custom_snackbar.dart';
import '../../../../models/user_model.dart';
import '../../../home/bloc/searchuser_bloc.dart';
import '../../../home/ui/screens/user_filter/bloc/userfilter_bloc.dart';
import '../../../home/ui/widgets/age_range.dart';
import '../../../home/ui/widgets/distance_widget.dart';
import '../../../home/ui/widgets/looking_for_connection_card.dart';
import '../../../home/ui/widgets/show_me.dart';
import '../../../home/ui/widgets/update_address.dart';
import '../../../settings/widgets/settings_list/settings_switch_theme.dart';

/// Discovery-only preferences (distance, age, intent, etc.).
/// Account, theme, language, and logout live on the main Settings screen.
class DiscoveryPreferencesScreen extends StatefulWidget {
  const DiscoveryPreferencesScreen({
    required this.currentUser,
    required this.isPurchased,
    required this.items,
    super.key,
  });

  final UserModel currentUser;
  final bool isPurchased;
  final Map items;

  @override
  State<DiscoveryPreferencesScreen> createState() =>
      _DiscoveryPreferencesScreenState();
}

class _DiscoveryPreferencesScreenState
    extends State<DiscoveryPreferencesScreen> {
  final Map<String, dynamic> changeValues = <String, dynamic>{};

  late int freeR;
  late int paidR;

  late int _initialMaxDistance;
  late Map<dynamic, dynamic> _initialAgeRange;
  late String? _initialShowGender;
  late String? _initialLookingFor;

  bool _strictAge = false;
  bool _strictDistance = false;
  bool _strictIntent = false;
  bool _verifiedOnly = false;

  /// Bumps when filters reset so [LookingForConnectionCard] rebuilds its selection.
  int _lookingForCardKey = 0;

  bool _hasPendingEdits() {
    return changeValues.isNotEmpty ||
        _strictAge ||
        _strictDistance ||
        _strictIntent ||
        _verifiedOnly;
  }

  Future<bool> _onWillPop() async {
    final UserfilterState currentstate = context.read<UserfilterBloc>().state;
    if (currentstate is UpdatingUserFilter) {
      return false;
    }
    if (!_hasPendingEdits()) {
      return true;
    }
    final UserfilterBloc userFilterBloc = context.read<UserfilterBloc>();
    final SearchUserBloc searchUserBloc = context.read<SearchUserBloc>();
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<UserfilterBloc>.value(value: userFilterBloc),
          BlocProvider<SearchUserBloc>.value(value: searchUserBloc),
        ],
        child: AlertDialog(
          title: Text('Save Changes?'.tr()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Close'.tr(),
                style: const TextStyle(color: AppColors.primaryGreen),
              ),
            ),
            BlocBuilder<UserfilterBloc, UserfilterState>(
              builder: (BuildContext context, UserfilterState state) {
                if (state is UpdatingUserFilter) {
                  return const CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  );
                }
                return TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                    context.read<UserfilterBloc>().add(
                          ChangefilterRequest(details: _buildPayload()),
                        );
                    context.read<SearchUserBloc>().add(
                          LoadUserEvent(currentUser: widget.currentUser),
                        );
                  },
                  child: Text(
                    'Save'.tr(),
                    style: const TextStyle(color: AppColors.primaryGreen),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Map<String, dynamic> _buildPayload() {
    final Map<String, dynamic> payload =
        Map<String, dynamic>.from(changeValues);
    if (_strictAge) {
      payload['strict_age'] = true;
    }
    if (_strictDistance) {
      payload['strict_distance'] = true;
    }
    if (_strictIntent) {
      payload['strict_intent'] = true;
    }
    if (_verifiedOnly) {
      payload['show_verified_only'] = true;
    }
    return payload;
  }

  @override
  void initState() {
    super.initState();
    freeR = widget.items['free_radius'] != null
        ? (int.parse(widget.items['free_radius'].toString()) * 0.621371).round()
        : 248;
    paidR = widget.items['paid_radius'] != null
        ? (int.parse(widget.items['paid_radius'].toString()) * 0.621371).round()
        : 248;

    _initialMaxDistance = widget.currentUser.maxDistance ?? 10;
    _initialAgeRange = Map<dynamic, dynamic>.from(
      widget.currentUser.ageRange ??
          <dynamic, dynamic>{'min': '18', 'max': '50'},
    );
    _initialShowGender = widget.currentUser.showGender;
    _initialLookingFor = widget.currentUser.lookingFor;

    final int dist = widget.currentUser.maxDistance ?? 10;
    if (!widget.isPurchased && dist > freeR) {
      widget.currentUser.maxDistance = freeR;
    } else if (widget.isPurchased && dist >= paidR) {
      widget.currentUser.maxDistance = paidR;
    }
  }

  void _resetFilters() {
    setState(() {
      changeValues.clear();
      widget.currentUser.maxDistance = _initialMaxDistance;
      widget.currentUser.ageRange =
          Map<dynamic, dynamic>.from(_initialAgeRange);
      widget.currentUser.showGender = _initialShowGender;
      widget.currentUser.lookingFor = _initialLookingFor;
      _strictAge = false;
      _strictDistance = false;
      _strictIntent = false;
      _verifiedOnly = false;
      _lookingForCardKey++;
    });
  }

  String _ageSummary() {
    final Map? ar = widget.currentUser.ageRange;
    if (ar == null) return '18–50';
    return '${ar['min'] ?? '18'}–${ar['max'] ?? '50'}';
  }

  /// Whole miles for helper copy (avoids long floats like 31.06855…).
  int _distanceMilesRounded() {
    final int miles = widget.currentUser.maxDistance ?? 10;
    return (miles * 0.621371).round();
  }

  /// Slightly stronger than [AppColors.textSecondary] for long helper lines.
  TextStyle _helperLineStyle(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color color = Theme.of(context).brightness == Brightness.dark
        ? cs.onSurface.withValues(alpha: 0.82)
        : const Color(0xFF4A4A4A);
    return GoogleFonts.montserrat(
      fontSize: 12,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  void _applyFilters() {
    if (!_hasPendingEdits()) {
      CustomSnackbar.showSnackBarSimple(
        'No changes to save'.tr(),
        context,
      );
      return;
    }
    context.read<UserfilterBloc>().add(
          ChangefilterRequest(details: _buildPayload()),
        );
    context.read<SearchUserBloc>().add(
          LoadUserEvent(currentUser: widget.currentUser),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserfilterBloc, UserfilterState>(
      listener: (BuildContext context, UserfilterState state) {
        if (state is UserFilterUpdationFailed) {
          CustomSnackbar.showSnackBarSimple(
            'Filter not applied..'.tr(),
            context,
          );
        } else if (state is UserFilterUpdated) {
          CustomSnackbar.showSnackBarSimple(
            'Preferences updated'.tr(),
            context,
          );
          changeValues.clear();
          setState(() {
            _strictAge = false;
            _strictDistance = false;
            _strictIntent = false;
            _verifiedOnly = false;
          });
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) return;
          final bool allow = await _onWillPop();
          if (allow && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColors.backgroundColor,
            foregroundColor: AppColors.textPrimary,
            title: Text(
              'Discovery Filters'.tr(),
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [
              TextButton(
                onPressed: _resetFilters,
                child: Text(
                  'Reset filters'.tr(),
                  style: GoogleFonts.montserrat(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  children: [
                    Text(
                      'Discovery'.tr(),
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.78)
                            : const Color(0xFF505050),
                      ),
                    ),
                    const SizedBox(height: 6),
                    UpdateAddressWidget(
                      currentUser: widget.currentUser,
                      hasSubscription: widget.isPurchased,
                      items: widget.items,
                      compact: true,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Change your location to see members in other cities.'
                          .tr(),
                      style: _helperLineStyle(context),
                    ),
                    const SizedBox(height: 10),
                    ShowmeWidget(
                      currentUser: widget.currentUser,
                      changeValues: changeValues,
                      compact: true,
                      onEdited: () => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    LookingForConnectionCard(
                      key: ValueKey<int>(_lookingForCardKey),
                      currentUser: widget.currentUser,
                      changeValues: changeValues,
                      compact: true,
                    ),
                    const SizedBox(height: 8),
                    DistanceWidget(
                      currentUser: widget.currentUser,
                      changeValues: changeValues,
                      max: widget.isPurchased
                          ? paidR.toDouble()
                          : freeR.toDouble(),
                      compact: true,
                      onEdited: () => setState(() {}),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${'Showing people within'.tr()} '
                      '${_distanceMilesRounded()} '
                      '${'mi'.tr()}',
                      style: _helperLineStyle(context),
                    ),
                    const SizedBox(height: 8),
                    AgeRangeWidget(
                      currentUser: widget.currentUser,
                      changeValues: changeValues,
                      compact: true,
                      onEdited: () => setState(() {}),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${'Age range'.tr()}: ${_ageSummary()}',
                      style: _helperLineStyle(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Advanced Filters'.tr(),
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'When on, these act as dealbreakers.'.tr(),
                      style: _helperLineStyle(context),
                    ),
                    const SizedBox(height: 6),
                    settingsSwitchTheme(
                      context: context,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SwitchListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            title: Text('Strict age'.tr()),
                            subtitle: Text(
                              'Only show people strictly in this age band.'
                                  .tr(),
                              style: GoogleFonts.montserrat(fontSize: 12),
                            ),
                            value: _strictAge,
                            onChanged: (bool v) =>
                                setState(() => _strictAge = v),
                          ),
                          SwitchListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            title: Text('Strict distance'.tr()),
                            subtitle: Text(
                              'Hide people slightly outside your radius.'.tr(),
                              style: GoogleFonts.montserrat(fontSize: 12),
                            ),
                            value: _strictDistance,
                            onChanged: (bool v) =>
                                setState(() => _strictDistance = v),
                          ),
                          SwitchListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            title: Text('Strict intent'.tr()),
                            subtitle: Text(
                              'Match my "looking for" mode more strictly.'.tr(),
                              style: GoogleFonts.montserrat(fontSize: 12),
                            ),
                            value: _strictIntent,
                            onChanged: (bool v) =>
                                setState(() => _strictIntent = v),
                          ),
                          SwitchListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            title: Text('Show only verified profiles'.tr()),
                            subtitle: Text(
                              'When available, hide profiles not yet verified.'
                                  .tr(),
                              style: GoogleFonts.montserrat(fontSize: 12),
                            ),
                            value: _verifiedOnly,
                            onChanged: (bool v) =>
                                setState(() => _verifiedOnly = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 88),
                  ],
                ),
              ),
              Material(
                elevation: 12,
                shadowColor: Colors.black26,
                color: AppColors.backgroundColor,
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Apply filters'.tr(),
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
