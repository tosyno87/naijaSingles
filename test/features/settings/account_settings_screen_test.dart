import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:naijasingles/common/bloc/theme/theme_bloc.dart';
import 'package:naijasingles/common/bloc/user/user_bloc.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/features/payment/presentation/bloc/subscription_bloc.dart';
import 'package:naijasingles/features/settings/account_settings_screen.dart';
import 'package:naijasingles/models/user_model.dart';

import '../../helpers/firebase_widget_setup.dart';

class MockThemeBloc extends Mock implements ThemeBloc {}

class MockUserBloc extends Mock implements UserBloc {}

/// Providers required by [AccountSettingsScreen] (subscription + account hub).
MultiBlocProvider accountSettingsTestHarness({
  required ThemeBloc theme,
  required UserBloc user,
}) =>
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>.value(value: theme),
        BlocProvider<UserBloc>.value(value: user),
        BlocProvider<SubscriptionBloc>(
          create: (BuildContext context) => SubscriptionBloc(userBloc: user),
        ),
      ],
      child: const AccountSettingsScreen(),
    );

/// Stubs for the four hub drill-downs registered in [RouteName] (named routes).
Map<String, WidgetBuilder> get _stubNewSettingsRoutes => {
      RouteName.phoneEmailSettings: (_) => const Scaffold(
            body: Text('__route_phone_email__'),
          ),
      RouteName.connectedAccountsSettings: (_) => const Scaffold(
            body: Text('__route_connected_accounts__'),
          ),
      RouteName.emailNotificationsSettings: (_) => const Scaffold(
            body: Text('__route_email_notifications__'),
          ),
      RouteName.downloadMyData: (_) => const Scaffold(
            body: Text('__route_download_my_data__'),
          ),
    };

void main() {
  setUpAll(() async {
    await setupFirebaseForWidgetTests();
  });

  late MockThemeBloc themeBloc;
  late MockUserBloc userBloc;

  setUp(() {
    themeBloc = MockThemeBloc();
    userBloc = MockUserBloc();
    when(() => themeBloc.state).thenReturn(ThemeLoaded(ThemeMode.light));
    when(() => themeBloc.stream).thenAnswer(
      (_) => Stream<ThemeState>.value(ThemeLoaded(ThemeMode.light)),
    );
    when(() => themeBloc.isDarkMode).thenReturn(false);
    when(() => userBloc.state).thenReturn(const UserInitial());
    when(() => userBloc.stream).thenAnswer(
      (_) => const Stream<UserState>.empty(),
    );
    when(() => userBloc.currentUser).thenReturn(null);
  });

  testWidgets('AccountSettingsScreen shows hub sections', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: accountSettingsTestHarness(theme: themeBloc, user: userBloc),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('NOTIFICATIONS'), findsOneWidget);
  });

  testWidgets('tapping Push notifications navigates to notification route',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          RouteName.notificationSettings: (_) => const Scaffold(
                body: Text('notification_route_body'),
              ),
        },
        home: accountSettingsTestHarness(theme: themeBloc, user: userBloc),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Push notifications'),
      500,
    );
    await tester.tap(find.text('Push notifications'));
    await tester.pumpAndSettle();

    expect(find.text('notification_route_body'), findsOneWidget);
  });

  testWidgets('tapping Phone & email opens named route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: _stubNewSettingsRoutes,
        home: accountSettingsTestHarness(theme: themeBloc, user: userBloc),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Phone & email'), 500);
    await tester.tap(find.text('Phone & email'));
    await tester.pumpAndSettle();

    expect(find.text('__route_phone_email__'), findsOneWidget);
  });

  testWidgets('tapping Connected accounts opens named route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: _stubNewSettingsRoutes,
        home: accountSettingsTestHarness(theme: themeBloc, user: userBloc),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Connected accounts'), 500);
    await tester.tap(find.text('Connected accounts'));
    await tester.pumpAndSettle();

    expect(find.text('__route_connected_accounts__'), findsOneWidget);
  });

  testWidgets('tapping Email notifications opens named route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: _stubNewSettingsRoutes,
        home: accountSettingsTestHarness(theme: themeBloc, user: userBloc),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Email notifications'), 500);
    await tester.tap(find.text('Email notifications'));
    await tester.pumpAndSettle();

    expect(find.text('__route_email_notifications__'), findsOneWidget);
  });

  testWidgets('tapping Download my data opens named route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: _stubNewSettingsRoutes,
        home: accountSettingsTestHarness(theme: themeBloc, user: userBloc),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Download my data'), 500);
    await tester.tap(find.text('Download my data'));
    await tester.pumpAndSettle();

    expect(find.text('__route_download_my_data__'), findsOneWidget);
  });

  testWidgets('premium user sees Change plan in Subscription section',
      (tester) async {
    final UserModel premiumUser = UserModel(
      id: 'u1',
      name: 'Test',
      isPremium: true,
      subscriptionPlanId: 'monthly_premium',
    );
    when(() => userBloc.state).thenReturn(UserLoaded(premiumUser));
    when(() => userBloc.currentUser).thenReturn(premiumUser);
    when(() => userBloc.stream).thenAnswer(
      (_) => Stream<UserState>.value(UserLoaded(premiumUser)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: accountSettingsTestHarness(theme: themeBloc, user: userBloc),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Change plan'), 500);
    expect(find.text('Change plan'), findsOneWidget);
  });
}
