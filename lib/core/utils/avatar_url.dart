import '../constants/api_constants.dart';

String? resolveAvatarUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http')) return raw;
  final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '');
  return '$base$raw';
}
