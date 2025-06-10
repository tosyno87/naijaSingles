import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:naijasingles/features/auth/phone/ui/screens/login_option_page.dart';
import 'package:naijasingles/features/auth/facebook_login/facebook_login_bloc.dart';
import 'package:naijasingles/features/auth/auth_status/bloc/registration/bloc/registration_bloc.dart';
import 'package:naijasingles/common/providers/theme_provider.dart';
import 'package:naijasingles/common/providers/user_provider.dart';
import 'package:naijasingles/common/data/repo/phone_auth_repo.dart';

void main() {
  testWidgets('shows phone number login button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => FacebookLoginBloc()),
            BlocProvider(
              create: (_) => RegistrationBloc(
                phoneAuthRepository: PhoneAuthRepository(),
              ),
            ),
          ],
          child: const MaterialApp(
            home: LoginOption(),
          ),
        ),
      ),
    );

    expect(find.text('LOG IN WITH PHONE NUMBER'), findsOneWidget);
  });
}
