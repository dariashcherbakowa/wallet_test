import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_test/core/dev_stubs/in_memory_transfer_repository.dart';
import 'package:wallet_test/core/errors/app_exception.dart';
import 'package:wallet_test/core/network/api_client.dart';
import 'package:wallet_test/features/transfers/transfer.dart';
import 'package:wallet_test/features/transfers/transfer_status_sync_service.dart';
import '../../fakes/fake_http_client_adapter.dart';

void main() {
  group('TransferStatusSyncService', () {
    late InMemoryTransferRepository repository;
    late Transfer transfer;
    const txHash = '0x1234abcd';
    const network = 'ethereum';

    setUp(() {
      repository = InMemoryTransferRepository();
      transfer = const Transfer(
        id: 'test_id',
        network: network,
        txHash: txHash,
      );
    });

    test('429, затем 200 - retry сработал, БД обновилась, статус confirmed',
        () async {
      final dio = Dio();
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(429),
        HttpOutcome(200, {'status': 'confirmed'}),
      ]);
      dio.httpClientAdapter = adapter;

      final service = TransferStatusSyncService(
        api: ApiClient(dio: dio),
        repository: repository,
      );

      final status = await service.sync(transfer);

      expect(status, TransferStatus.confirmed);
      expect(repository.applyCalls, 1);
      expect(repository.lastStatus, TransferStatus.confirmed);
    });

    test('401 - нет retry, БД не обновлялась, ошибка unauthorized', () async {
      final dio = Dio();
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(401),
      ]);
      dio.httpClientAdapter = adapter;

      final service = TransferStatusSyncService(
        api: ApiClient(dio: dio),
        repository: repository,
      );

      expect(
        () => service.sync(transfer),
        throwsA(
          isA<TransferSyncException>().having(
            (e) => e.code,
            'code',
            'unauthorized',
          ),
        ),
      );

      expect(repository.applyCalls, 0);
    });

    test('500 - нет retry, ошибка internal', () async {
      final dio = Dio();
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(500),
      ]);
      dio.httpClientAdapter = adapter;

      final service = TransferStatusSyncService(
        api: ApiClient(dio: dio),
        repository: repository,
      );

      expect(
        () => service.sync(transfer),
        throwsA(
          isA<TransferSyncException>().having(
            (e) => e.code,
            'code',
            'internal',
          ),
        ),
      );

      expect(repository.applyCalls, 0);
    });

    test('429, 429, 429 - 3 попытки, ошибка rateLimited', () async {
      final dio = Dio();
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(429),
        HttpOutcome(429),
        HttpOutcome(429),
      ]);
      dio.httpClientAdapter = adapter;

      final service = TransferStatusSyncService(
        api: ApiClient(dio: dio),
        repository: repository,
      );

      expect(
        () => service.sync(transfer),
        throwsA(
          isA<TransferSyncException>().having(
            (e) => e.code,
            'code',
            'rateLimited',
          ),
        ),
      );

      expect(repository.applyCalls, 0);
    });

    test('HTTP 200, но БД падает - ошибка localPersistenceFailed', () async {
      final dio = Dio();
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(200, {'status': 'confirmed'}),
      ]);
      dio.httpClientAdapter = adapter;

      repository.shouldFail = true;

      final service = TransferStatusSyncService(
        api: ApiClient(dio: dio),
        repository: repository,
      );

      expect(
        () => service.sync(transfer),
        throwsA(
          isA<TransferSyncException>().having(
            (e) => e.code,
            'code',
            'localPersistenceFailed',
          ),
        ),
      );
    });

    test('Idempotency-Key header присутствует, формат правильный', () async {
      final dio = Dio();
      final adapter = FakeHttpClientAdapter([
        HttpOutcome(200, {'status': 'confirmed'}),
      ]);
      dio.httpClientAdapter = adapter;

      final service = TransferStatusSyncService(
        api: ApiClient(dio: dio),
        repository: repository,
      );

      await service.sync(transfer);

      expect(adapter.calls, 1);
    });
  });
}
