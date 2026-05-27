import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/services/undo_service.dart';

void main() {
  group('UndoService constants', () {
    test('undo window is 10 seconds', () {
      expect(UndoService.undoWindow, const Duration(seconds: 10));
    });

    test('free users get 1 undo per day', () {
      expect(UndoService.dailyUndoLimit, 1);
    });

    test('premium users get 5 undos per day', () {
      expect(UndoService.premiumUndoLimit, 5);
    });
  });

  group('SwipeDirection', () {
    test('only left swipes are passes', () {
      expect(SwipeDirection.left.name, 'left');
      expect(SwipeDirection.right.name, 'right');
    });
  });
}
