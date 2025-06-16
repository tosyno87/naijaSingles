import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/common/widgets/custom_button.dart';
import 'package:naijasingles/common/widgets/custom_snackbar.dart';

class UserNationality extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserNationality(this.userData, {super.key});

  @override
  _UserNationalityState createState() => _UserNationalityState();
}

class _UserNationalityState extends State<UserNationality> {
  String selectedCountry = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tribeController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool isDiaspora = false;
  
  // List of countries
  final List<String> countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Antigua and Barbuda', 'Argentina', 'Armenia', 'Australia', 'Austria', 'Azerbaijan',
    'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados', 'Belarus', 'Belgium', 'Belize', 'Benin', 'Bhutan', 'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei', 'Bulgaria', 'Burkina Faso', 'Burundi',
    'Cabo Verde', 'Cambodia', 'Cameroon', 'Canada', 'Central African Republic', 'Chad', 'Chile', 'China', 'Colombia', 'Comoros', 'Congo', 'Costa Rica', 'Croatia', 'Cuba', 'Cyprus', 'Czech Republic',
    'Denmark', 'Djibouti', 'Dominica', 'Dominican Republic',
    'Ecuador', 'Egypt', 'El Salvador', 'Equatorial Guinea', 'Eritrea', 'Estonia', 'Eswatini', 'Ethiopia',
    'Fiji', 'Finland', 'France',
    'Gabon', 'Gambia', 'Georgia', 'Germany', 'Ghana', 'Greece', 'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana',
    'Haiti', 'Honduras', 'Hungary',
    'Iceland', 'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy', 'Ivory Coast',
    'Jamaica', 'Japan', 'Jordan',
    'Kazakhstan', 'Kenya', 'Kiribati', 'Kuwait', 'Kyrgyzstan',
    'Laos', 'Latvia', 'Lebanon', 'Lesotho', 'Liberia', 'Libya', 'Liechtenstein', 'Lithuania', 'Luxembourg',
    'Madagascar', 'Malawi', 'Malaysia', 'Maldives', 'Mali', 'Malta', 'Marshall Islands', 'Mauritania', 'Mauritius', 'Mexico', 'Micronesia', 'Moldova', 'Monaco', 'Mongolia', 'Montenegro', 'Morocco', 'Mozambique', 'Myanmar',
    'Namibia', 'Nauru', 'Nepal', 'Netherlands', 'New Zealand', 'Nicaragua', 'Niger', 'Nigeria', 'North Korea', 'North Macedonia', 'Norway',
    'Oman',
    'Pakistan', 'Palau', 'Palestine', 'Panama', 'Papua New Guinea', 'Paraguay', 'Peru', 'Philippines', 'Poland', 'Portugal',
    'Qatar',
    'Romania', 'Russia', 'Rwanda',
    'Saint Kitts and Nevis', 'Saint Lucia', 'Saint Vincent and the Grenadines', 'Samoa', 'San Marino', 'Sao Tome and Principe', 'Saudi Arabia', 'Senegal', 'Serbia', 'Seychelles', 'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia', 'Solomon Islands', 'Somalia', 'South Africa', 'South Korea', 'South Sudan', 'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Sweden', 'Switzerland', 'Syria',
    'Taiwan', 'Tajikistan', 'Tanzania', 'Thailand', 'Timor-Leste', 'Togo', 'Tonga', 'Trinidad and Tobago', 'Tunisia', 'Turkey', 'Turkmenistan', 'Tuvalu',
    'Uganda', 'Ukraine', 'United Arab Emirates', 'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan',
    'Vanuatu', 'Vatican City', 'Venezuela', 'Vietnam',
    'Yemen',
    'Zambia', 'Zimbabwe'
  ];
  
  List<String> filteredCountries = [];
  
  @override
  void initState() {
    super.initState();
    filteredCountries = List.from(countries);
    
    // Auto focus the search field after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tribeController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCountries = List.from(countries);
      } else {
        filteredCountries = countries
            .where((country) => country.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
  
  void _selectCountry(String country) {
    setState(() {
      selectedCountry = country;
      _searchController.text = country;
      filteredCountries = [country];
      _searchFocusNode.unfocus();
    });
  }
  
  void _clearSelection() {
    setState(() {
      selectedCountry = '';
      _searchController.clear();
      filteredCountries = List.from(countries);
      _searchFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Progress indicator
              Container(
                height: 4,
                width: screenSize.width * 0.60, // 60% of screen width (fourth step)
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Title section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Where are you from?",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "We'll connect you with people from your country",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Search field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        cursorColor: const Color(0xFF27AE60),
                        decoration: InputDecoration(
                          hintText: "Search your country",
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey[400]),
                        ),
                        onChanged: _filterCountries,
                      ),
                    ),
                    if (selectedCountry.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                        onPressed: _clearSelection,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _tribeController,
                decoration: InputDecoration(
                  labelText: 'Tribe (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Are you in the diaspora?'),
                  Switch(
                    value: isDiaspora,
                    activeColor: const Color(0xFF27AE60),
                    onChanged: (val) {
                      setState(() {
                        isDiaspora = val;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),
              
              // Countries list
              Expanded(
                child: filteredCountries.isEmpty
                    ? Center(
                        child: Text(
                          "No countries found",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: filteredCountries.length,
                        itemBuilder: (context, index) {
                          final country = filteredCountries[index];
                          final isSelected = country == selectedCountry;
                          
                          return InkWell(
                            onTap: () => _selectCountry(country),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(color: const Color(0xFF27AE60))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      country,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? const Color(0xFF27AE60) : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF27AE60),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              
              // Continue button
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 10.0),
                child: AnimatedOpacity(
                  opacity: selectedCountry.isNotEmpty ? 1.0 : 0.7,
                  duration: const Duration(milliseconds: 200),
                  child: CustomButton(
                    active: selectedCountry.isNotEmpty,
                    color: const Color(0xFF27AE60),
                    onTap: () {
                      if (selectedCountry.isNotEmpty) {
                        widget.userData.addAll({
                          'nationality': selectedCountry,
                          'tribe': _tribeController.text.trim(),
                          'isDiaspora': isDiaspora,
                        });
                        log(widget.userData.toString());
                        Navigator.pushNamed(context, RouteName.sexualorientationScreen,
                            arguments: widget.userData);
                      } else {
                        CustomSnackbar.showSnackBarSimple(
                            "Please select your country", context);
                      }
                    },
                    text: 'CONTINUE',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
