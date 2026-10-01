import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Base class for all application-specific exceptions.
abstract class AppException implements Exception {
  final String messageKey;
  final String? originalMessage;
  final StackTrace? stackTrace;

  const AppException({
    required this.messageKey,
    this.originalMessage,
    this.stackTrace,
  });

  @override
  String toString() => '$runtimeType: [$messageKey] ${originalMessage ?? ""}';

  /// Maps any caught error into a friendly, typed [AppException].
  factory AppException.from(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error;
    }

    if (error is SocketException ||
        error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('ClientException')) {
      return NetworkException(
        messageKey: 'error_network_offline',
        originalMessage: 'No internet connection',
        stackTrace: stackTrace,
      );
    }

    if (error is TimeoutException || error.toString().contains('TimeoutException')) {
      return AppTimeoutException(
        messageKey: 'error_timeout',
        originalMessage: 'Request timed out',
        stackTrace: stackTrace,
      );
    }

    if (error is AuthException) {
      return AppAuthException(
        messageKey: _mapAuthErrorKey(error.message),
        originalMessage: error.message,
        stackTrace: stackTrace,
      );
    }

    if (error is PostgrestException) {
      return DatabaseException(
        messageKey: 'error_database',
        originalMessage: error.message,
        code: error.code,
        stackTrace: stackTrace,
      );
    }

    if (error is FunctionException) {
      return DatabaseException(
        messageKey: 'error_edge_function',
        originalMessage: error.reasonPhrase ?? 'Function execution error',
        stackTrace: stackTrace,
      );
    }

    return UnknownException(
      messageKey: 'error_unknown',
      originalMessage: error.toString(),
      stackTrace: stackTrace,
    );
  }

  static String _mapAuthErrorKey(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
      return 'error_auth_invalid_credentials';
    }
    if (msg.contains('user not found')) {
      return 'error_auth_user_not_found';
    }
    if (msg.contains('already registered') || msg.contains('user_already_exists')) {
      return 'error_auth_user_exists';
    }
    return 'error_auth_general';
  }
}

class NetworkException extends AppException {
  const NetworkException({
    super.messageKey = 'error_network_offline',
    super.originalMessage,
    super.stackTrace,
  });
}

class AppTimeoutException extends AppException {
  const AppTimeoutException({
    super.messageKey = 'error_timeout',
    super.originalMessage,
    super.stackTrace,
  });
}

class AppAuthException extends AppException {
  const AppAuthException({
    required super.messageKey,
    super.originalMessage,
    super.stackTrace,
  });
}

class DatabaseException extends AppException {
  final String? code;

  const DatabaseException({
    super.messageKey = 'error_database',
    super.originalMessage,
    this.code,
    super.stackTrace,
  });
}

class UnknownException extends AppException {
  const UnknownException({
    super.messageKey = 'error_unknown',
    super.originalMessage,
    super.stackTrace,
  });
}

/// A lightweight, privacy-focused logger that redacts tokens and phone numbers.
class AppLogger {
  AppLogger._();

  static final RegExp _jwtRegex = RegExp(r'eyJ[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*');
  static final RegExp _bearerRegex = RegExp(r'Bearer\s+[A-Za-z0-9-_=.]+', caseSensitive: false);
  static final RegExp _phoneRegex = RegExp(r'(\+91[\-\s]?)?[6-9]\d{9}');
  static final RegExp _secretRegex = RegExp(
    r'(password|token|secret|key)[:=]\s*\S+',
    caseSensitive: false,
  );

  /// Sanitize text by replacing tokens, phone numbers, and secrets with [REDACTED].
  static String sanitize(String text) {
    var result = text;
    result = result.replaceAll(_jwtRegex, '[REDACTED_JWT]');
    result = result.replaceAll(_bearerRegex, 'Bearer [REDACTED_TOKEN]');
    result = result.replaceAll(_phoneRegex, '[REDACTED_PHONE]');
    result = result.replaceAllMapped(_secretRegex, (match) {
      final key = match.group(1);
      return '$key: "[REDACTED]"';
    });
    return result;
  }

  static void i(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] ${sanitize(message)}');
    }
  }

  static void w(String message) {
    if (kDebugMode) {
      debugPrint('[WARN] ${sanitize(message)}');
    }
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      final sanitizedMsg = sanitize(message);
      final sanitizedErr = error != null ? sanitize(error.toString()) : '';
      debugPrint('[ERROR] $sanitizedMsg ${sanitizedErr.isNotEmpty ? "-> $sanitizedErr" : ""}');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}
