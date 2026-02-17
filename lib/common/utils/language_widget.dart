import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/language/language_bloc.dart';
import '../bloc/theme/theme_bloc.dart';
import '../constants/app_colors.dart';
import '../constants/constants.dart';
import '../routes/route_name.dart';

class LanguageSelectionDropdown extends StatefulWidget {
  const LanguageSelectionDropdown({super.key});

  @override
  State<LanguageSelectionDropdown> createState() =>
      _LanguageSelectionDropdownState();
}

class _LanguageSelectionDropdownState extends State<LanguageSelectionDropdown> {
  late String selectedLanguage;
  // Track the selected language
  @override
  void initState() {
    super.initState();

    selectedLanguage = ''; // Initialize selectedLanguage
  }

  String capitalizeFirstLetter(String input) {
    if (input.isEmpty) {
      return input; // Return empty string if input is empty
    }
    return input[0].toUpperCase() + input.substring(1);
  }

  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      case 'ru':
        return 'Russian';
      case 'hi':
        return 'Hindi';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(
            color: AppColors.secondaryColor
                .withValues(alpha: (0.2 * 255).toDouble()),
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: firebaseFireStoreInstance
              .collection('Language')
              .doc('present_languages')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Text('Language not found'),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data == null) {
              return const Center(
                child: Text('Language not found'),
              );
            }

            final List<String> languages = data.keys
                .where((key) => data[key] == true)
                .map(capitalizeFirstLetter)
                .toList();
            log('languages is $languages');

            // Set initial selectedLanguage to the first language in the list
            if (selectedLanguage.isEmpty && languages.isNotEmpty) {
              final res = EasyLocalization.of(context)!.locale.languageCode;
              // check if value is in languages list or not
              if (languages.contains(getLanguageName(res))) {
                selectedLanguage = getLanguageName(res);
              } else {
                selectedLanguage = languages.first;
              }
            }

            try {
              return Padding(
                padding: const EdgeInsets.only(
                  left: 15,
                  right: 15,
                  top: 5,
                  bottom: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Change Language'.tr().toString(),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode
                            ? Colors.white
                            : Colors.pink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    DropdownButton<String>(
                      iconDisabledColor: AppColors.primaryGreen,
                      iconEnabledColor: AppColors.primaryGreen,
                      icon: const Icon(Icons.keyboard_arrow_down_outlined),
                      value: selectedLanguage,
                      hint: const Text('Select a language'),
                      onChanged: (newValue) {
                        setState(() {
                          selectedLanguage = newValue!;
                        });
                        // Handle language change here
                        switch (newValue) {
                          case 'English':
                            _refreshPage(
                              context,
                              cCode: 'US',
                              lCode: 'en',
                            );
                            break;
                          case 'Spanish':
                            _refreshPage(
                              context,
                              cCode: 'ES',
                              lCode: 'es',
                            );
                            break;
                          case 'German':
                            _refreshPage(
                              context,
                              cCode: 'DE',
                              lCode: 'de',
                            );
                            break;
                          case 'Russian':
                            _refreshPage(
                              context,
                              cCode: 'RU',
                              lCode: 'ru',
                            );
                            break;
                          case 'French':
                            _refreshPage(
                              context,
                              cCode: 'FR',
                              lCode: 'fr',
                            );
                            break;
                          case 'Hindi':
                            _refreshPage(
                              context,
                              cCode: 'IN',
                              lCode: 'hi',
                            );
                            break;
                        }
                      },
                      items: languages
                          .map(
                            (language) => DropdownMenuItem<String>(
                              value: language,
                              child: Text(
                                language.tr().toString(),
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.pink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              );
            } catch (e) {
              return Center(
                child: Text(
                  'Unable to load'.tr().toString(),
                  style: const TextStyle(color: AppColors.primaryGreen),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

void _refreshPage(BuildContext context, {required String lCode, required String cCode}) {
  context.read<LanguageBloc>().add(
        LanguageLocaleChanged(Locale(lCode, cCode), context),
      );
  Navigator.pushReplacementNamed(context, RouteName.welcomeScreen);
}
