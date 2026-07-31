import 'package:flutter/material.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../models/user_model.dart';

/// "I'm looking for" intent selector used on discovery preference screens.
class LookingForConnectionCard extends StatefulWidget {
  const LookingForConnectionCard({
    required this.currentUser,
    required this.changeValues,
    this.compact = false,
    super.key,
  });

  final UserModel currentUser;
  final Map<String, dynamic> changeValues;
  final bool compact;

  @override
  State<LookingForConnectionCard> createState() =>
      _LookingForConnectionCardState();
}

class _LookingForConnectionCardState extends State<LookingForConnectionCard> {
  static const Map<String, String> _modes = <String, String>{
    'Dating': 'Dating & Romance',
    'Friendship': 'Friendship & Social',
    'Networking': 'Professional Networking',
    'Mixed': 'All of the Above',
  };

  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentUser.lookingFor ?? 'Dating';
    if (!_modes.containsKey(_selected)) {
      _selected = 'Dating';
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pad = widget.compact
        ? const EdgeInsets.fromLTRB(10, 10, 10, 8)
        : const EdgeInsets.all(15);
    return Card(
      child: Padding(
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'I\'m looking for',
              style: TextStyle(
                fontSize: widget.compact ? 15 : 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: widget.compact ? 6 : 8),
            ..._modes.entries.map(
              (MapEntry<String, String> entry) => RadioListTile<String>(
                title: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: widget.compact ? 14.5 : 15,
                    height: 1.25,
                  ),
                ),
                value: entry.key,
                // ignore: deprecated_member_use
                groupValue: _selected,
                activeColor: AppColors.primaryGreen,
                contentPadding: EdgeInsets.zero,
                dense: widget.compact,
                visualDensity: widget.compact
                    ? VisualDensity.compact
                    : VisualDensity.standard,
                // ignore: deprecated_member_use
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() => _selected = value);
                  widget.changeValues['lookingFor'] = value;
                  // Keep the shared in-memory model in sync (same pattern as
                  // ShowmeWidget/DistanceWidget) so post-apply reloads and
                  // screen re-opens reflect the new intent.
                  widget.currentUser.lookingFor = value;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
