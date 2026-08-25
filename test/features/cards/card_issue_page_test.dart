import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:wallet_test/core/dev_stubs/dev_card_issuer.dart';
import 'package:wallet_test/core/di/get_it_injector.dart';
import 'package:wallet_test/features/cards/card_issue_page.dart';
import 'package:wallet_test/features/cards/card_issuer.dart';

void main() {
  group('CardIssuePage', () {
    late DevCardIssuer issuer;

    setUp(() {
      GetIt.instance.reset();
      registerAppDependencies();

      issuer = GetIt.instance<ICardIssuer>() as DevCardIssuer;
      issuer.cancelCalls = 0;
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    testWidgets('страница рендерится', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Issue card'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('при dispose: cancelPending() вызван ровно 1 раз',
        (tester) async {
      issuer.cancelCalls = 0;

      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(issuer.cancelCalls, 1);
    });
  });
}
