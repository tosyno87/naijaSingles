import 'package:flutter/material.dart';
import '../../../../services/message_delivery_service.dart';

class EnhancedMessageWidget extends StatelessWidget {
  const EnhancedMessageWidget({
    required this.messageText,
    required this.status,
    required this.isSender,
    super.key,
  });
  final String messageText;
  final MessageStatus status;
  final bool isSender;

  @override
  Widget build(BuildContext context) => Row(
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
