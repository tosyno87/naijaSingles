import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../common/routes/route_name.dart';

import '../../../../common/widgets/custom_button.dart';

class UserDOB extends StatefulWidget {
  const UserDOB(this.userData, {super.key});
  final Map<String, dynamic> userData;

  @override
  _UserDOBState createState() => _UserDOBState();
}

class _UserDOBState extends State<UserDOB> {
  DateTime selecteddate = DateTime(1999, 10, 19);
  DateTime initialDate = DateTime(1999, 10, 19);
  TextEditingController dobctlr = TextEditingController();
  bool isDateSelected = false;

  @override
  void initState() {
    super.initState();
    // Initialize text controller
    dobctlr.text =
        '${initialDate.day}/${initialDate.month}/${initialDate.year}';
  }

  @override
  void dispose() {
    dobctlr.dispose();
    super.dispose();
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) => Container(
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
                'Select your birthday',
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
                      dobctlr.text =
                          '${newdate.day}/${newdate.month}/${newdate.year}';
                      selecteddate = newdate;
                      isDateSelected = true;
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
                    'Confirm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Progress indicator
              Container(
                height: 4,
                width: screenSize.width *
                    0.30, // 30% of screen width (second step)
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 40),

              // Title section - Option 1: Playful & Flirty
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "When's your birthday?",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Age is just a number, but it helps us find your perfect match!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Date selector labelLarge
              GestureDetector(
                onTap: _showDatePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[50],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
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

              const Spacer(),

              // Age requirement note
              const Text(
                'You must be 18+ to join NaijaSingles',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 24),

              // Continue labelLarge
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: CustomButton(
                  active: true,
                  color: const Color(0xFF27AE60),
                  onTap: () {
                    widget.userData.addAll({
                      'user_DOB': '$selecteddate',
                      'age': ((DateTime.now().difference(selecteddate).inDays) /
                              365.2425)
                          .truncate(),
                    });
                    log(widget.userData.toString());
                    Navigator.pushNamed(context, RouteName.genderScreen,
                        arguments: widget.userData,);
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
