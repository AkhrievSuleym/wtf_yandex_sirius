import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
    if (diff.inHours < 24) return '${diff.inHours} ч. назад';
    if (diff.inDays < 7) return '${diff.inDays} дн. назад';

    return DateFormat('d MMM', 'ru').format(date);
  }

  static String full(DateTime date) {
    return DateFormat('d MMMM yyyy, HH:mm', 'ru').format(date);
  }

  static String short(DateTime date) {
    return DateFormat('d MMM', 'ru').format(date);
  }
}
