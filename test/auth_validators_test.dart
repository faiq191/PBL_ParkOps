import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_parkops/features/auth/domain/auth_validators.dart';

void main() {
  group('username', () {
    test('empty is rejected', () {
      expect(AuthValidators.username(''), isNotNull);
      expect(AuthValidators.username(null), isNotNull);
    });
    test('boundaries 2 / 3 / 20 / 21 characters', () {
      expect(AuthValidators.username('ab'), isNotNull);
      expect(AuthValidators.username('abc'), isNull);
      expect(AuthValidators.username('a' * 20), isNull);
      expect(AuthValidators.username('a' * 21), isNotNull);
    });
    test('illegal characters are rejected', () {
      expect(AuthValidators.username('new user'), isNotNull);
      expect(AuthValidators.username('new-user'), isNotNull);
      expect(AuthValidators.username('new_user1'), isNull);
    });
  });

  group('email', () {
    test('empty and malformed are rejected', () {
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email('new_user@'), isNotNull);
      expect(AuthValidators.email('new_user.mail.com'), isNotNull);
      expect(AuthValidators.email('a b@mail.com'), isNotNull);
    });
    test('valid email passes, surrounding spaces ignored', () {
      expect(AuthValidators.email('new_user@mail.com'), isNull);
      expect(AuthValidators.email('  new_user@mail.com  '), isNull);
    });
  });

  group('password', () {
    test('boundary 7 / 8 characters', () {
      expect(AuthValidators.password('Abcd#12'), isNotNull);
      expect(AuthValidators.password('Abcd#123'), isNull);
    });
    test('empty is rejected', () {
      expect(AuthValidators.password(''), isNotNull);
    });
    test('login only requires a non-empty password', () {
      expect(AuthValidators.loginPassword(''), isNotNull);
      expect(AuthValidators.loginPassword('x'), isNull);
    });
  });

  group('confirm password', () {
    test('empty and mismatch are rejected', () {
      expect(AuthValidators.confirmPassword('', 'Passw0rd!'), isNotNull);
      expect(
          AuthValidators.confirmPassword('Passw0rd?', 'Passw0rd!'), isNotNull);
    });
    test('matching passes', () {
      expect(AuthValidators.confirmPassword('Passw0rd!', 'Passw0rd!'), isNull);
    });
  });
}