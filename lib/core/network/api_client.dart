import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import 'auth_expiration_bus.dart';

class ApiClient {
  ApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          headers: {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await FirebaseAuth.instance.currentUser?.getIdToken();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await FirebaseAuth.instance.signOut();
            AuthExpirationBus.notify();
          }
          handler.next(error);
        },
      ),
    );
  }
  final Dio dio;

  static AppException mapError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout)
        return const AppException('The request timed out. Please try again.');
      final data = error.response?.data;
      final details = data is Map ? data['error'] : null;
      final message = details is Map
          ? details['message']?.toString()
          : data is Map
          ? data['message']?.toString()
          : null;
      return AppException(
        message ?? 'Unable to reach SafeRide-LK. Check your connection.',
        statusCode: error.response?.statusCode,
      );
    }
    return const AppException('Something went wrong. Please try again.');
  }
}
