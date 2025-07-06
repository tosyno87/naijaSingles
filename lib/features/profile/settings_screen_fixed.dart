// Alternative approaches to fix text bleeding in sign out button

// Option 1: Use Expanded with proper constraints
Container(
  width: double.infinity,
  height: 56,
  padding: const EdgeInsets.symmetric(horizontal: 16), // Container padding
  child: ElevatedButton(
    onPressed: () => _showSignOutDialog(),
    style: ElevatedButton.styleFrom(
      backgroundColor: cardColor,
      foregroundColor: Colors.red.shade700,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade300, width: 2),
      ),
      elevation: 2,
    ),
    child: Text(
      'Sign Out',
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.red.shade700,
      ),
    ),
  ),
),

// Option 2: Use SizedBox with specific width
SizedBox(
  width: MediaQuery.of(context).size.width - 64, // Screen width minus padding
  height: 56,
  child: ElevatedButton(
    onPressed: () => _showSignOutDialog(),
    style: ElevatedButton.styleFrom(
      backgroundColor: cardColor,
      foregroundColor: Colors.red.shade700,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade300, width: 2),
      ),
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
    child: Text(
      'Sign Out',
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.red.shade700,
      ),
    ),
  ),
),

// Option 3: Use FractionallySizedBox
FractionallySizedBox(
  widthFactor: 0.9, // 90% of available width
  child: Container(
    height: 56,
    child: ElevatedButton(
      onPressed: () => _showSignOutDialog(),
      style: ElevatedButton.styleFrom(
        backgroundColor: cardColor,
        foregroundColor: Colors.red.shade700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.shade300, width: 2),
        ),
        elevation: 2,
      ),
      child: Text(
        'Sign Out',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.red.shade700,
        ),
      ),
    ),
  ),
)
