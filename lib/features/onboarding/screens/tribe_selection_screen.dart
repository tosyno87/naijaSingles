import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../user/controllers/onboarding_controller.dart';

class TribeSelectionScreen extends StatefulWidget {
  const TribeSelectionScreen({super.key});

  @override
  State<TribeSelectionScreen> createState() => _TribeSelectionScreenState();
}

class _TribeSelectionScreenState extends State<TribeSelectionScreen> {
  String _selectedTribe = '';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // List of Nigerian tribes
  final List<String> _tribes = [
    'Yoruba',
    'Igbo',
    'Hausa',
    'Fulani',
    'Ijaw',
    'Kanuri',
    'Ibibio',
    'Tiv',
    'Edo',
    'Nupe',
    'Urhobo',
    'Igala',
    'Idoma',
    'Ebira',
    'Efik',
    'Gwari',
    'Jukun',
    'Kalabari',
    'Ogoni',
    'Isoko',
    'Ikwerre',
    'Itsekiri',
    'Birom',
    'Angas',
    'Tarok',
    'Chamba',
    'Esan',
    'Anioma',
    'Ogoja',
    'Ishan',
    'Afemai',
    'Ekiti',
    'Ijebu',
    'Egba',
    'Awori',
    'Ijesha',
    'Ondo',
    'Oyo',
    'Ife',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<OnboardingController>(context, listen: false);
      
      if (controller.tribe.isNotEmpty) {
        setState(() {
          _selectedTribe = controller.tribe;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectTribe(String tribe) {
    setState(() {
      _selectedTribe = tribe;
    });
    
    // Save to controller
    Provider.of<OnboardingController>(context, listen: false)
        .setTribe(tribe);
  }

  List<String> get _filteredTribes {
    if (_searchQuery.isEmpty) {
      return _tribes;
    }
    
    return _tribes.where((tribe) => 
      tribe.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Define colors
    const Color primaryColor = Color(0xFF008037); // Deep Green
    const Color textColor = Color(0xFF333333);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Your Tribe",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                "This helps us connect you with people from similar backgrounds",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Search box
              TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Search tribes",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ],
          ),
        ),
        
        // Tribe list
        Expanded(
          child: _filteredTribes.isEmpty
              ? Center(
                  child: Text(
                    "No tribes found",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  itemCount: _filteredTribes.length,
                  itemBuilder: (context, index) {
                    final tribe = _filteredTribes[index];
                    final isSelected = tribe == _selectedTribe;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      elevation: isSelected ? 2 : 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          tribe,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected ? primaryColor : textColor,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: primaryColor,
                              )
                            : null,
                        onTap: () => _selectTribe(tribe),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
