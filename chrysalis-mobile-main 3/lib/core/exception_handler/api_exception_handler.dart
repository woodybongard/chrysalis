import 'package:chrysalis_mobile/core/localization/localization.dart';
import 'package:dio/dio.dart';

class InternalServerErrorException implements Exception {
  InternalServerErrorException([this.message = 'Internal server error.']);
  final String message;

  @override
  String toString() => message;
}

class ValidationErrorException implements Exception {
  ValidationErrorException(this.statusMessage);
  final String statusMessage;

  @override
  String toString() => statusMessage;
}

class UnauthorizedException implements Exception {
  UnauthorizedException([this.message = 'Please log in to continue.']);
  final String message;

  @override
  String toString() => message;
}

class SocketErrorException implements Exception {
  SocketErrorException([
    this.message =
        'Failed to connect to internet. Please check your internet connection.',
  ]);
  final String message;

  @override
  String toString() => message;
}

class TimeoutException implements Exception {
  TimeoutException([this.message = 'Your connection has timed out.']);
  final String message;

  @override
  String toString() => message;
}

class FormatErrorException implements Exception {
  FormatErrorException([this.message = 'Something went wrong.']);
  final String message;

  @override
  String toString() => message;
}

class SlotConflictErrorException implements Exception {
  SlotConflictErrorException([this.message = 'Something went wrong.']);
  final String message;

  @override
  String toString() => message;
}

class CommonErrorException implements Exception {
  CommonErrorException([this.message = 'Something went wrong.']);
  final String message;

  @override
  String toString() => message;
}

void handleApiException(DioException e) {
  final commonErrorMsg = Translator.translateWithoutContext(
    'Something went wrong.',
  );
  final formatErrorMsg = Translator.translateWithoutContext(
    'Something went wrong.',
  );
  final internalServerErrorMsg = Translator.translateWithoutContext(
    'Internal server error.',
  );
  final socketErrorMsg = Translator.translateWithoutContext(
    'Failed to connect to internet. Please check your internet connection.',
  );
  final timeoutErrorMsg = Translator.translateWithoutContext(
    'Your connection has timed out.',
  );

  if (e.response != null) {
    final response = e.response!;
    final statusCode = response.statusCode;
    final data = response.data;

    // Handle Validation Error (422)
    if (statusCode == 422 &&
        data is Map &&
        data['errors'] != null &&
        data['errors'] is Map) {
      final errors = data['errors'] as Map<String, dynamic>;
      var statusMessage = '';

      // Concatenate all error messages into a single status message
      errors.forEach((key, value) {
        if (value is List) {
          statusMessage += "${value.join("\n")}\n";
        }
      });

      throw ValidationErrorException(statusMessage.trim());
    }

    // Handle Internal Server Error (500)
    if (statusCode == 500) {
      throw InternalServerErrorException(internalServerErrorMsg);
    }
    //409 slot for conflicts exceptions that can happen while measurement visit reservation
    if (statusCode == 409) {
      final message = data is Map && data['statusMessage'] is String
          ? data['statusMessage'] as String
          : 'Conflict occurred.';
      throw SlotConflictErrorException(message);
    }
  }

  // Handle Timeout
  if (e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.connectionTimeout) {
    throw TimeoutException(timeoutErrorMsg);
  }

  // Handle Socket Error
  if (e.type == DioExceptionType.connectionError) {
    throw SocketErrorException(socketErrorMsg);
  }

  // Handle Format Error
  if (e.type == DioExceptionType.badResponse ||
      e.type == DioExceptionType.badCertificate) {
    throw FormatErrorException(formatErrorMsg);
  }

  // Generic exception if no specific case matches
  throw CommonErrorException(commonErrorMsg);
}
