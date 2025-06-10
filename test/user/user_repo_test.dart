import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/common/data/repo/user_repo.dart';
import 'package:naijasingles/models/user_model.dart';

void main() {
  group('UserRepo.chatId1', () {
    test('orders ids alphabetically when hashCode is lower', () {
      final currentUser = UserModel(id: 'a');
      final chatId = UserRepo.chatId1(currentUser, 'b');
      expect(chatId, 'a-b');
    });

    test('orders ids alphabetically when hashCode is higher', () {
      final currentUser = UserModel(id: 'b');
      final chatId = UserRepo.chatId1(currentUser, 'a');
      expect(chatId, 'a-b');
    });
  });
}
