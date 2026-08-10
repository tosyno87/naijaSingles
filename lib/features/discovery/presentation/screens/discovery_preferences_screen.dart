import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/bloc/user/user_bloc.dart';
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

  /// Brief in-button confirmation after a successful apply (no snackbar).
  bool _showAppliedConfirm = false;
  Timer? _appliedConfirmTimer;

  /// True while a Reset filters write is in flight (distinct from Apply).
  bool _pendingWriteIsReset = false;

  /// Bumps when filters reset so [LookingForConnectionCard] rebuilds its selection.
  int _lookingForCardKey = 0;

  bool _hasPendingEdits() {
    return changeValues.isNotEmpty ||
        _strictAge ||
        _strictDistance ||
        _strictIntent ||
        _verifiedOnly;
  }

  /// Reverts unsaved edits on the shared [UserModel] so callers that reuse
  /// this instance after the route closes don't see discarded values.
  void _restoreLastSavedValues() {
    changeValues.clear();
    widget.currentUser.maxDistance = _initialMaxDistance;
    widget.currentUser.ageRange = Map<dynamic, dynamic>.from(_initialAgeRange);
    widget.currentUser.showGender = _initialShowGender;
    widget.currentUser.lookingFor = _initialLookingFor;
  }

  /// After a successful save, the current values become the new baseline for
  /// discard/reset.
  void _snapshotLastSavedValues() {
    _initialMaxDistance = widget.currentUser.maxDistance ?? 10;
    _initialAgeRange = Map<dynamic, dynamic>.from(
      widget.currentUser.ageRange ??
          <dynamic, dynamic>{'min': '18', 'max': '50'},
    );
    _initialShowGender = widget.currentUser.showGender;
    _initialLookingFor = widget.currentUser.lookingFor;
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
              onPressed: () {
                _restoreLastSavedValues();
                Navigator.of(dialogContext).pop(true);
              },
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
                    final UserModel seeker =
                        context.read<UserBloc>().currentUser ??
                            widget.currentUser;
                    context.read<SearchUserBloc>().add(
                          LoadUserEvent(currentUser: seeker),
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

  @override
  void dispose() {
    _appliedConfirmTimer?.cancel();
    super.dispose();
  }

  /// Restores app-default filters and saves them, so "Reset filters" is a
  /// real reset rather than a local revert to the values from screen open.
  void _resetFilters() {
    if (context.read<UserfilterBloc>().state is UpdatingUserFilter) {
      return;
    }
    final int defaultDistance = widget.isPurchased ? paidR : freeR;
    const Map<String, String> defaultAgeRange = <String, String>{
      'min': '18',
      'max': '50',
    };
    setState(() {
      changeValues.clear();
      widget.currentUser.maxDistance = defaultDistance;
      widget.currentUser.ageRange =
          Map<dynamic, dynamic>.from(defaultAgeRange);
      widget.currentUser.showGender = 'everyone';
      widget.currentUser.lookingFor = 'Dating';
      widget.currentUser.strictDistance = false;
      _strictAge = false;
      _strictDistance = false;
      _strictIntent = false;
      _verifiedOnly = false;
      _lookingForCardKey++;
      _pendingWriteIsReset = true;
    });
    // Strict flags are written as false explicitly to clear any previously
    // saved dealbreakers on the user doc.
    context.read<UserfilterBloc>().add(
          ChangefilterRequest(
            details: <String, dynamic>{
              'showGender': 'everyone',
              'lookingFor': 'Dating',
              'maximum_distance': defaultDistance,
              'age_range': defaultAgeRange,
              'strict_age': false,
              'strict_distance': false,
              'strict_intent': false,
              'show_verified_only': false,
            },
          ),
        );
    context.read<SearchUserBloc>().add(
          LoadUserEvent(currentUser: widget.currentUser),
        );
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
      // Silent no-op (Tinder/Hinge-style) — no dismissible snackbar.
      return;
    }
    if (context.read<UserfilterBloc>().state is UpdatingUserFilter) {
      return;
    }
    _pendingWriteIsReset = false;
    context.read<UserfilterBloc>().add(
          ChangefilterRequest(details: _buildPayload()),
        );
    // Reload from the edited screen model (age/distance/gender live here).
    // UserBloc can lag behind when this route was opened with a fresh doc.
    final UserModel seeker = widget.currentUser;
    seeker.strictDistance = _strictDistance;

    // Prefer freshest coordinates from UserBloc when location was updated
    // this session (lat/lng are final on UserModel).
    final UserModel? blocUser = context.read<UserBloc>().currentUser;
    final UserModel reloadSeeker;
    if (blocUser != null &&
        blocUser.id == seeker.id &&
        blocUser.latitude != null &&
        blocUser.longitude != null &&
        (blocUser.latitude != seeker.latitude ||
            blocUser.longitude != seeker.longitude)) {
      reloadSeeker = UserModel(
        id: seeker.id,
        name: seeker.name ?? blocUser.name,
        age: seeker.age ?? blocUser.age,
        address: seeker.address ?? blocUser.address,
        latitude: blocUser.latitude,
        longitude: blocUser.longitude,
        showGender: seeker.showGender,
        ageRange: seeker.ageRange,
        maxDistance: seeker.maxDistance,
        lookingFor: seeker.lookingFor,
        userGender: seeker.userGender ?? blocUser.userGender,
        imageUrl: seeker.imageUrl ?? blocUser.imageUrl,
        editInfo: seeker.editInfo ?? blocUser.editInfo,
        strictDistance: seeker.strictDistance,
        isPremium: seeker.isPremium ?? blocUser.isPremium,
      );
    } else {
      reloadSeeker = seeker;
    }

    context.read<SearchUserBloc>().add(
          LoadUserEvent(currentUser: reloadSeeker),
        );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color pageBackground =
        isDark ? scheme.surface : AppColors.backgroundColor;
    final Color onPage = scheme.onSurface;
    final ThemeData scopedTheme = theme.copyWith(
      cardTheme: theme.cardTheme.copyWith(
        color: isDark ? scheme.surfaceContainerHighest : AppColors.cardColor,
        surfaceTintColor: Colors.transparent,
      ),
    );

    return Theme(
      data: scopedTheme,
      child: BlocListener<UserfilterBloc, UserfilterState>(
        listener: (BuildContext context, UserfilterState state) {
          if (state is UserFilterUpdationFailed) {
            CustomSnackbar.showSnackBarSimple(
              'Filter not applied..'.tr(),
              context,
            );
            // Reset mutates the shared model before the write finishes. If
            // persistence fails, roll back so UI/discovery match Firestore.
            if (_pendingWriteIsReset) {
              setState(() {
                _restoreLastSavedValues();
                _lookingForCardKey++;
                _pendingWriteIsReset = false;
              });
              context.read<SearchUserBloc>().add(
                    LoadUserEvent(currentUser: widget.currentUser),
                  );
            }
          } else if (state is UserFilterUpdated) {
            unawaited(HapticFeedback.lightImpact());
            changeValues.clear();
            _snapshotLastSavedValues();
            _pendingWriteIsReset = false;
            _appliedConfirmTimer?.cancel();
            setState(() {
              _strictAge = false;
              _strictDistance = false;
              _strictIntent = false;
              _verifiedOnly = false;
              _showAppliedConfirm = true;
            });
            _appliedConfirmTimer =
                Timer(const Duration(milliseconds: 1600), () {
              if (mounted) {
                setState(() => _showAppliedConfirm = false);
              }
            });
          }
        },
        child: BlocBuilder<UserfilterBloc, UserfilterState>(
          builder: (BuildContext context, UserfilterState filterState) {
            final bool filtersBusy = filterState is UpdatingUserFilter;
            return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) return;
            final bool allow = await _onWillPop();
            if (allow && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: pageBackground,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: pageBackground,
              foregroundColor: onPage,
              title: Text(
                'Discovery Filters'.tr(),
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: onPage,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: filtersBusy ? null : _resetFilters,
                  child: Text(
                    'Reset filters'.tr(),
                    style: GoogleFonts.montserrat(
                      color: isDark
                          ? AppColors.primaryGreenLight
                          : AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: AbsorbPointer(
                    absorbing: filtersBusy,
                    child: Opacity(
                      opacity: filtersBusy ? 0.6 : 1,
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
                          color: onPage.withValues(alpha: isDark ? 0.78 : 0.72),
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
                          color: onPage.withValues(alpha: isDark ? 0.78 : 0.72),
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
                                'Hide people slightly outside your radius.'
                                    .tr(),
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
                                'Match my "looking for" mode more strictly.'
                                    .tr(),
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
                  ),
                ),
                Material(
                  elevation: 12,
                  shadowColor: Colors.black26,
                  color: pageBackground,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_showAppliedConfirm || filtersBusy)
                            ? null
                            : _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showAppliedConfirm
                              ? AppColors.primaryGreen.withValues(alpha: 0.85)
                              : AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primaryGreen.withValues(alpha: 0.85),
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _showAppliedConfirm
                              ? Row(
                                  key: const ValueKey<String>('applied'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Applied'.tr(),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  key: const ValueKey<String>('apply'),
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
                ),
              ],
            ),
          ),
        );
          },
        ),
      ),
    );
  }
}
