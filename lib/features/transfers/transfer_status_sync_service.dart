import 'dart:async';
import 'package:dio/dio.dart';
import 'package:wallet_test/core/errors/app_exception.dart';
import 'package:wallet_test/core/network/api_client.dart';
import 'package:wallet_test/features/transfers/transfer.dart';
import 'package:wallet_test/features/transfers/transfer_repository.dart';

class TransferStatusSyncService {
  TransferStatusSyncService({
    required ApiClient api,
    required ITransferRepository repository,
  })  : _api = api,
        _repository = repository;

  final ApiClient _api;
  final ITransferRepository _repository;

  Future<TransferStatus> sync(
    Transfer transfer, {
    CancelToken? cancelToken,
  }) async {
    int attempt = 0;
    const maxAttempts = 3;
    final delays = [
      Duration.zero,
      const Duration(milliseconds: 200),
      const Duration(milliseconds: 500),
    ];

    while (attempt < maxAttempts) {
      if (cancelToken?.isCancelled == true) {
        throw const CancelException();
      }

      try {
        final response = await _api.dio.get(
          '/v1/transfers/${transfer.txHash}/status',
          cancelToken: cancelToken,
          options: Options(
            headers: {
              'Idempotency-Key':
                  '${transfer.network.toLowerCase()}:${transfer.txHash}',
            },
          ),
        );

        final status = TransferStatus.fromName(
          response.data['status'] as String? ?? 'unknown',
        );

        try {
          await _repository.applyStatus(
            transfer,
            status,
            DateTime.now(),
          );
        } catch (_) {
          throw const TransferSyncException(code: 'localPersistenceFailed');
        }

        return status;
      } on DioException catch (e) {
        if (cancelToken?.isCancelled == true) {
          throw const CancelException();
        }

        final shouldRetry = _shouldRetry(e);
        if (!shouldRetry || attempt >= maxAttempts - 1) {
          throw _mapError(e);
        }

        attempt++;
        await Future.delayed(delays[attempt]);
      } catch (e) {
        if (e is CancelException) rethrow;
        rethrow;
      }
    }

    throw const TransferSyncException(code: 'network');
  }

  bool _shouldRetry(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      return false;
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return true;
    }

    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      return statusCode == 408 || statusCode == 429 || statusCode == 503;
    }

    return false;
  }

  TransferSyncException _mapError(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      return const TransferSyncException(code: 'cancelled');
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const TransferSyncException(code: 'network');
    }

    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      switch (statusCode) {
        case 401:
          return const TransferSyncException(code: 'unauthorized');
        case 404:
          return const TransferSyncException(code: 'notFound');
        case 409:
          return const TransferSyncException(code: 'conflict');
        case 408:
        case 429:
          return const TransferSyncException(code: 'rateLimited');
        case 503:
          return const TransferSyncException(code: 'serverUnavailable');
        case 500:
          return const TransferSyncException(code: 'internal');
        default:
          return TransferSyncException(code: 'http_$statusCode');
      }
    }

    return const TransferSyncException(code: 'network');
  }
}
