import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GenderSign extends StatelessWidget {
  final String gender;
  final Color iconColor;
  const GenderSign({super.key, required this.gender, required this.iconColor});
  Widget _userGenderIcon({required String gender, required Color iconColor}) {
    if (gender == 'men') {
      return FaIcon(
        // Icons.male,
        FontAwesomeIcons.mars,
        color: iconColor,
        size: 20,
      );
    } else if (gender == 'women') {
      return FaIcon(
        // Icons.female,
        FontAwesomeIcons.venus,
        color: iconColor,
        size: 20,
      );
    } else if (gender == 'other') {
      // return Icon(
      //   Icons.transgender,
      //   color: iconColor,
      // );

      return FaIcon(
        // Icons.transgender,
        FontAwesomeIcons.transgender,
        color: iconColor,
        size: 20,
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _userGenderIcon(gender: gender, iconColor: iconColor);
  }
}
