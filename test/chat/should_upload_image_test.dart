import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:naijasingles/features/chat/ui/widgets/send_message_box.dart';

void main() {
  group('shouldUploadImage', () {
    test('returns false when image is null', () {
      final result = shouldUploadImage(null);
      expect(result, isFalse);
    });

    test('returns true when image is provided', () {
      final image = XFile('path');
      final result = shouldUploadImage(image);
      expect(result, isTrue);
    });
  });
}
