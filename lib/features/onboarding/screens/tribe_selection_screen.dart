import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/onboarding_bloc.dart';
import '../onboarding_theme.dart';

class TribeSelectionScreen extends StatefulWidget {
  const TribeSelectionScreen({super.key});

  @override
  State<TribeSelectionScreen> createState() => _TribeSelectionScreenState();
}

class _TribeSelectionScreenState extends State<TribeSelectionScreen> {
  String? _selectedNationality;
  String? _selectedTribe;
  final TextEditingController _otherTribeController = TextEditingController();
  final TextEditingController _nationalitySearchController =
      TextEditingController();
  bool _showOtherField = false;
  String _nationalityFilter = '';

  final List<String> _nationalities = [
    'Nigeria',
    'Ghana',
    'Kenya',
    'South Africa',
    'Ethiopia',
    'Tanzania',
    'Uganda',
    'Zimbabwe',
    'Senegal',
    'Cameroon',
    'Ivory Coast',
    'Morocco',
    'Egypt',
    'Tunisia',
    'Algeria',
    'Sudan',
    'Mozambique',
    'Angola',
    'Madagascar',
    'Mali',
    'Burkina Faso',
    'Niger',
    'Malawi',
    'Zambia',
    'Somalia',
    'Guinea',
    'Benin',
    'Burundi',
    'Togo',
    'Eritrea',
    'Sierra Leone',
    'Libya',
    'Rwanda',
    'Chad',
    'Central African Republic',
    'Mauritania',
    'Namibia',
    'Botswana',
    'Gabon',
    'Gambia',
    'Lesotho',
    'Guinea-Bissau',
    'Equatorial Guinea',
    'Mauritius',
    'Eswatini',
    'Djibouti',
    'Comoros',
    'Cabo Verde',
    'São Tomé and Príncipe',
    'Seychelles',
    'African Diaspora',
    'Other',
  ];

