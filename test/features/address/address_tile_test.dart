import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:wallet_test/core/dev_stubs/in_memory_address_repository.dart';
import 'package:wallet_test/features/address/address_repository.dart';
import 'package:wallet_test/features/address/address_tile.dart';
import 'package:wallet_test/features/address/address_tile_bloc.dart';

import '../../helpers/test_get_it.dart';

void main() {
  group('AddressTile', () {
    const address = '0x1234567890abcdef1234567890abcdef12345678';
    const network = 'Ethereum';

    ({InMemoryAddressRepository repository, AddressTileBloc bloc})
        overrideDependencies() {
      final repository = InMemoryAddressRepository();

      if (GetIt.I.isRegistered<IAddressRepository>()) {
        GetIt.I.unregister<IAddressRepository>();
      }
      GetIt.I.registerLazySingleton<IAddressRepository>(() => repository);

      if (GetIt.I.isRegistered<AddressTileBloc>()) {
        GetIt.I.unregister<AddressTileBloc>();
      }
      GetIt.I.registerLazySingleton<AddressTileBloc>(
        () => AddressTileBloc(repository: repository),
      );

      final bloc = GetIt.I<AddressTileBloc>();

      return (repository: repository, bloc: bloc);
    }

    testWidgets('виджет рендерится', (tester) async {
      await testWithGetIt(() async {
        overrideDependencies();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AddressTile(
                address: address,
                network: network,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text(network), findsOneWidget);
        expect(find.text('0x123456…5678'), findsOneWidget);
        expect(find.byIcon(Icons.copy), findsOneWidget);
      });
    });

    testWidgets('нет overflow при textScaleFactor: 2.0', (tester) async {
      await testWithGetIt(() async {
        overrideDependencies();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
                child: AddressTile(
                  address: address,
                  network: network,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('по нажатию вызывается IAddressRepository.copyAddress',
        (tester) async {
      await testWithGetIt(() async {
        final deps = overrideDependencies();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AddressTile(
                address: address,
                network: network,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final iconButton = find.byIcon(Icons.copy);
        expect(iconButton, findsOneWidget);

        await tester.tap(iconButton);
        await tester.pumpAndSettle();

        expect(deps.repository.copyCalls, 1);
        expect(deps.repository.lastAddress, address);
      });
    });

    testWidgets('при успехе показывается copied state', (tester) async {
      await testWithGetIt(() async {
        final deps = overrideDependencies();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AddressTile(
                address: address,
                network: network,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.copy), findsOneWidget);

        await tester.tap(find.byIcon(Icons.copy));
        await tester.pumpAndSettle();

        expect(deps.bloc.state.copied, isTrue);
        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.byIcon(Icons.copy), findsNothing);
      });
    });

    testWidgets('при ошибке показывается error state', (tester) async {
      await testWithGetIt(() async {
        final deps = overrideDependencies();
        deps.repository.shouldFail = true;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AddressTile(
                address: address,
                network: network,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.copy));
        await tester.pumpAndSettle();

        expect(deps.bloc.state.error, isNotNull);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });

    testWidgets('после 1500ms состояние сбрасывается', (tester) async {
      await testWithGetIt(() async {
        final deps = overrideDependencies();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AddressTile(
                address: address,
                network: network,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.copy));
        await tester.pumpAndSettle();

        expect(deps.bloc.state.copied, isTrue);

        await tester.pump(const Duration(milliseconds: 1500));
        await tester.pumpAndSettle();

        expect(deps.bloc.state.copied, isFalse);
        expect(find.byIcon(Icons.copy), findsOneWidget);
        expect(find.byIcon(Icons.check), findsNothing);
      });
    });

    testWidgets('BLoC закрыт после dispose', (tester) async {
      await testWithGetIt(() async {
        overrideDependencies();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AddressTile(
                address: address,
                network: network,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(AddressTile), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();

        expect(find.byType(AddressTile), findsNothing);
      });
    });
  });
}
