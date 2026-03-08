import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';

/// Design tokens for all chat surfaces (DM and group).
///
/// Consumed via `Theme.of(context).extension<ChatUiTokens>()` when the
/// extension is registered, or directly via the [defaults] factory.
class ChatUiTokens extends ThemeExtension<ChatUiTokens> {
  const ChatUiTokens({
    required this.ownBubbleColor,
    required this.otherBubbleColor,
    required this.ownTextColor,
    required this.otherTextColor,
    required this.timestampOwnColor,
    required this.timestampOtherColor,
    required this.senderNameColor,
    required this.systemBubbleColor,
    required this.systemTextColor,
    required this.composerBackground,
    required this.inputFillColor,
    required this.sendButtonActiveColor,
    required this.sendButtonInactiveColor,
    required this.bubblePadding,
    required this.bubbleRadius,
    required this.bubbleTailRadius,
    required this.bubbleShadow,
    required this.messageFontSize,
    required this.timestampFontSize,
    required this.senderNameFontSize,
    required this.inputBorderRadius,
    required this.readReceiptColor,
    required this.readReceiptReadColor,
  });

  factory ChatUiTokens.defaults() => ChatUiTokens(
        ownBubbleColor: AppColors.primaryGreen,
        otherBubbleColor: Colors.white,
        ownTextColor: Colors.white,
        otherTextColor: Colors.black87,
        timestampOwnColor: Colors.white.withValues(alpha: 0.8),
        timestampOtherColor: Colors.grey.shade500,
        senderNameColor: Colors.grey.shade600,
        systemBubbleColor: Colors.grey.shade200,
        systemTextColor: Colors.grey.shade600,
        composerBackground: Colors.white,
        inputFillColor: Colors.grey.shade100,
        sendButtonActiveColor: AppColors.primaryGreen,
        sendButtonInactiveColor: Colors.grey.shade300,
        bubblePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        bubbleRadius: 20,
        bubbleTailRadius: 4,
        bubbleShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        messageFontSize: 15,
        timestampFontSize: 11,
        senderNameFontSize: 12,
        inputBorderRadius: 24,
        readReceiptColor: Colors.white.withValues(alpha: 0.8),
        readReceiptReadColor: Colors.blue.shade300,
      );

  final Color ownBubbleColor;
  final Color otherBubbleColor;
  final Color ownTextColor;
  final Color otherTextColor;
  final Color timestampOwnColor;
  final Color timestampOtherColor;
  final Color senderNameColor;
  final Color systemBubbleColor;
  final Color systemTextColor;
  final Color composerBackground;
  final Color inputFillColor;
  final Color sendButtonActiveColor;
  final Color sendButtonInactiveColor;
  final EdgeInsets bubblePadding;
  final double bubbleRadius;
  final double bubbleTailRadius;
  final List<BoxShadow> bubbleShadow;
  final double messageFontSize;
  final double timestampFontSize;
  final double senderNameFontSize;
  final double inputBorderRadius;
  final Color readReceiptColor;
  final Color readReceiptReadColor;

  TextStyle messageStyle({required bool isOwn}) => GoogleFonts.montserrat(
        fontSize: messageFontSize,
        color: isOwn ? ownTextColor : otherTextColor,
        height: 1.4,
      );

  TextStyle timestampStyle({required bool isOwn}) => GoogleFonts.montserrat(
        fontSize: timestampFontSize,
        color: isOwn ? timestampOwnColor : timestampOtherColor,
      );

  TextStyle senderNameStyle() => GoogleFonts.montserrat(
        fontSize: senderNameFontSize,
        fontWeight: FontWeight.w600,
        color: senderNameColor,
      );

  TextStyle systemMessageStyle() => GoogleFonts.montserrat(
        fontSize: 12,
        color: systemTextColor,
        fontStyle: FontStyle.italic,
      );

