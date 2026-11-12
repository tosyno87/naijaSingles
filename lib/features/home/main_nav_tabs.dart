import 'package:flutter/material.dart';

/// Bottom-nav order for [MainNavigationScreen].
/// Discover is first so the post-onboarding surface is community/events, not Connect.
enum MainNavTabId {
  discover,
  connect,
  messages,
  profile,
}

class MainNavTab {
  const MainNavTab({
    required this.id,
    required this.label,
  });

  final MainNavTabId id;
  final String label;
}

const List<MainNavTab> kMainNavTabs = <MainNavTab>[
  MainNavTab(id: MainNavTabId.discover, label: 'Discover'),
  MainNavTab(id: MainNavTabId.connect, label: 'Connect'),
  MainNavTab(id: MainNavTabId.messages, label: 'Messages'),
  MainNavTab(id: MainNavTabId.profile, label: 'Profile'),
];

int mainNavIndexFor(MainNavTabId id) =>
    kMainNavTabs.indexWhere((MainNavTab tab) => tab.id == id);

/// Lets Discover (and other tabs) switch the shell tab without stacking a
/// second [ExploreScreen].
class MainNavSwitcher extends InheritedWidget {
  const MainNavSwitcher({
    required this.switchToTab,
    required super.child,
    super.key,
  });

  final void Function(int index) switchToTab;

  static MainNavSwitcher? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainNavSwitcher>();

  @override
  bool updateShouldNotify(MainNavSwitcher oldWidget) =>
      switchToTab != oldWidget.switchToTab;
}
