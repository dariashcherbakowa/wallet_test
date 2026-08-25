import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_test/features/router/cards_auth_redirect.dart';

void main() {
  group('cardsAuthRedirect', () {
    test('не авторизован, /cards/card_1/issue?step=2 → /onboarding с next', () {
      final result = cardsAuthRedirect(
        Uri.parse('/cards/card_1/issue?step=2'),
        false,
      );
      expect(
        result,
        '/onboarding?next=%2Fcards%2Fcard_1%2Fissue%3Fstep%3D2',
      );
    });

    test('авторизован, /onboarding с next → редирект на /cards/card_1/issue',
        () {
      final result = cardsAuthRedirect(
        Uri.parse('/onboarding?next=%2Fcards%2Fcard_1%2Fissue%3Fstep%3D2'),
        true,
      );
      expect(result, '/cards/card_1/issue?step=2');
    });

    test('авторизован, /onboarding с unsafe next → /cards', () {
      final result = cardsAuthRedirect(
        Uri.parse('/onboarding?next=https%3A%2F%2Fevil.com'),
        true,
      );
      expect(result, '/cards');
    });

    test('не авторизован, /onboarding → null', () {
      final result = cardsAuthRedirect(
        Uri.parse('/onboarding'),
        false,
      );
      expect(result, isNull);
    });

    test('авторизован, /cards → null', () {
      final result = cardsAuthRedirect(
        Uri.parse('/cards'),
        true,
      );
      expect(result, isNull);
    });

    test('авторизован, /onboarding без next → /cards', () {
      final result = cardsAuthRedirect(
        Uri.parse('/onboarding'),
        true,
      );
      expect(result, '/cards');
    });

    test('не авторизован, /cards → /onboarding с next', () {
      final result = cardsAuthRedirect(
        Uri.parse('/cards'),
        false,
      );
      expect(result, '/onboarding?next=%2Fcards');
    });
  });
}
