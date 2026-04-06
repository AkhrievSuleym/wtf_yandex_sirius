import 'dart:io';

import 'package:dio/dio.dart';

String formatError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Превышено время ожидания. Проверьте соединение.';
      case DioExceptionType.connectionError:
        return 'Нет подключения к интернету.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 401) return 'Сессия истекла. Войдите снова.';
        if (status == 403) return 'Нет доступа.';
        if (status == 404) return 'Не найдено.';
        if (status != null && status >= 500) {
          return 'Ошибка сервера. Попробуйте позже.';
        }
        return 'Что-то пошло не так. Попробуйте ещё раз.';
      case DioExceptionType.cancel:
        return 'Запрос отменён.';
      case DioExceptionType.badCertificate:
        return 'Ошибка безопасного соединения.';
      case DioExceptionType.unknown:
        final inner = error.error;
        if (inner is SocketException || inner is HttpException) {
          return 'Нет подключения к интернету.';
        }
        return 'Нет подключения к интернету.';
    }
  }

  if (error is SocketException || error is HttpException) {
    return 'Нет подключения к интернету.';
  }

  final msg = error.toString();
  if (msg.startsWith('Exception: ')) {
    return msg.replaceFirst('Exception: ', '');
  }

  return 'Что-то пошло не так. Попробуйте ещё раз.';
}
