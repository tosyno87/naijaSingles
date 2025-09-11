import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/user_model.dart';

/// Mode-specific action buttons for different relationship intents
class ModeActionButtons extends StatelessWidget {
  final String selectedMode;
  final UserModel? currentUser;
  final VoidCallback? onSuperLike;
  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final VoidCallback? onModeSpecificAction;

  const ModeActionButtons({
    Key? key,
    required this.selectedMode,
    this.currentUser,
    this.onSuperLike,
    this.onPass,
    this.onLike,
    this.onModeSpecificAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Pass button (same for all modes)
        _buildActionButton(
          icon: Icons.close,
          color: Colors.red,
          onTap: onPass,
          tooltip: 'Pass',
        ),
        
        // Mode-specific primary action
        _buildModeSpecificAction(),
        
        // Super like button (same for all modes)
        _buildActionButton(
          icon: Icons.star_rounded,
          color: Colors.blue,
          onTap: onSuperLike,
          tooltip: 'Super Like',
        ),
      ],
    );
  }

  Widget _buildModeSpecificAction() {
    switch (selectedMode) {
      case 'Dating':
        return _buildActionButton(
          icon: Icons.favorite,
          color: Colors.pink,
          onTap: onLike,
          tooltip: 'Like',
        );
      
      case 'Friendship':
        return _buildActionButton(
          icon: Icons.people,
          color: Colors.green,
          onTap: onLike,
          tooltip: 'Connect',
        );
      
      case 'Networking':
        return _buildActionButton(
          icon: Icons.handshake,
          color: Colors.orange,
          onTap: onLike,
          tooltip: 'Network',
        );
      
      default:
        return _buildActionButton(
          icon: Icons.favorite,
          color: Colors.pink,
          onTap: onLike,
          tooltip: 'Like',
        );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return Material(
      elevation: 8,
      shape: const CircleBorder(),
      color: color,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          child: Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}

/// Mode-specific action button with enhanced styling
class EnhancedModeActionButton extends StatelessWidget {
  final String selectedMode;
  final VoidCallback? onTap;
  final bool isEnabled;

  const EnhancedModeActionButton({
    Key? key,
    required this.selectedMode,
    this.onTap,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getModeConfig();
    
    return Material(
      elevation: isEnabled ? 8 : 2,
      shape: const CircleBorder(),
      color: isEnabled ? config.color : Colors.grey,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: 70,
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                config.icon,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 2),
              Text(
                config.label,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _ModeConfig _getModeConfig() {
    switch (selectedMode) {
      case 'Dating':
        return _ModeConfig(
          icon: Icons.favorite,
          color: Colors.pink,
          label: 'Like',
        );
      
      case 'Friendship':
        return _ModeConfig(
          icon: Icons.people,
          color: Colors.green,
          label: 'Connect',
        );
      
      case 'Networking':
        return _ModeConfig(
          icon: Icons.handshake,
          color: Colors.orange,
          label: 'Network',
        );
      
      default:
        return _ModeConfig(
          icon: Icons.favorite,
          color: Colors.pink,
          label: 'Like',
        );
    }
  }
}

class _ModeConfig {
  final IconData icon;
  final Color color;
  final String label;

  _ModeConfig({
    required this.icon,
    required this.color,
    required this.label,
  });
}

/// Mode-specific action sheet for additional options
class ModeActionSheet extends StatelessWidget {
  final String selectedMode;
  final UserModel user;
  final VoidCallback? onClose;

  const ModeActionSheet({
    Key? key,
    required this.selectedMode,
    required this.user,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Mode-specific content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  _getModeTitle(),
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 20),
                ..._getModeSpecificActions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getModeTitle() {
    switch (selectedMode) {
      case 'Dating':
        return 'Dating Options';
      case 'Friendship':
        return 'Friendship Options';
      case 'Networking':
        return 'Networking Options';
      default:
        return 'Options';
    }
  }

  List<Widget> _getModeSpecificActions(BuildContext context) {
    switch (selectedMode) {
      case 'Dating':
        return [
          _buildActionTile(
            icon: Icons.restaurant,
            title: 'Ask on a Date',
            subtitle: 'Suggest a coffee or dinner',
            onTap: () => _handleDatingAction(context, 'date'),
          ),
          _buildActionTile(
            icon: Icons.chat,
            title: 'Start Conversation',
            subtitle: 'Send a message',
            onTap: () => _handleDatingAction(context, 'chat'),
          ),
          _buildActionTile(
            icon: Icons.favorite,
            title: 'Express Interest',
            subtitle: 'Show you\'re interested',
            onTap: () => _handleDatingAction(context, 'interest'),
          ),
        ];
      
      case 'Friendship':
        return [
          _buildActionTile(
            icon: Icons.group,
            title: 'Hang Out',
            subtitle: 'Suggest a group activity',
            onTap: () => _handleFriendshipAction(context, 'hangout'),
          ),
          _buildActionTile(
            icon: Icons.sports,
            title: 'Share Interests',
            subtitle: 'Connect over hobbies',
            onTap: () => _handleFriendshipAction(context, 'interests'),
          ),
          _buildActionTile(
            icon: Icons.people,
            title: 'Make Friends',
            subtitle: 'Start a friendship',
            onTap: () => _handleFriendshipAction(context, 'friendship'),
          ),
        ];
      
      case 'Networking':
        return [
          _buildActionTile(
            icon: Icons.business_center,
            title: 'Professional Connect',
            subtitle: 'Connect for business',
            onTap: () => _handleNetworkingAction(context, 'connect'),
          ),
          _buildActionTile(
            icon: Icons.lightbulb,
            title: 'Share Ideas',
            subtitle: 'Discuss opportunities',
            onTap: () => _handleNetworkingAction(context, 'ideas'),
          ),
          _buildActionTile(
            icon: Icons.handshake,
            title: 'Collaborate',
            subtitle: 'Explore partnerships',
            onTap: () => _handleNetworkingAction(context, 'collaborate'),
          ),
        ];
      
      default:
        return [];
    }
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF008037)),
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF333333),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          color: const Color(0xFF666666),
        ),
      ),
      onTap: onTap,
    );
  }

  void _handleDatingAction(BuildContext context, String action) {
    Navigator.pop(context);
    // Handle dating-specific actions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dating action: $action'),
        backgroundColor: Colors.pink,
      ),
    );
  }

  void _handleFriendshipAction(BuildContext context, String action) {
    Navigator.pop(context);
    // Handle friendship-specific actions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Friendship action: $action'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleNetworkingAction(BuildContext context, String action) {
    Navigator.pop(context);
    // Handle networking-specific actions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Networking action: $action'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
