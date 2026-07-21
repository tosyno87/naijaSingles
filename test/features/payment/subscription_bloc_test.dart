import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';

import 'package:naijasingles/common/bloc/user/user_bloc.dart';
import 'package:naijasingles/features/payment/data/subscription_functions_service.dart';
import 'package:naijasingles/features/payment/presentation/bloc/subscription_bloc.dart';

class MockUserBloc extends Mock implements UserBloc {}

class MockSubscriptionFunctionsService extends Mock
    implements SubscriptionFunctionsService {}

class FakeUserEvent extends Fake implements UserEvent {}

PurchaseDetails _purchase({
  required String productId,
  PurchaseStatus status = PurchaseStatus.purchased,
}) =>
    PurchaseDetails(
      productID: productId,
      purchaseID: 'p-$productId',
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server',
        source: 'test',
      ),
      transactionDate: '0',
      status: status,
    );

void main() {
  late MockUserBloc userBloc;
  late MockSubscriptionFunctionsService functions;

  setUpAll(() {
    registerFallbackValue(FakeUserEvent());
  });

  setUp(() {
    userBloc = MockUserBloc();
    functions = MockSubscriptionFunctionsService();
    when(() => userBloc.state).thenReturn(const UserInitial());
    when(() => userBloc.stream)
        .thenAnswer((_) => const Stream<UserState>.empty());
    when(() => userBloc.add(any())).thenReturn(null);
    when(
      () => functions.verifySubscriptionPurchase(
        platform: any(named: 'platform'),
        productId: any(named: 'productId'),
        purchaseToken: any(named: 'purchaseToken'),
        receiptData: any(named: 'receiptData'),
        packageName: any(named: 'packageName'),
      ),
    ).thenAnswer((_) async => 'ok');
  });

  SubscriptionBloc buildBloc() => SubscriptionBloc(
        userBloc: userBloc,
        functionsService: functions,
        isStoreAvailable: () async => false,
        purchaseUpdates: () => const Stream<List<PurchaseDetails>>.empty(),
      );

  group('SubscriptionBloc.prepareForPurchase', () {
    test('throws when uid is empty', () async {
      final SubscriptionBloc bloc = buildBloc();
      expect(
        () => bloc.prepareForPurchase(''),
        throwsA(isA<ArgumentError>()),
      );
      await bloc.close();
    });

    blocTest<SubscriptionBloc, SubscriptionState>(
      'sets uid so later batches are verified for that user',
      build: buildBloc,
      act: (SubscriptionBloc bloc) async {
        // Drain constructor-triggered SubscriptionUserChanged(null).
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await bloc.prepareForPurchase('user-a');
        bloc.add(
          SubscriptionPurchaseBatch([
            _purchase(productId: 'premium.monthly'),
          ]),
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(
          () => functions.verifySubscriptionPurchase(
            platform: any(named: 'platform'),
            productId: 'premium.monthly',
            purchaseToken: any(named: 'purchaseToken'),
            receiptData: any(named: 'receiptData'),
            packageName: any(named: 'packageName'),
          ),
        ).called(1);
      },
    );
  });

  group('SubscriptionBloc unsigned purchase buffering', () {
    blocTest<SubscriptionBloc, SubscriptionState>(
      'cold start: buffers purchased update while uid is null',
      build: buildBloc,
      act: (SubscriptionBloc bloc) {
        bloc.add(
          SubscriptionPurchaseBatch([
            _purchase(productId: 'premium.monthly'),
          ]),
        );
      },
      expect: () => [
        isA<SubscriptionState>().having(
          (SubscriptionState s) => s.purchaseInProgress,
          'purchaseInProgress',
          isTrue,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => functions.verifySubscriptionPurchase(
            platform: any(named: 'platform'),
            productId: any(named: 'productId'),
            purchaseToken: any(named: 'purchaseToken'),
            receiptData: any(named: 'receiptData'),
            packageName: any(named: 'packageName'),
          ),
        );
      },
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'after logout, unsigned batches are dropped (not applied on next login)',
      build: buildBloc,
      act: (SubscriptionBloc bloc) async {
        // Establish a signed-in session, then log out.
        bloc.add(const SubscriptionUserChanged('user-a'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SubscriptionUserChanged(null));
        await Future<void>.delayed(Duration.zero);

        // Store update while signed out — must be dropped.
        bloc.add(
          SubscriptionPurchaseBatch([
            _purchase(productId: 'premium.monthly'),
          ]),
        );
        await Future<void>.delayed(Duration.zero);

        // Next login must not verify the signed-out purchase.
        bloc.add(const SubscriptionUserChanged('user-b'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      verify: (_) {
        verifyNever(
          () => functions.verifySubscriptionPurchase(
            platform: any(named: 'platform'),
            productId: any(named: 'productId'),
            purchaseToken: any(named: 'purchaseToken'),
            receiptData: any(named: 'receiptData'),
            packageName: any(named: 'packageName'),
          ),
        );
      },
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'cold start buffer is flushed when first uid arrives',
      build: buildBloc,
      act: (SubscriptionBloc bloc) async {
        bloc.add(
          SubscriptionPurchaseBatch([
            _purchase(productId: 'premium.yearly'),
          ]),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SubscriptionUserChanged('user-cold'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      verify: (_) {
        verify(
          () => functions.verifySubscriptionPurchase(
            platform: any(named: 'platform'),
            productId: 'premium.yearly',
            purchaseToken: any(named: 'purchaseToken'),
            receiptData: any(named: 'receiptData'),
            packageName: any(named: 'packageName'),
          ),
        ).called(1);
      },
    );
  });

  group('SubscriptionBloc consume events', () {
    blocTest<SubscriptionBloc, SubscriptionState>(
      'consume user message clears it',
      build: buildBloc,
      seed: () => const SubscriptionState(userMessage: 'Hello'),
      act: (SubscriptionBloc bloc) =>
          bloc.add(const SubscriptionConsumeUserMessage()),
      expect: () => [
        isA<SubscriptionState>().having(
          (SubscriptionState s) => s.userMessage,
          'userMessage',
          isNull,
        ),
      ],
    );
  });
}
