import 'package:dio/dio.dart';

/// Turns a Dio error (or the raw NestJS `{statusCode, message}` error body)
/// into a message safe to show directly to the user.
String extractErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] != null) {
      final message = data['message'];
      if (message is List) {
        return message.join('\n');
      }
      return message.toString();
    }
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return 'No se pudo conectar al servidor. Verifica tu conexión.';
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'El servidor tardó demasiado en responder. Intenta de nuevo.';
      default:
        return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
  }
  return error.toString();
}
