import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// This interceptor is used to show request and response logs
class LoggerInterceptor extends Interceptor {
  Logger logger = Logger(printer: PrettyPrinter(methodCount: 0));

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    loggerOnError(err);
    handler.next(err);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestPath = '${options.baseUrl}${options.path}';

    logger
      ..i('${options.method} request ==> $requestPath') //Info log
      ..d('Data: ${options.data}'); // Debug log
    handler.next(options); // continue with the Request
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    logger.d(
      'STATUSCODE: ${response.statusCode} \n '
      'STATUSMESSAGE: ${response.statusMessage} \n'
      'HEADERS: ${response.headers} \n'
      'Data: ${response.data}',
    ); // Debug log
    handler.next(response); // continue with the Response
  }
}

void loggerOnError(DioException err) {
  final logger = Logger(printer: PrettyPrinter(methodCount: 0));
  final options = err.requestOptions;
  final requestPath = '${options.baseUrl}${options.path}';

  // Log request details
  logger
    ..e('${options.method} request was ==> $requestPath') // Error log
    ..d('Request Data: ${options.data}')
    // Log error details
    ..e('Error type: ${err.type}')
    ..e('Error message: ${err.message}');

  // Check if there's a response from the server
  if (err.response != null) {
    logger
      ..e('STATUS CODE: ${err.response?.statusCode}')
      ..e('STATUS MESSAGE: ${err.response?.statusMessage}')
      ..d('RESPONSE DATA: ${err.response?.data}')
      ..d('RESPONSE HEADERS: ${err.response?.headers}');
  } else {
    logger.e('No response received from the server.');
  }
}
