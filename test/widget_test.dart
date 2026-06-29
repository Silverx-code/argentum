// Basic smoke test for Argentum AI app.
import 'package:flutter_test/flutter_test.dart';
import 'package:argentum/utils/validators.dart';
import 'package:argentum/utils/routes.dart';

void main() {
  test('Email validator works correctly', () {
    expect(Validators.email('test@example.com'), isNull);
    expect(Validators.email('invalid'), isNotNull);
    expect(Validators.email(''), isNotNull);
  });

  test('Password validator works correctly', () {
    expect(Validators.password('password123'), isNull);
    expect(Validators.password('short'), isNotNull);
    expect(Validators.password(''), isNotNull);
  });

  test('AppRoutes constants are defined', () {
    expect(AppRoutes.home, '/home');
    expect(AppRoutes.signIn, '/signin');
    expect(AppRoutes.quiz, '/quiz');
  });
}
