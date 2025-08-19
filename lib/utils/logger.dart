import 'package:flutter/foundation.dart';

/// Système de logging simple pour remplacer les print statements
class Logger {
  static const String _prefix = '[ILIUM]';
  
  /// Callback optionnel pour capturer les logs
  static void Function(String)? onLog;
  
  /// Log d'information
  static void info(String message) {
    final fullMessage = '$_prefix INFO: $message';
    if (kDebugMode) {
      debugPrint(fullMessage);
    }
    onLog?.call(fullMessage);
  }
  
  /// Log d'erreur
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    final fullMessage = '$_prefix ERROR: $message';
    if (kDebugMode) {
      debugPrint(fullMessage);
      if (error != null) {
        debugPrint('$_prefix ERROR Details: $error');
      }
      if (stackTrace != null) {
        debugPrint('$_prefix STACK TRACE: $stackTrace');
      }
    }
    onLog?.call(fullMessage);
    if (error != null) {
      onLog?.call('$_prefix ERROR Details: $error');
    }
  }
  
  /// Log de debug
  static void debug(String message) {
    final fullMessage = '$_prefix DEBUG: $message';
    if (kDebugMode) {
      debugPrint(fullMessage);
    }
    onLog?.call(fullMessage);
  }
  
  /// Log de warning
  static void warning(String message) {
    final fullMessage = '$_prefix WARNING: $message';
    if (kDebugMode) {
      debugPrint(fullMessage);
    }
    onLog?.call(fullMessage);
  }
}