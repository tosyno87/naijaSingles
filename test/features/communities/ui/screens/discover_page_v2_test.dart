import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/home/main_nav_tabs.dart';

// DiscoverPageV2 still requires Firebase. Tab order and isolated Houston
// widgets are covered in main_nav_tabs_test and houston_home_widgets_test.

void main() {
  test('Discover remains the first main-nav tab', () {
    expect(kMainNavTabs.first.label, 'Discover');
    expect(kMainNavTabs.first.id, MainNavTabId.discover);
  });
}