  @override
  ChatUiTokens copyWith({
    Color? ownBubbleColor,
    Color? otherBubbleColor,
    Color? ownTextColor,
    Color? otherTextColor,
    Color? timestampOwnColor,
    Color? timestampOtherColor,
    Color? senderNameColor,
    Color? systemBubbleColor,
    Color? systemTextColor,
    Color? composerBackground,
    Color? inputFillColor,
    Color? sendButtonActiveColor,
    Color? sendButtonInactiveColor,
    EdgeInsets? bubblePadding,
    double? bubbleRadius,
    double? bubbleTailRadius,
    List<BoxShadow>? bubbleShadow,
    double? messageFontSize,
    double? timestampFontSize,
    double? senderNameFontSize,
    double? inputBorderRadius,
    Color? readReceiptColor,
    Color? readReceiptReadColor,
  }) =>
      ChatUiTokens(
        ownBubbleColor: ownBubbleColor ?? this.ownBubbleColor,
        otherBubbleColor: otherBubbleColor ?? this.otherBubbleColor,
        ownTextColor: ownTextColor ?? this.ownTextColor,
        otherTextColor: otherTextColor ?? this.otherTextColor,
        timestampOwnColor: timestampOwnColor ?? this.timestampOwnColor,
        timestampOtherColor: timestampOtherColor ?? this.timestampOtherColor,
        senderNameColor: senderNameColor ?? this.senderNameColor,
        systemBubbleColor: systemBubbleColor ?? this.systemBubbleColor,
        systemTextColor: systemTextColor ?? this.systemTextColor,
        composerBackground: composerBackground ?? this.composerBackground,
        inputFillColor: inputFillColor ?? this.inputFillColor,
        sendButtonActiveColor:
            sendButtonActiveColor ?? this.sendButtonActiveColor,
        sendButtonInactiveColor:
            sendButtonInactiveColor ?? this.sendButtonInactiveColor,
        bubblePadding: bubblePadding ?? this.bubblePadding,
        bubbleRadius: bubbleRadius ?? this.bubbleRadius,
        bubbleTailRadius: bubbleTailRadius ?? this.bubbleTailRadius,
        bubbleShadow: bubbleShadow ?? this.bubbleShadow,
        messageFontSize: messageFontSize ?? this.messageFontSize,
        timestampFontSize: timestampFontSize ?? this.timestampFontSize,
        senderNameFontSize: senderNameFontSize ?? this.senderNameFontSize,
        inputBorderRadius: inputBorderRadius ?? this.inputBorderRadius,
        readReceiptColor: readReceiptColor ?? this.readReceiptColor,
        readReceiptReadColor:
            readReceiptReadColor ?? this.readReceiptReadColor,
      );

  @override
  ChatUiTokens lerp(ChatUiTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return ChatUiTokens(
      ownBubbleColor: Color.lerp(ownBubbleColor, other.ownBubbleColor, t)!,
      otherBubbleColor:
          Color.lerp(otherBubbleColor, other.otherBubbleColor, t)!,
      ownTextColor: Color.lerp(ownTextColor, other.ownTextColor, t)!,
      otherTextColor: Color.lerp(otherTextColor, other.otherTextColor, t)!,
      timestampOwnColor:
          Color.lerp(timestampOwnColor, other.timestampOwnColor, t)!,
      timestampOtherColor:
          Color.lerp(timestampOtherColor, other.timestampOtherColor, t)!,
      senderNameColor:
          Color.lerp(senderNameColor, other.senderNameColor, t)!,
      systemBubbleColor:
          Color.lerp(systemBubbleColor, other.systemBubbleColor, t)!,
      systemTextColor:
          Color.lerp(systemTextColor, other.systemTextColor, t)!,
      composerBackground:
          Color.lerp(composerBackground, other.composerBackground, t)!,
      inputFillColor: Color.lerp(inputFillColor, other.inputFillColor, t)!,
      sendButtonActiveColor:
          Color.lerp(sendButtonActiveColor, other.sendButtonActiveColor, t)!,
      sendButtonInactiveColor: Color.lerp(
        sendButtonInactiveColor,
        other.sendButtonInactiveColor,
        t,
      )!,
      bubblePadding: EdgeInsets.lerp(bubblePadding, other.bubblePadding, t)!,
      bubbleRadius: lerpDouble(bubbleRadius, other.bubbleRadius, t)!,
      bubbleTailRadius:
          lerpDouble(bubbleTailRadius, other.bubbleTailRadius, t)!,
      bubbleShadow: other.bubbleShadow,
      messageFontSize:
          lerpDouble(messageFontSize, other.messageFontSize, t)!,
      timestampFontSize:
          lerpDouble(timestampFontSize, other.timestampFontSize, t)!,
      senderNameFontSize:
          lerpDouble(senderNameFontSize, other.senderNameFontSize, t)!,
      inputBorderRadius:
          lerpDouble(inputBorderRadius, other.inputBorderRadius, t)!,
      readReceiptColor:
          Color.lerp(readReceiptColor, other.readReceiptColor, t)!,
      readReceiptReadColor:
          Color.lerp(readReceiptReadColor, other.readReceiptReadColor, t)!,
    );
  }

  static double? lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    final start = a ?? 0.0;
    final end = b ?? 0.0;
    return start + (end - start) * t;
  }
}
