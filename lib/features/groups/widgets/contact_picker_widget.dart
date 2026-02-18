import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../common/constants/app_colors.dart';
import '../../../services/contact_invitation_service.dart';

/// Modern contact picker widget for group member invitations
/// Features:
/// - Phone contact integration
/// - Email invitation option
/// - Search functionality
/// - Permission handling
/// - Industry-standard UI
class ContactPickerWidget extends StatefulWidget {
  const ContactPickerWidget({
    required this.groupName,
    required this.groupId,
    required this.onInvitationsSent,
    super.key,
  });
  final String groupName;
  final String groupId;
  final Function(List<Map<String, dynamic>>) onInvitationsSent;

  @override
  State<ContactPickerWidget> createState() => _ContactPickerWidgetState();
}

class _ContactPickerWidgetState extends State<ContactPickerWidget> {
  final ContactInvitationService _contactService = ContactInvitationService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  final List<Contact> _selectedContacts = [];
  bool _isLoading = false;
  bool _showEmailOption = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _messageController.text =
        'You are invited to join "${widget.groupName}" group!';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
    });

    try {
      final contacts = await _contactService.getPhoneContacts();

      if (contacts.isEmpty && mounted) {
        final granted = await _contactService.isContactPermissionGranted();
        if (!granted) {
          setState(() {
            _permissionDenied = true;
            _isLoading = false;
          });
          return;
        }
      }

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _filteredContacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contacts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts.where((contact) {
          final name = contact.displayName?.toLowerCase() ?? '';
          final phone = contact.phones?.first.value?.toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              phone.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleContactSelection(Contact contact) {
    setState(() {
      if (_selectedContacts.contains(contact)) {
        _selectedContacts.remove(contact);
      } else {
        _selectedContacts.add(contact);
      }
    });
  }

  Future<void> _sendInvitations() async {
    if (_selectedContacts.isEmpty && !_showEmailOption) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select contacts or enter an email'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final invitations = <Map<String, dynamic>>[];

    // Process selected contacts
    for (final contact in _selectedContacts) {
      final invitationData = _contactService.createInvitationData(
        contact: contact,
        groupName: widget.groupName,
        groupId: widget.groupId,
        customMessage: _messageController.text,
      );
      invitations.add(invitationData);
    }

    // Process email invitation if enabled
    if (_showEmailOption && _emailController.text.isNotEmpty) {
      if (!_contactService.isValidEmail(_emailController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      invitations.add({
        'contactName': _emailController.text.split('@')[0],
        'email': _emailController.text,
        'groupName': widget.groupName,
        'groupId': widget.groupId,
        'message': _messageController.text,
        'invitationType': 'email',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    // Send invitations
    for (final invitation in invitations) {
      if (invitation['invitationType'] == 'phone') {
        await _contactService.sendSMSInvitation(
          phoneNumber: invitation['phone']!,
          message: invitation['message'],
        );
      } else {
        await _contactService.sendEmailInvitation(
          email: invitation['email']!,
          subject: 'Invitation to join ${invitation['groupName']}',
          message: invitation['message'],
        );
      }
    }

    if (mounted) {
      widget.onInvitationsSent(invitations);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${invitations.length} invitations sent successfully!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    }
  }

  Widget _buildPermissionDeniedState() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Contact access required',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To invite friends to this group, please allow '
                'Afropeep to access your contacts.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await openAppSettings();
                  if (mounted) {
                    await _loadContacts();
                  }
                },
                icon: const Icon(Icons.settings),
                label: Text(
                  'Open Settings',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadContacts,
                child: Text(
                  'Try again',
                  style: GoogleFonts.montserrat(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyContactsState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No contacts found',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your device has no contacts to display.\n'
              'Use the email option above to invite members.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Add Members',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_selectedContacts.isNotEmpty || _showEmailOption)
              TextButton(
                onPressed: _sendInvitations,
                child: Text(
                  'Send (${_selectedContacts.length + (_showEmailOption ? 1 : 0)})',
                  style: GoogleFonts.montserrat(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _filterContacts,
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: GoogleFonts.montserrat(color: Colors.grey[400]),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primaryGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryGreen),
                  ),
                ),
              ),
            ),

            // Email invitation option
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Checkbox(
                    value: _showEmailOption,
                    onChanged: (value) {
                      setState(() {
                        _showEmailOption = value ?? false;
                      });
                    },
                    activeColor: AppColors.primaryGreen,
                  ),
                  Text(
                    'Add by email',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Email input field
            if (_showEmailOption)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    hintStyle: GoogleFonts.montserrat(color: Colors.grey[400]),
                    prefixIcon:
                        const Icon(Icons.email, color: AppColors.primaryGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primaryGreen),
                    ),
                  ),
                ),
              ),

            // Custom message field
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _messageController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Custom invitation message (optional)',
                  hintStyle: GoogleFonts.montserrat(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryGreen),
                  ),
                ),
              ),
            ),

            // Contacts list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _permissionDenied
                      ? _buildPermissionDeniedState()
                      : _filteredContacts.isEmpty
                          ? _buildEmptyContactsState()
                          : ListView.builder(
                          itemCount: _filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _filteredContacts[index];
                            final isSelected =
                                _selectedContacts.contains(contact);
                            final phone =
                                _contactService.getPrimaryPhone(contact);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? AppColors.primaryGreen
                                    : Colors.grey[300],
                                child: Icon(
                                  Icons.person,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                              title: Text(
                                contact.displayName ?? 'Unknown',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: phone != null
                                  ? Text(
                                      phone,
                                      style: GoogleFonts.montserrat(
                                        color: Colors.grey[600],
                                      ),
                                    )
                                  : null,
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primaryGreen,
                                    )
                                  : const Icon(
                                      Icons.radio_button_unchecked,
                                      color: Colors.grey,
                                    ),
                              onTap: () => _toggleContactSelection(contact),
                            );
                          },
                        ),
            ),
          ],
        ),
      );
}
