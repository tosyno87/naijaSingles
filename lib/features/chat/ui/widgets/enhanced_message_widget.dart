import 'package:flutter/material.dart';
import 'package:naijasingles/services/message_delivery_service.dart';

class EnhancedMessageWidget extends StatelessWidget {
  final String messageText;
  final MessageStatus status;
  final bool isSender;

  const EnhancedMessageWidget({
    super.key,
    required this.messageText,
    required this.status,
    required this.isSender,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            messageText,
            style: TextStyle(
              color: isSender ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          MessageDeliveryService.getMessageStatusIcon(status),
          size: 16,
          color: MessageDeliveryService.getMessageStatusColor(status),
        ),
      ],
    );
  }
}
