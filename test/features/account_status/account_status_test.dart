import 'package:flutter_test/flutter_test.dart';

import 'package:naijasingles/models/user_model.dart';
import 'package:naijasingles/features/account_status/presentation/bloc/account_status_event.dart';
import 'package:naijasingles/features/account_status/presentation/bloc/account_status_state.dart';
import 'package:naijasingles/features/account_status/data/services/account_status_service.dart';

void main() {
  // ─── UserModel.isDiscoverable tests ─────────────────────────────
  group('UserModel account status helpers', () {
    UserModel _user({String? accountStatus}) => UserModel(
          id: 'u1',
          name: 'Test',
          accountStatus: accountStatus,
        );

    test('null accountStatus defaults to discoverable', () {
      final user = _user();
      expect(user.isDiscoverable, isTrue);
      expect(user.isDeactivated, isFalse);
      expect(user.isIncognito, isFalse);
      expect(user.isPaused, isFalse);
    });

    test('active status is discoverable', () {
      final user = _user(accountStatus: 'active');
      expect(user.isDiscoverable, isTrue);
      expect(user.isDeactivated, isFalse);
    });

    test('paused status is NOT discoverable', () {
      final user = _user(accountStatus: 'paused');
      expect(user.isDiscoverable, isFalse);
      expect(user.isDeactivated, isTrue);
      expect(user.isPaused, isTrue);
      expect(user.isIncognito, isFalse);
    });

    test('incognito status is NOT discoverable', () {
      final user = _user(accountStatus: 'incognito');
      expect(user.isDiscoverable, isFalse);
      expect(user.isDeactivated, isTrue);
      expect(user.isIncognito, isTrue);
      expect(user.isPaused, isFalse);
    });

    test('deleted status is NOT discoverable', () {
      final user = _user(accountStatus: 'deleted');
      expect(user.isDiscoverable, isFalse);
    });

    test('banned status is NOT discoverable', () {
      final user = _user(accountStatus: 'banned');
      expect(user.isDiscoverable, isFalse);
    });
  });

  // ─── UserModel serialization round-trip ─────────────────────────
  group('UserModel accountStatus serialization', () {
    test('toMap includes accountStatus', () {
      final user = UserModel(id: 'u1', name: 'Test', accountStatus: 'paused');
      final map = user.toMap();
      expect(map['accountStatus'], 'paused');
    });

    test('fromJson parses accountStatus', () {
      final user = UserModel.fromJson({
        'id': 'u1',
        'name': 'Test',
        'accountStatus': 'incognito',
      });
      expect(user.accountStatus, 'incognito');
      expect(user.isIncognito, isTrue);
    });

    test('fromJson defaults to active when accountStatus missing', () {
      final user = UserModel.fromJson({'id': 'u1', 'name': 'Test'});
      expect(user.accountStatus, 'active');
      expect(user.isDiscoverable, isTrue);
    });

    test('fromMap parses accountStatus', () {
      final user = UserModel.fromMap(
        {'name': 'Test', 'accountStatus': 'paused'},
        'u1',
      );
      expect(user.accountStatus, 'paused');
      expect(user.isPaused, isTrue);
    });
  });

  // ─── AccountStatusService constants ────────────────────────────
  group('AccountStatusService', () {
    test('userAssignableStatuses includes active, paused, incognito', () {
      expect(
        AccountStatusService.userAssignableStatuses,
        containsAll(['active', 'paused', 'incognito']),
      );
    });

    test('userAssignableStatuses excludes deleted and banned', () {
      expect(
        AccountStatusService.userAssignableStatuses,
        isNot(contains('deleted')),
      );
      expect(
        AccountStatusService.userAssignableStatuses,
        isNot(contains('banned')),
      );
    });
  });

  // ─── AccountStatusState helpers ────────────────────────────────
  group('AccountStatusState', () {
    test('AccountStatusLoaded.isActive is true for active', () {
      const state = AccountStatusLoaded('active');
      expect(state.isActive, isTrue);
      expect(state.isPaused, isFalse);
      expect(state.isIncognito, isFalse);
      expect(state.isDeactivated, isFalse);
    });

    test('AccountStatusLoaded.isPaused is true for paused', () {
      const state = AccountStatusLoaded('paused');
      expect(state.isActive, isFalse);
      expect(state.isPaused, isTrue);
      expect(state.isDeactivated, isTrue);
    });

    test('AccountStatusLoaded.isIncognito is true for incognito', () {
      const state = AccountStatusLoaded('incognito');
      expect(state.isActive, isFalse);
      expect(state.isIncognito, isTrue);
      expect(state.isDeactivated, isTrue);
    });
  });

  // ─── AccountStatusEvent types ──────────────────────────────────
  group('AccountStatusEvent', () {
    test('PauseAccount carries userId and optional reason', () {
      const event = PauseAccount(userId: 'u1', reason: 'need a break');
      expect(event.userId, 'u1');
      expect(event.reason, 'need a break');
    });

    test('EnableIncognito carries userId', () {
      const event = EnableIncognito(userId: 'u1');
      expect(event.userId, 'u1');
      expect(event.reason, isNull);
    });

    test('ReactivateAccount carries userId', () {
      const event = ReactivateAccount(userId: 'u1');
      expect(event.userId, 'u1');
    });

    test('LoadAccountStatus carries userId', () {
      const event = LoadAccountStatus('u1');
      expect(event.userId, 'u1');
    });
  });
}
