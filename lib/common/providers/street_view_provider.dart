import 'package:flutter/material.dart';

import '../data/streetview_prefrences.dart';

class StreetViewProvider extends ChangeNotifier {
  final String userId;
  String streetMode = 'None';
  final StretViewPreferences _preferences;

  StreetViewProvider(this.userId)
      : _preferences = StretViewPreferences(userId) {
    // Pass userId to the StretViewPreferences constructor
    initializeView();
  }

  Future<void> initializeView() async {
    final savedView = await _preferences.getView();
    if (savedView != null) {
      streetMode = savedView;
    }
    notifyListeners();
  }

  void toggleView(String value, List<String> userIds) {
    final value1 = value;
    switch (value1) {
      case 'None':
        streetMode = 'None';
        break;
      case 'Everyone':
        streetMode = 'Everyone';
        break;
      case 'My Matches':
        streetMode = 'My Matches';
        break;
      case 'Only':
        streetMode = 'Only';
        break;
      default:
        streetMode = 'None';
    }

    _preferences.setView(value, userIds);

    notifyListeners();
  }
}
