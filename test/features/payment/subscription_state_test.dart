import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/payment/presentation/bloc/subscription_bloc.dart';

void main() {
  group('SubscriptionState', () {
    test('copyWith clears userMessage when clearUserMessage is true', () {
      const SubscriptionState s = SubscriptionState(userMessage: 'Hi');
      final SubscriptionState cleared =
          s.copyWith(clearUserMessage: true, userMessage: 'ignored');
      expect(cleared.userMessage, isNull);
    });

    test('copyWith clears navigate flag when clearNavigate is true', () {
      const SubscriptionState s =
          SubscriptionState(shouldNavigateToSuccess: true);
      final SubscriptionState cleared = s.copyWith(clearNavigate: true);
      expect(cleared.shouldNavigateToSuccess, isFalse);
    });
  });
}
