import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class HttpOutcome {
  HttpOutcome(this.statusCode, [this.body = const {}]);
  final int statusCode;
  final Map<String, dynamic> body;
}

class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.outcomes);

  final List<HttpOutcome> outcomes;
  int _callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = _callCount;
    _callCount++;

    final outcome = outcomes.isEmpty
        ? HttpOutcome(500)
        : outcomes[index < outcomes.length ? index : outcomes.length - 1];

    if (outcome.statusCode >= 200 && outcome.statusCode < 300) {
      return ResponseBody.fromString(
        jsonEncode(outcome.body),
        outcome.statusCode,
        headers: const {
          'content-type': ['application/json'],
        },
      );
    }

    throw DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(
        statusCode: outcome.statusCode,
        requestOptions: options,
        data: outcome.body,
      ),
    );
  }

  @override
  void close({bool force = false}) {}

  int get calls => _callCount;
}
