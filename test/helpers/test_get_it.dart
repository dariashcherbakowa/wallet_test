import 'package:get_it/get_it.dart';

Future<T> testWithGetIt<T>(Future<T> Function() body) async {
  final local = GetIt.instance;

  await local.reset();

  try {
    return await body();
  } finally {
    await local.reset();
  }
}