  final List<String> _mainTribes = [
    'Yoruba',
    'Igbo',
    'Hausa',
    'Fulani',
    'Ijaw',
    'Kanuri',
    'Ibibio',
    'Tiv',
    'Edo',
    'Urhobo',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<OnboardingBloc>().state.data;

      if (data != null) {
        if (data.nationality != null && data.nationality!.isNotEmpty) {
          setState(() => _selectedNationality = data.nationality);
        }

        if (data.tribe.isNotEmpty) {
          if (_mainTribes.contains(data.tribe)) {
            setState(() => _selectedTribe = data.tribe);
          } else {
            setState(() {
              _selectedTribe = 'Other';
              _otherTribeController.text = data.tribe;
              _showOtherField = true;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _otherTribeController.dispose();
    _nationalitySearchController.dispose();
    super.dispose();
  }

  void _selectNationality(String? nationality) {
    setState(() => _selectedNationality = nationality);
    if (nationality != null) {
      context.read<OnboardingBloc>().add(
            OnboardingNationalityUpdated(nationality),
          );
    }
  }

  void _selectTribe(String? tribe) {
    setState(() {
      _selectedTribe = tribe;
      _showOtherField = tribe == 'Other';

      if (tribe != 'Other' && tribe != null) {
        context.read<OnboardingBloc>().add(OnboardingTribeUpdated(tribe));
      }
    });
  }

  void _showNationalitySearch() {
    _nationalitySearchController.text = '';
    _nationalityFilter = '';

    unawaited(showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OnboardingTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered = _nationalityFilter.isEmpty
              ? _nationalities
              : _nationalities
                  .where((n) => n
                      .toLowerCase()
                      .contains(_nationalityFilter.toLowerCase()))
                  .toList();

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder: (_, scrollController) => SafeArea(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OnboardingTheme.horizontalPadding,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _nationalitySearchController,
                      autofocus: true,
                      style: OnboardingTheme.fieldTextStyle,
                      decoration: OnboardingTheme.fieldDecoration(
                        hint: 'Search nationality...',
                        prefix: const Icon(
                          Icons.search,
                          color: OnboardingTheme.primaryGreen,
                        ),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          _nationalityFilter = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final nation = filtered[i];
                        final isSelected = nation == _selectedNationality;
                        return ListTile(
                          title: Text(
                            nation,
                            style: OnboardingTheme.fieldTextStyle.copyWith(
                              color: isSelected
                                  ? OnboardingTheme.primaryGreen
                                  : OnboardingTheme.fieldTextColor,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: OnboardingTheme.primaryGreen,
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(ctx, nation);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((selected) {
      if (selected != null) {
        _selectNationality(selected);
      }
    }));
  }

  @override
  Widget build(BuildContext context) => OnboardingTheme.constrainedContent(
        child: SingleChildScrollView(
          padding: OnboardingTheme.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This helps us connect you with people from similar backgrounds',
                style: OnboardingTheme.subtitleStyle,
              ),

              const SizedBox(height: OnboardingTheme.subtitleToField),

              Text('Nationality *', style: OnboardingTheme.sectionLabelStyle),
              const SizedBox(height: OnboardingTheme.labelToField),

              // Searchable nationality selector
              GestureDetector(
                onTap: _showNationalitySearch,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: OnboardingTheme.fieldHeight,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: OnboardingTheme.fieldContentPadding,
                  ),
                  decoration: OnboardingTheme.dropdownDecoration(
                    hasFocus: _selectedNationality != null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedNationality ?? 'Search and select nationality',
                          style: _selectedNationality != null
                              ? OnboardingTheme.fieldTextStyle
                              : GoogleFonts.montserrat(
                                  color: OnboardingTheme.subtitleColor,
                                  fontSize: 16,
                                ),
                        ),
                      ),
                      const Icon(
                        Icons.search,
                        color: OnboardingTheme.primaryGreen,
                        size: OnboardingTheme.fieldIconSize,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: OnboardingTheme.fieldToSection),

              Row(
                children: [
                  Text(
                    'Tribe or Ethnic Group',
                    style: OnboardingTheme.sectionLabelStyle,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(Optional)',
                    style: OnboardingTheme.helperStyle.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OnboardingTheme.labelToField),
              Container(
                constraints: const BoxConstraints(
                  minHeight: OnboardingTheme.fieldHeight,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: OnboardingTheme.fieldContentPadding,
                ),
                decoration: OnboardingTheme.dropdownDecoration(
                  hasFocus: _selectedTribe != null,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTribe,
                    hint: Text(
                      'Select your tribe (optional)',
                      style: GoogleFonts.montserrat(
                        color: OnboardingTheme.subtitleColor,
                        fontSize: 16,
                      ),
                    ),
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: OnboardingTheme.primaryGreen,
                      size: OnboardingTheme.fieldIconSize,
                    ),
                    dropdownColor: OnboardingTheme.fieldFill,
                    borderRadius: BorderRadius.circular(
                      OnboardingTheme.fieldRadius,
                    ),
                    style: OnboardingTheme.fieldTextStyle,
                    items: _mainTribes
                        .map(
                          (String tribe) => DropdownMenuItem<String>(
                            value: tribe,
                            child: Text(tribe),
                          ),
                        )
                        .toList(),
                    onChanged: _selectTribe,
                  ),
                ),
              ),

              if (_showOtherField) ...[
                const SizedBox(height: OnboardingTheme.fieldToSection),
                Text(
                  'Please specify your tribe',
                  style: OnboardingTheme.sectionLabelStyle,
                ),
                const SizedBox(height: OnboardingTheme.labelToField),
                TextField(
                  controller: _otherTribeController,
                  style: OnboardingTheme.fieldTextStyle,
                  decoration: OnboardingTheme.fieldDecoration(
                    hint: 'Enter your tribe',
                  ),
                  onChanged: (value) {
                    if (value.trim().isNotEmpty) {
                      context.read<OnboardingBloc>().add(
                            OnboardingTribeUpdated(value.trim()),
                          );
                    }
                  },
                ),
              ],

              const SizedBox(height: OnboardingTheme.fieldToBottom),
            ],
          ),
        ),
      );
}
