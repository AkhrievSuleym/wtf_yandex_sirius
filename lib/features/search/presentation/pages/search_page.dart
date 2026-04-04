import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../cubits/search_cubit.dart';
import '../cubits/search_state.dart';
import '../widgets/search_history_list.dart';
import '../widgets/search_result_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<SearchCubit>().loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _navigateToProfile(BuildContext context, String uid) {
    context.push('/search/$uid');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _SearchBar(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (q) => context.read<SearchCubit>().onQueryChanged(q),
          onClear: () {
            _controller.clear();
            context.read<SearchCubit>().loadHistory();
          },
        ),
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          return switch (state) {
            SearchInitial(:final history) => SearchHistoryList(
                items: history,
                onItemTap: (item) {
                  if (item.viewedUid != null) {
                    _navigateToProfile(context, item.viewedUid!);
                  }
                },
                onClear: () => context.read<SearchCubit>().clearHistory(),
              ),
            SearchLoading() => const SearchShimmer(),
            SearchEmpty(:final query) => _EmptyResults(query: query),
            SearchResults(:final results) => ListView.builder(
                itemCount: results.length,
                itemBuilder: (_, i) {
                  final profile = results[i];
                  return SearchResultTile(
                    profile: profile,
                    onTap: () {
                      context.read<SearchCubit>().addProfileToHistory(profile);
                      _navigateToProfile(context, profile.uid);
                    },
                  )
                      .animate(delay: Duration(milliseconds: 40 * i))
                      .fadeIn(duration: 200.ms)
                      .slideX(begin: 0.05, end: 0, duration: 200.ms);
                },
              ),
            SearchError(:final message) => AppErrorWidget(
                message: message,
                onRetry: () => context
                    .read<SearchCubit>()
                    .onQueryChanged(_controller.text),
              ),
          };
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Поиск по никнейму...',
        prefixIcon:
            const Icon(Icons.search, color: AppColors.textSecondaryLight),
        suffixIcon: ValueListenableBuilder(
          valueListenable: controller,
          builder: (_, value, __) => value.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                )
              : const SizedBox.shrink(),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;
  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Никого не найдено',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'По запросу «$query» ничего не найдено.\nПроверьте никнейм.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
