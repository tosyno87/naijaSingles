import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';

import 'package:naijasingles/common/bloc/theme/theme_bloc.dart';
import 'package:naijasingles/common/bloc/user/user_bloc.dart';
import 'package:naijasingles/features/payment/presentation/bloc/subscription_bloc.dart';
import 'package:naijasingles/features/payment/ui/in_app_purchase/buy_products/buyproducts_bloc.dart';
import 'package:naijasingles/features/payment/ui/in_app_purchase/buy_products/buyproducts_events.dart';
import 'package:naijasingles/features/payment/ui/in_app_purchase/buy_products/buyproducts_states.dart';
import 'package:naijasingles/features/payment/ui/in_app_purchase/get_products/getproducts_bloc.dart';
import 'package:naijasingles/features/payment/ui/in_app_purchase/get_products/getproducts_events.dart';
import 'package:naijasingles/features/payment/ui/in_app_purchase/get_products/getproducts_states.dart';
import 'package:naijasingles/features/payment/ui/products.dart';
import 'package:naijasingles/models/user_model.dart';

import '../../helpers/firebase_widget_setup.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockThemeBloc extends Mock implements ThemeBloc {}

class MockUserBloc extends Mock implements UserBloc {}

class MockGetInAppProductsBloc extends Mock implements GetInAppProductsBloc {}

class MockBuyConsumableBloc extends Mock
    implements BuyConsumableInAppProductsBloc {}

class FakeGetInAppProductsEvents extends Fake
    implements GetInAppProductsEvents {}

class FakeBuyInAppProductsEvents extends Fake
    implements BuyInAppProductsEvents {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProductDetails _fakeProduct({
  required String id,
  required String title,
  required double rawPrice,
  required String currencyCode,
}) =>
    ProductDetails(
      id: id,
      title: title,
      description: 'Test description',
      price: '\$${rawPrice.toStringAsFixed(2)}',
      rawPrice: rawPrice,
      currencyCode: currencyCode,
    );

void main() {
  setUpAll(() async {
    await setupFirebaseForWidgetTests();
    registerFallbackValue(FakeGetInAppProductsEvents());
    registerFallbackValue(FakeBuyInAppProductsEvents());
  });

  late MockThemeBloc themeBloc;
  late MockUserBloc userBloc;
  late MockGetInAppProductsBloc getProductsBloc;
  late MockBuyConsumableBloc buyBloc;

  final monthly = _fakeProduct(
    id: 'com.afropeep.premium.monthly',
    title: 'Monthly v2 (Afropeep)',
    rawPrice: 9.99,
    currencyCode: 'USD',
  );
  final yearly = _fakeProduct(
    id: 'com.afropeep.premium.yearly',
    title: 'Yearly v2 (Afropeep)',
    rawPrice: 79.99,
    currencyCode: 'USD',
  );

  setUp(() {
    themeBloc = MockThemeBloc();
    userBloc = MockUserBloc();
    getProductsBloc = MockGetInAppProductsBloc();
    buyBloc = MockBuyConsumableBloc();

    when(() => themeBloc.state).thenReturn(ThemeLoaded(ThemeMode.light));
    when(() => themeBloc.stream)
        .thenAnswer((_) => Stream.value(ThemeLoaded(ThemeMode.light)));
    when(() => themeBloc.isDarkMode).thenReturn(false);

    when(() => userBloc.state).thenReturn(const UserInitial());
    when(() => userBloc.stream)
        .thenAnswer((_) => const Stream<UserState>.empty());
    when(() => userBloc.currentUser).thenReturn(null);

    when(() => getProductsBloc.state).thenReturn(
      GetInAppProductsSuccessState(result: [monthly, yearly]),
    );
    when(() => getProductsBloc.stream).thenAnswer(
      (_) => Stream.value(
        GetInAppProductsSuccessState(result: [monthly, yearly]),
      ),
    );

    when(() => buyBloc.state).thenReturn(BuyConsumableInitialState());
    when(() => buyBloc.stream)
        .thenAnswer((_) => const Stream<BuyConsumableStates>.empty());
    when(() => buyBloc.add(any())).thenReturn(null);
  });

  Widget buildSubject() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>.value(value: themeBloc),
        BlocProvider<UserBloc>.value(value: userBloc),
        BlocProvider<GetInAppProductsBloc>.value(value: getProductsBloc),
        BlocProvider<BuyConsumableInAppProductsBloc>.value(value: buyBloc),
        BlocProvider<SubscriptionBloc>(
          create: (_) => SubscriptionBloc(
            userBloc: userBloc,
            isStoreAvailable: () async => false,
            purchaseUpdates: () => const Stream<List<PurchaseDetails>>.empty(),
          ),
        ),
      ],
      child: Products(
        UserModel(id: 'u1', name: 'Test'),
        null,
        const <String, dynamic>{},
      ),
    );
  }

  group('Products paywall', () {
    testWidgets(
      'auto-selects first plan and CTA shows its label',
      (tester) async {
        await tester.pumpWidget(MaterialApp(home: buildSubject()));
        await tester.pumpAndSettle();

        // First plan (monthly) should be auto-selected, so CTA
        // should read "Continue with Monthly".
        expect(find.text('Continue with Monthly'), findsOneWidget);

        // Both plan labels should be visible.
        expect(find.text('Monthly'), findsOneWidget);
        expect(find.text('Yearly'), findsOneWidget);

        // Benefits are shown.
        expect(find.text('Unlimited swipes'), findsOneWidget);
        expect(find.text('See who likes you'), findsOneWidget);

        // Raw product titles (with "v2") should NOT appear.
        expect(find.text(monthly.title), findsNothing);
        expect(find.text(yearly.title), findsNothing);
      },
    );

    testWidgets(
      'tapping yearly card updates CTA label',
      (tester) async {
        await tester.pumpWidget(MaterialApp(home: buildSubject()));
        await tester.pumpAndSettle();

        // Initially monthly is selected.
        expect(find.text('Continue with Monthly'), findsOneWidget);

        // Tap the yearly card (find by 'Yearly' text).
        await tester.tap(find.text('Yearly'));
        await tester.pumpAndSettle();

        expect(find.text('Continue with Yearly'), findsOneWidget);
      },
    );

    testWidgets(
      'yearly card shows dynamic savings badge when cheaper per month',
      (tester) async {
        await tester.pumpWidget(MaterialApp(home: buildSubject()));
        await tester.pumpAndSettle();

        // yearly = $79.99/12 ≈ $6.67/mo vs monthly $9.99/mo → ~33% savings
        expect(find.textContaining('Save'), findsOneWidget);
        expect(find.textContaining('%'), findsOneWidget);
      },
    );

    testWidgets(
      'Continue prepares listener then dispatches buy',
      (tester) async {
        await tester.pumpWidget(MaterialApp(home: buildSubject()));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Continue with Monthly'));
        // prepareForPurchase awaits store availability; avoid pumpAndSettle.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        verify(() => buyBloc.add(any())).called(1);
      },
    );
  });
}
