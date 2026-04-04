import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../search/repositories/search_repository.dart';

class DeepLinkPage extends StatefulWidget {
  final String username;

  const DeepLinkPage({super.key, required this.username});

  @override
  State<DeepLinkPage> createState() => _DeepLinkPageState();
}

class _DeepLinkPageState extends State<DeepLinkPage> {
  static const _tag = 'DeepLinkPage';
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    AppLogger.d(_tag, 'resolving username=${widget.username}');
    try {
      final uid =
          await getIt<SearchRepository>().resolveUsername(widget.username);
      if (!mounted) return;
      if (uid != null) {
        AppLogger.i(_tag, 'resolved uid=$uid, navigating');
        context.go('/search/$uid');
      } else {
        AppLogger.w(_tag, 'username not found: ${widget.username}');
        setState(() => _notFound = true);
      }
    } catch (e) {
      AppLogger.e(_tag, 'resolve failed', e);
      if (mounted) setState(() => _notFound = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notFound) {
      return Scaffold(
        appBar: AppBar(title: const Text('Профиль не найден')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😕', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text(
                  'Пользователь @${widget.username} не найден',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/board'),
                  child: const Text('На главную'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const Scaffold(body: LoadingIndicator());
  }
}
