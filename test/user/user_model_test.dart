import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/models/user_model.dart';

void main() {
  test('toString summarizes key fields', () {
    const id = '42';
    const name = 'Alice';
    const age = 30;
    const phone = '555';
    final user = UserModel(id: id, name: name, age: age, phoneNumber: phone);
    expect(
      user.toString(),
      'UserModel{id: $id, name: $name, age: $age, phone: $phone}',
    );
  });
}
