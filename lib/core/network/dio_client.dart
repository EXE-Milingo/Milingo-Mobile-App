import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:milingo/core/constants/app_constants.dart';

part 'dio_client.g.dart';

/// Dio HTTP client provider for API communication
/// Primarily used for PayOS payment integration
@riverpod
Dio dioClient(DioClientRef ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.payOSBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'x-client-id': AppConstants.payOSClientId,
        'x-api-key': AppConstants.payOSApiKey,
      },
    ),
  );

  // Add interceptors for logging and error handling
  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (object) {
        // TODO: Replace with proper logging in production
        print('[DIO] $object');
      },
    ),
  );

  // Add error handling interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        // Handle common HTTP errors
        final statusCode = error.response?.statusCode;
        String errorMessage = 'An error occurred';

        switch (statusCode) {
          case 400:
            errorMessage = 'Bad request';
            break;
          case 401:
            errorMessage = 'Unauthorized';
            break;
          case 403:
            errorMessage = 'Forbidden';
            break;
          case 404:
            errorMessage = 'Not found';
            break;
          case 500:
            errorMessage = 'Internal server error';
            break;
        }

        // TODO: Implement centralized error handling
        print('[DIO ERROR] $errorMessage: ${error.message}');

        return handler.next(error);
      },
    ),
  );

  return dio;
}
