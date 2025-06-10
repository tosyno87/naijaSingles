import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/home/ui/tab/tabbar.dart';
import '../constants/colors.dart';
import '../constants/constants.dart';
import '../providers/theme_provider.dart';

class LanguageWidget extends StatefulWidget {
  const LanguageWidget({Key? key}) : super(key: key);

  @override
  State<LanguageWidget> createState() => _LanguageWidgetState();
}

class _LanguageWidgetState extends State<LanguageWidget> {
  late String selectedLanguage; // Track the selected language

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Card(
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
                .map((language) => capitalizeFirstLetter(language))
                .toList();

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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(
                      "Change Language".tr().toString(),
                      style: TextStyle(
                        fontSize: 18,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          DropdownButton<String>(
                            iconDisabledColor: primaryColor,
                            iconEnabledColor: primaryColor,
                            iconSize: 24,
                            icon:
                                const Icon(Icons.keyboard_arrow_down_outlined),
                            value: selectedLanguage,
                            hint: const Text('Select a language'),
                            onChanged: (newValue) {
                              setState(() {
                                selectedLanguage = newValue!;
                              });
                              // Handle language change here
                              switch (newValue) {
                                case 'English':
                                  showChangeDialog(
                                    context,
                                    'English',
                                    () {
                                      EasyLocalization.of(context)!
                                          .setLocale(const Locale('en', 'US'));

                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const Tabbar(null, false)));
                                    },
                                  );
                                  break;
                                case 'Spanish':
                                  showChangeDialog(
                                    context,
                                    'Spanish',
                                    () {
                                      EasyLocalization.of(context)!
                                          .setLocale(const Locale('es', 'ES'));

                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const Tabbar(null, false)));
                                    },
                                  );
                                  break;
                                case 'German':
                                  showChangeDialog(
                                    context,
                                    'German',
                                    () {
                                      EasyLocalization.of(context)!
                                          .setLocale(const Locale('de', 'DE'));
                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const Tabbar(null, false)));
                                    },
                                  );
                                  break;
                                case 'Russian':
                                  showChangeDialog(
                                    context,
                                    'Russian',
                                    () {
                                      EasyLocalization.of(context)!
                                          .setLocale(const Locale('ru', 'RU'));

                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const Tabbar(null, false)));
                                    },
                                  );
                                  break;
                                case 'French':
                                  showChangeDialog(
                                    context,
                                    'French',
                                    () {
                                      EasyLocalization.of(context)!
                                          .setLocale(const Locale('fr', 'FR'));

                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const Tabbar(null, false)));
                                    },
                                  );
                                  break;
                                case 'Hindi':
                                  showChangeDialog(
                                    context,
                                    'Hindi',
                                    () {
                                      EasyLocalization.of(context)!
                                          .setLocale(const Locale('hi', 'IN'));

                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const Tabbar(null, false)));
                                    },
                                  );
                                  break;
                              }
                            },
                            items: languages.map((language) {
                              return DropdownMenuItem<String>(
                                value: language,
                                child: Text(
                                  language.tr().toString(),
                                  style: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? Colors.white70
                                          : primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } catch (e) {
              return Center(
                  child: Text(
                "Unable to load".tr().toString(),
                style: TextStyle(color: primaryColor),
              ));
            }
          },
        ),
      ),
    );
  }
}

void showChangeDialog(
    BuildContext context, String language, VoidCallback onTap) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Change Language".tr().toString()),
        content: Text(
            'Do you want to change the language to $language?'.tr().toString()),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'.tr().toString(),
                style: TextStyle(color: primaryColor)),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              'Yes'.tr().toString(),
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      );
    },
  );
}
