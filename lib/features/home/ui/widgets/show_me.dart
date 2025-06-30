import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../models/user_model.dart';

class ShowmeWidget extends StatefulWidget {
  final UserModel currentUser;
  final Map<String, dynamic> changeValues;
  const ShowmeWidget({
    super.key,
    required this.currentUser,
    required this.changeValues,
  });

  @override
  State<ShowmeWidget> createState() => _ShowmeWidgetState();
}

class _ShowmeWidgetState extends State<ShowmeWidget> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Show me".tr().toString(),
              style: TextStyle(
                  fontSize: 18,
                  color: themeProvider.isDarkMode ? Colors.white : primaryColor,
                  fontWeight: FontWeight.w500),
            ),
            ListTile(
              title: DropdownButton(
                iconEnabledColor: primaryColor,
                iconDisabledColor: AppColors.secondaryColor,
                iconSize: 24,
                icon: const Icon(Icons.keyboard_arrow_down_outlined),
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: "men",
                    child: Text(
                      "Men".tr().toString(),
                      style: TextStyle(
                        color: AppColors.secondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                      value: "women",
                      child: Text("Women".tr().toString(),
                          style: TextStyle(
                            color: AppColors.secondaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ))),
                  DropdownMenuItem(
                      value: "everyone",
                      child: Text("Everyone".tr().toString(),
                          style: TextStyle(
                            color: AppColors.secondaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ))),
                ],
                onChanged: (val) {
                  widget.changeValues.addAll({
                    'showGender': val,
                  });
                  setState(() {
                    widget.currentUser.showGender = val;
                  });
                },
                value: widget.currentUser.showGender,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
