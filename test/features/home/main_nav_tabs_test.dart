import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/home/main_nav_tabs.dart';

void main() {
  group('kMainNavTabs', () {
    test('Discover is first and order is Discover, Connect, Messages, Profile',
        () {
      expect(kMainNavTabs.map((MainNavTab t) => t.label).toList(), <String>[
        'Discover',
        'Connect',
        'Messages',
        'Profile',
      ]);
      expect(kMainNavTabs.first.id, MainNavTabId.discover);
      expect(mainNavIndexFor(MainNavTabId.discover), 0);
      expect(mainNavIndexFor(MainNavTabId.connect), 1);
    });
  });
}
