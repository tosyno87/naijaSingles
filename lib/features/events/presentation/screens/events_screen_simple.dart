import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EventsScreenSimple extends StatefulWidget {
  const EventsScreenSimple({Key? key}) : super(key: key);

  @override
  State<EventsScreenSimple> createState() => _EventsScreenSimpleState();
}

class _EventsScreenSimpleState extends State<EventsScreenSimple> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E5), // NaijaSingles cream background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover Events',
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find amazing Afrocentric events near you',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event,
                        size: 80,
                        color: const Color(0xFF008037),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Events Coming Soon!',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We\'re working on bringing you amazing events.',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: const Color(0xFF666666),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
