import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wtf_yandex_sirius/features/profile/models/profile_model.dart';
import 'package:wtf_yandex_sirius/features/search/models/search_history_item.dart';
import 'package:wtf_yandex_sirius/features/search/presentation/cubits/search_cubit.dart';
import 'package:wtf_yandex_sirius/features/search/presentation/cubits/search_state.dart';
import 'package:wtf_yandex_sirius/features/search/repositories/search_repository.dart';

import 'search_cubit_test.mocks.dart';

@GenerateMocks([SearchRepository])
void main() {
  late MockSearchRepository mockRepo;

  const profile = ProfileModel(
    uid: 'uid1',
    username: 'alice',
    displayName: 'Alice',
    bio: '',
    commentCount: 0,
    isPublic: true,
  );

  final historyItem = SearchHistoryItem(
    query: 'alice',
    viewedUid: 'uid1',
    viewedUsername: 'alice',
    viewedDisplayName: 'Alice',
    timestamp: DateTime(2025, 1, 1),
  );

  setUp(() {
    mockRepo = MockSearchRepository();
  });

  group('SearchCubit.loadHistory', () {
    blocTest<SearchCubit, SearchState>(
      'emits SearchInitial with history items',
      build: () {
        when(mockRepo.getSearchHistory())
            .thenAnswer((_) async => [historyItem]);
        return SearchCubit(mockRepo);
      },
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        isA<SearchInitial>().having((s) => s.history.length, 'length', 1),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'emits empty SearchInitial on error',
      build: () {
        when(mockRepo.getSearchHistory()).thenThrow(Exception('storage error'));
        return SearchCubit(mockRepo);
      },
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        isA<SearchInitial>().having((s) => s.history, 'history', isEmpty),
      ],
    );
  });

  group('SearchCubit.onQueryChanged', () {
    blocTest<SearchCubit, SearchState>(
      'emits [Loading, Results] when results found',
      build: () {
        when(mockRepo.searchByUsername('alice'))
            .thenAnswer((_) async => [profile]);
        return SearchCubit(mockRepo);
      },
      act: (cubit) => cubit.onQueryChanged('alice'),
      // debounce is 300ms; wait for it
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const SearchLoading(),
        isA<SearchResults>().having((s) => s.results.length, 'length', 1),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'emits [Loading, Empty] when no results',
      build: () {
        when(mockRepo.searchByUsername('xyz'))
            .thenAnswer((_) async => []);
        return SearchCubit(mockRepo);
      },
      act: (cubit) => cubit.onQueryChanged('xyz'),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const SearchLoading(),
        isA<SearchEmpty>().having((s) => s.query, 'query', 'xyz'),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'emits [Loading, Error] on repository failure',
      build: () {
        when(mockRepo.searchByUsername(any)).thenThrow(Exception('network'));
        return SearchCubit(mockRepo);
      },
      act: (cubit) => cubit.onQueryChanged('fail'),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const SearchLoading(),
        isA<SearchError>(),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'clears query → calls loadHistory',
      build: () {
        when(mockRepo.getSearchHistory()).thenAnswer((_) async => []);
        return SearchCubit(mockRepo);
      },
      act: (cubit) => cubit.onQueryChanged(''),
      expect: () => [
        isA<SearchInitial>(),
      ],
    );
  });

  group('SearchCubit.clearHistory', () {
    blocTest<SearchCubit, SearchState>(
      'emits empty SearchInitial after clearing',
      build: () {
        when(mockRepo.clearHistory()).thenAnswer((_) async {});
        return SearchCubit(mockRepo);
      },
      act: (cubit) => cubit.clearHistory(),
      expect: () => [const SearchInitial()],
    );
  });
}
