import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/beon_config.dart';

/// HTTP client for Beon API communication
class BeonApiClient {
  late final Dio _dio;
  final BeonConfig config;
  String? _visitorId;

  BeonApiClient(this.config) {
    _dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    // _dio.interceptors.add(PrettyDioLogger(
    //     requestHeader: true,
    //     requestBody: true,
    //     responseBody: true,
    //     responseHeader: false,
    //     error: true,
    //     compact: true,
    //     maxWidth: 90));
    _dio.interceptors.addAll([
      _AuthInterceptor(config.apiKey, () => _visitorId),
      // _LoggingInterceptor(),
      _RetryInterceptor(),
    ]);
  }

  /// Set visitor ID for requests
  void setVisitorId(String id) {
    _visitorId = id;
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Upload file
  Future<Response<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fileName,
    Map<String, dynamic>? extraData,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      if (extraData != null) ...extraData,
    });

    return _dio.post<T>(
      path,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
  }

  /// Close the client
  void close() {
    _dio.close();
  }
}

/// Interceptor for adding authentication headers
class _AuthInterceptor extends Interceptor {
  final String apiKey;
  final String? Function() getVisitorId;

  _AuthInterceptor(this.apiKey, this.getVisitorId);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Api-Key'] = apiKey;
    options.headers['Authorization'] = 'Bearer $apiKey';

    final visitorId = getVisitorId();
    if (visitorId != null) {
      options.headers['X-Visitor-Id'] = visitorId;
    }

    handler.next(options);
  }
}

/// Interceptor for logging requests and responses
// class _LoggingInterceptor extends Interceptor {
//   @override
//   void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
//     print('══════════════════════════════════════════════════════════════');
//     print('REQUEST[${options.method}] => ${options.uri}');
//     print('Headers: ${options.headers}');
//     if (options.data != null) {
//       print('Body: ${options.data}');
//     }
//     print('══════════════════════════════════════════════════════════════');
//     handler.next(options);
//   }
//
//   @override
//   void onResponse(Response response, ResponseInterceptorHandler handler) {
//     print('══════════════════════════════════════════════════════════════');
//     print('RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}');
//     print('Data: ${response.data}');
//     print('══════════════════════════════════════════════════════════════');
//     handler.next(response);
//   }
//
//   @override
//   void onError(DioException err, ErrorInterceptorHandler handler) {
//     print('══════════════════════════════════════════════════════════════');
//     print('ERROR[${err.response?.statusCode}] => ${err.requestOptions.uri}');
//     print('Message: ${err.message}');
//     print('Response: ${err.response?.data}');
//     print('══════════════════════════════════════════════════════════════');
//     handler.next(err);
//   }
// }

/// Interceptor for retrying failed requests
class _RetryInterceptor extends Interceptor {
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 1);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final retryCount = requestOptions.extra['retryCount'] ?? 0;

    // Only retry on network errors or 5xx errors
    final shouldRetry = (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.receiveTimeout ||
            (err.response?.statusCode ?? 0) >= 500) &&
        retryCount < _maxRetries;

    if (shouldRetry) {
      await Future.delayed(_retryDelay * (retryCount + 1));
      requestOptions.extra['retryCount'] = retryCount + 1;

      try {
        final response = await Dio().fetch(requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // Fall through to handler.next
      }
    }

    handler.next(err);
  }
}

/// Custom exception for API errors
class BeonApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  BeonApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory BeonApiException.fromDioError(DioException error) {
    String message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please try again.';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection.';
        break;
      case DioExceptionType.badResponse:
        message = error.response?.data?['message'] ?? 'Server error occurred.';
        break;
      default:
        message = 'An unexpected error occurred.';
    }

    return BeonApiException(
      message: message,
      statusCode: error.response?.statusCode,
      data: error.response?.data,
    );
  }

  @override
  String toString() => 'BeonApiException: $message (status: $statusCode)';
}
