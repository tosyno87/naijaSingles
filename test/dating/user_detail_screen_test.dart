import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/dating/screens/user_detail_screen.dart';
import 'package:naijasingles/models/user_model.dart';

void main() {
  testWidgets('matched conversation profile hides like actions',
      (tester) async {
    final user = UserModel(
      id: 'matched-user',
      name: 'Phone User',
      age: 18,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: UserDetailScreen(
          user: user,
          showLikeActions: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Like'), findsNothing);
    expect(find.text('Liked'), findsNothing);
    expect(find.text('Back'), findsNothing);
    expect(find.text('Dating'), findsNothing);
    expect(find.text('Music'), findsNothing);
    expect(find.text('Travel'), findsNothing);
    expect(find.text('Phone User, 18'), findsOneWidget);
  });
}
