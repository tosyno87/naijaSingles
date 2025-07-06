// Alternative Sign Out Button Layout - Simpler approach

// Option 1: Simple icon + text (no circular background)
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: cardColor,
    foregroundColor: Colors.red.shade700,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.red.shade300, width: 2),
    ),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.logout_outlined, size: 20),
      const SizedBox(width: 16),
      Text(
        'Sign Out',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
)

// Option 2: Text only (most space-efficient)
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: cardColor,
    foregroundColor: Colors.red.shade700,
    padding: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.red.shade300, width: 2),
    ),
  ),
  child: Text(
    'Sign Out',
    style: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
)
