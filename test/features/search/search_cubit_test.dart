import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wtf_yandex_sirius/features/auth/models/user_model.dart';
import 'package:wtf_yandex_sirius/features/profile/models/profile_model.dart';
import 'package:wtf_yandex_sirius/features/search/models/search_history_item.dart';
import 'package:wtf_yandex_sirius/features/search/presentation/cubits/search_cubit.dart';
import 'package:wtf_yandex_sirius/features/search/presentation/cubits/search_state.dart';
import 'package:wtf_yandex_sirius/features/search/repositories/search_repository.dart';

import '../auth/auth_cubit_test.mocks.dart';
import 'search_cubit_test.mocks.dart';

@GenerateMocks([SearchRepository])
void main() {
  late MockSearchRepository mockRepo;
  late MockAuthRepository mockAuth;

  const accountUid = 'test_account_uid';
  final testUser = UserModel.empty(uid: accountUid);

  final profile = ProfileModel(
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
    mockAuth = MockAuthRepository();
    when(mockAuth.getCurrentUser()).thenAnswer((_) async => testUser);
  });

  SearchCubit buildCubit() => SearchCubit(mockRepo, mockAuth);

  group('SearchCubit.loadHistory', () {
    blocTest<SearchCubit, SearchState>(
      'emits SearchInitial with history items',
      build: () {
        when(mockRepo.getSearchHistory(accountUid))
            .thenAnswer((_) async => [historyItem]);
        return buildCubit();
      },
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        isA<SearchInitial>().having((s) => s.history.length, 'length', 1),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'emits empty SearchInitial on error',
      build: () {
        when(mockRepo.getSearchHistory(accountUid))
            .thenThrow(Exception('storage error'));
        return buildCubit();
      },
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        isA<SearchInitial>().having((s) => s.history, 'history', isEmpty),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'emits empty SearchInitial when not signed in',
      build: () {
        when(mockAuth.getCurrentUser()).thenAnswer((_) async => null);
        return buildCubit();
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
        return buildCubit();
      },
      act: (cubit) => cubit.onQueryChanged('alice'),
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
        return buildCubit();
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
        return buildCubit();
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
        when(mockRepo.getSearchHistory(accountUid))
            .thenAnswer((_) async => []);
        return buildCubit();
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
        when(mockRepo.clearHistory(accountUid)).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.clearHistory(),
      expect: () => [const SearchInitial()],
    );
  });
}
