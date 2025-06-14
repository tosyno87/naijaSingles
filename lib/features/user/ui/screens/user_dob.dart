// ignore_for_file: sort_child_properties_last

import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/widgets/custom_button.dart';

class UserDOB extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserDOB(this.userData, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UserDOBState createState() => _UserDOBState();
}

class _UserDOBState extends State<UserDOB> with SingleTickerProviderStateMixin {
  DateTime selecteddate = DateTime(1999, 10, 19);
  DateTime initialDate = DateTime(1999, 10, 19);
  TextEditingController dobctlr = TextEditingController();
  bool isDateSelected = false;
  
  // Use nullable types instead of late initialization
  AnimationController? _animationController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    // Initialize text controller
    dobctlr.text = '${initialDate.day}/${initialDate.month}/${initialDate.year}';
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Initialize animation
    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.elasticOut,
    );
    
    // Start animation after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _animationController != null) {
        _animationController!.forward();
      }
    });
  }
  
  @override
  void dispose() {
    // Clean up resources with null checks
    _animationController?.dispose();
    dobctlr.dispose();
    super.dispose();
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Select your birthday",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF27AE60),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: CupertinoDatePicker(
                  backgroundColor: Colors.white,
                  initialDateTime: selecteddate,
                  onDateTimeChanged: (DateTime newdate) {
                    setState(() {
                      dobctlr.text = '${newdate.day}/${newdate.month}/${newdate.year}';
                      selecteddate = newdate;
                      if (!isDateSelected && _animationController != null) {
                        isDateSelected = true;
                        _animationController!.reset();
                        _animationController!.forward();
                      }
                    });
                  },
                  maximumYear: 2007, // 18 years ago from 2025
                  minimumYear: 1950,
                  maximumDate: DateTime(2007, 6, 13), // 18 years ago from today
                  mode: CupertinoDatePickerMode.date,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "Confirm",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            children: [
              const Spacer(flex: 1),
              // Title section
              Column(
                children: const [
                  Text(
                    "My birthday is",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "This helps us show your age and connect better",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Date selector button
              GestureDetector(
                onTap: _showDatePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF27AE60),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        dobctlr.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Age requirement note
              const Text(
                "You must be 18+ to join Afropeep",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                  fontStyle: FontStyle.italic,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Use conditional widget instead of directly using the animation
              _animation != null
                  ? FadeTransition(
                      opacity: _animation!,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: CustomButton(
                          active: true,
                          color: textColor,
                          onTap: () {
                            widget.userData.addAll({
                              'user_DOB': "$selecteddate",
                              'age': ((DateTime.now().difference(selecteddate).inDays) /
                                      365.2425)
                                  .truncate(),
                            });
                            log(widget.userData.toString());
                            Navigator.pushNamed(context, RouteName.genderScreen,
                                arguments: widget.userData);
                          },
                          text: 'CONTINUE',
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: CustomButton(
                        active: true,
                        color: textColor,
                        onTap: () {
                          widget.userData.addAll({
                            'user_DOB': "$selecteddate",
                            'age': ((DateTime.now().difference(selecteddate).inDays) /
                                    365.2425)
                                .truncate(),
                          });
                          log(widget.userData.toString());
                          Navigator.pushNamed(context, RouteName.genderScreen,
                              arguments: widget.userData);
                        },
                        text: 'CONTINUE',
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
