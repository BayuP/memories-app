import 'package:dio/dio.dart';
import 'package:memories_app/core/constants/api_constants.dart';
import 'package:memories_app/core/network/secure_storage.dart';

class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($code): $message';

  factory ApiException.fromDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      final err = data['error'] as Map<String, dynamic>;
      return ApiException(
        code: (err['code'] as String?) ?? 'unknown',
        message: (err['message'] as String?) ?? e.message ?? 'Unknown error',
        statusCode: e.response?.statusCode,
      );
    }
    return ApiException(
      code: 'network_error',
      message: e.message ?? 'Network error',
      statusCode: e.response?.statusCode,
    );
  }
}

class ApiClient {
  ApiClient._(this._dio);

  final Dio _dio;

  static ApiClient create({String? baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_AuthInterceptor(dio));

    return ApiClient._(dio);
  }

  // Singleton instance for app-wide use
  static final ApiClient instance = ApiClient.create();

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for auth endpoints themselves
    final isAuthEndpoint =
        options.path == ApiConstants.authSignIn ||
        options.path == ApiConstants.authSignUp ||
        options.path == ApiConstants.authRefresh;

    if (!isAuthEndpoint) {
      final token = await SecureStorageService.instance.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    // Only attempt refresh on 401, not for auth endpoints, not while already refreshing
    final isAuthEndpoint =
        err.requestOptions.path == ApiConstants.authSignIn ||
        err.requestOptions.path == ApiConstants.authSignUp ||
        err.requestOptions.path == ApiConstants.authRefresh;

    if (statusCode == 401 && !isAuthEndpoint && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshToken =
            await SecureStorageService.instance.getRefreshToken();

        if (refreshToken == null) {
          await SecureStorageService.instance.clearTokens();
          _isRefreshing = false;
          handler.next(err);
          return;
        }

        // Attempt token refresh
        final refreshResponse = await _dio.post(
          ApiConstants.authRefresh,
          data: {'refresh_token': refreshToken},
          options: Options(
            headers: {'Authorization': null},
          ),
        );

        final newAccessToken =
            refreshResponse.data['access_token'] as String?;
        final newRefreshToken =
            refreshResponse.data['refresh_token'] as String?;

        if (newAccessToken != null && newRefreshToken != null) {
          await SecureStorageService.instance.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          // Retry original request with new token
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await _dio.fetch(retryOptions);
          _isRefreshing = false;
          handler.resolve(retryResponse);
          return;
        }
      } catch (_) {
        // Refresh failed — clear tokens and propagate error
        await SecureStorageService.instance.clearTokens();
      }

      _isRefreshing = false;
    }

    handler.next(err);
  }
}
