import '../constants/app_constants.dart';

class Validators {
  Validators._();

  static String? username(String? value) {
    if (value == null || value.isEmpty) return 'Введите никнейм';
    if (value.length < AppConstants.usernameMinLength) {
      return 'Минимум ${AppConstants.usernameMinLength} символа';
    }
    if (value.length > AppConstants.usernameMaxLength) {
      return 'Максимум ${AppConstants.usernameMaxLength} символов';
    }
    final regex = RegExp(AppConstants.usernamePattern);
    if (!regex.hasMatch(value)) {
      return 'Только a-z, 0-9 и _ (без заглавных букв)';
    }
    return null;
  }

  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите имя';
    if (value.trim().length > AppConstants.displayNameMaxLength) {
      return 'Максимум ${AppConstants.displayNameMaxLength} символов';
    }
    return null;
  }

  static String? bio(String? value) {
    if (value != null && value.length > AppConstants.bioMaxLength) {
      return 'Максимум ${AppConstants.bioMaxLength} символов';
    }
    return null;
  }

  static String? comment(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите сообщение';
    if (value.length > AppConstants.commentMaxLength) {
      return 'Максимум ${AppConstants.commentMaxLength} символов';
    }
    return null;
  }
}
