# WTF — Тикеты разработки

## Рекомендации по распределению в команде

Параллельные треки после завершения INFRA-1–3:

```
Разработчик A: INFRA-4,8,9,10 → AUTH → BOARD
Разработчик B: INFRA-5,6,7   → PROFILE → SEARCH
Разработчик C: COMMENT → FAVORITES → NOTIF
```

> **Важно:** Модели (`UserModel`, `CommentModel`, `ProfileModel`) — сделать первыми совместно, они блокируют все треки.

---

## EPIC-1: Инфраструктура и настройка проекта

| ID | Тикет | Зависимости |
|----|-------|-------------|
| INFRA-1 | Инициализация Flutter проекта: структура папок по PRD, `pubspec.yaml` с зависимостями | — |
| INFRA-2 | Настройка Firebase (FlutterFire CLI, `firebase_options.dart`) для iOS и Android | INFRA-1 |
| INFRA-3 | Настройка DI: `get_it` + `injectable`, базовый `injection.dart` | INFRA-1 |
| INFRA-4 | Настройка GoRouter: `app_router.dart`, `route_names.dart`, `shell_route.dart` (ShellRoute + BottomNav 4 вкладки) | INFRA-1 |
| INFRA-5 | Тема приложения: `app_theme.dart`, `app_colors.dart` (light/dark), `MaterialApp` | INFRA-1 |
| INFRA-6 | Core-виджеты: `AppTextField`, `AppButton`, `LoadingIndicator`, `AppErrorWidget` | INFRA-5 |
| INFRA-7 | Core-утилиты: `validators.dart`, `date_formatter.dart`, `failures.dart`, `app_constants.dart`, `firestore_collections.dart` | INFRA-1 |
| INFRA-8 | Настройка Hive: инициализация в `main.dart`, регистрация адаптеров | INFRA-1 |
| INFRA-9 | Firebase Security Rules (Firestore + Storage) согласно PRD §10 | INFRA-2 |
| INFRA-10 | Настройка линтера: `very_good_analysis`, `analysis_options.yaml` | INFRA-1 |

---

## EPIC-2: Auth

| ID | Тикет | Зависимости |
|----|-------|-------------|
| AUTH-1 | `UserModel`: все поля, `toJson / fromJson / fromFirestore / copyWith` | INFRA-7 |
| AUTH-2 | `AuthRepository` (абстракция) + `AuthRepositoryImpl` (Firebase Anonymous Auth + Firestore) | AUTH-1, INFRA-2 |
| AUTH-3 | `AuthCubit` + `AuthState` (Initial, Authenticated, Unauthenticated, Loading, Error) | AUTH-2 |
| AUTH-4 | `WelcomePage`: логотип, слоган, кнопка «Начать» → `/sign-up` | INFRA-5 |
| AUTH-5 | `SignUpPage`: анонимная регистрация через Firebase, переход на `/create-profile` | AUTH-3, INFRA-6 |
| AUTH-6 | `CreateProfilePage`: форма (username + realtime uniqueness check, displayName, bio), опциональный аватар | AUTH-3, INFRA-6 |
| AUTH-7 | Логика создания профиля: batch-запись в `users` + `usernames` (Firestore транзакция) | AUTH-2 |
| AUTH-8 | Splash + redirect-логика в GoRouter (auth guard: authenticated → `/board`, иначе → `/welcome`) | AUTH-3, INFRA-4 |

---

## EPIC-3: Board (Своя доска)

| ID | Тикет | Зависимости |
|----|-------|-------------|
| BOARD-1 | `CommentModel`: все поля, `reactions`, `reactedBy`, `toJson / fromJson / fromFirestore / copyWith` | INFRA-7 |
| BOARD-2 | `BoardRepository` (абстракция) + `BoardRepositoryImpl` (Firestore real-time stream) | BOARD-1, INFRA-2 |
| BOARD-3 | `BoardCubit` + `BoardState` (Initial, Loading, Loaded, Error) | BOARD-2 |
| BOARD-4 | `BoardPage`: AppBar с unread badge, список комментариев, pull-to-refresh | BOARD-3, INFRA-6 |
| BOARD-5 | `CommentCard`: текст, дата, метка «Новое», удаление с диалогом подтверждения | BOARD-4 |
| BOARD-6 | `ReactionBar`: 🔥 ❤️ 😂, счётчики, toggle-логика, оптимистичный UI + откат при ошибке | BOARD-2, BOARD-5 |
| BOARD-7 | `EmptyBoard`: иллюстрация + текст «Поделитесь ссылкой…» + CTA | BOARD-4 |
| BOARD-8 | Кнопка «Поделиться профилем»: генерация deep link, `share_plus` | BOARD-4 |

---

## EPIC-4: Comment (Отправка сообщений)

| ID | Тикет | Зависимости |
|----|-------|-------------|
| COMMENT-1 | `CommentRepository` (абстракция) + `CommentRepositoryImpl` (запись в Firestore) | BOARD-1, INFRA-2 |
| COMMENT-2 | `CommentCubit` + `CommentState` (Initial, Sending, Success, Error) | COMMENT-1 |
| COMMENT-3 | `SendCommentPage`: поле ввода (макс. 500 символов, счётчик), кнопка, disclaimer, Loading / Success / Error | COMMENT-2, INFRA-6 |

---

## EPIC-5: Profile (Профиль)

| ID | Тикет | Зависимости |
|----|-------|-------------|
| PROFILE-1 | `ProfileModel`: все поля, `toJson / fromJson / fromFirestore / copyWith` | INFRA-7 |
| PROFILE-2 | `ProfileRepository` (абстракция) + `ProfileRepositoryImpl` (Firestore + Firebase Storage) | PROFILE-1, INFRA-2 |
| PROFILE-3 | `ProfileCubit` + `ProfileState` (Initial, Loading, Loaded, Updating, Error) | PROFILE-2 |
| PROFILE-4 | `MyProfilePage`: шапка, статистика, кнопки «Редактировать» и «Настройки» | PROFILE-3, INFRA-6 |
| PROFILE-5 | Виджеты профиля: `ProfileHeader`, `ProfileAvatar`, `ProfileEditForm` | PROFILE-3 |
| PROFILE-6 | `PublicProfilePage`: шапка чужого профиля, кнопки «Написать анонимно» и «Избранное», список его комментариев | PROFILE-3, BOARD-5 |
| PROFILE-7 | `SettingsPage`: переключатель публичности доски, выход из аккаунта, удаление аккаунта | PROFILE-3, AUTH-3 |
| PROFILE-8 | Загрузка аватара в Firebase Storage (pick image → upload → save URL) | PROFILE-2 |

---

## EPIC-6: Search (Поиск)

| ID | Тикет | Зависимости |
|----|-------|-------------|
| SEARCH-1 | `SearchHistoryItem`: модель, `toJson / fromJson` для Hive | INFRA-8 |
| SEARCH-2 | `SearchRepository` (абстракция) + `SearchRepositoryImpl` (Firestore prefix query + Hive) | SEARCH-1, INFRA-2 |
| SEARCH-3 | `SearchCubit` + `SearchState` (Initial, Loading, Results, Empty, Error) + debounce 300ms | SEARCH-2 |
| SEARCH-4 | `SearchPage`: поле поиска, переключение между историей и результатами | SEARCH-3, INFRA-6 |
| SEARCH-5 | `SearchResultTile`: аватар, displayName, @username, нажатие → `PublicProfilePage` | SEARCH-4 |
| SEARCH-6 | `SearchHistoryList`: список последних 20 просмотров, кнопка «Очистить историю» | SEARCH-4 |

---

## EPIC-7: Favorites (Избранное)

| ID | Тикет | Зависимости |
|----|-------|-------------|
| FAV-1 | `FavoritesRepository` (абстракция) + `FavoritesRepositoryImpl` (Firestore subcollection `users/{uid}/favorites`) | PROFILE-1, INFRA-2 |
| FAV-2 | `FavoritesCubit` + `FavoritesState` (Initial, Loading, Loaded, Error) | FAV-1 |
| FAV-3 | `FavoritesPage`: список избранных, swipe-to-remove, пустое состояние | FAV-2, INFRA-6 |
| FAV-4 | `FavoriteProfileTile`: аватар, displayName, @username | FAV-3 |

---

## EPIC-8: Push-уведомления (FCM)

| ID | Тикет | Зависимости |
|----|-------|-------------|
| NOTIF-1 | Интеграция FCM на клиенте: запрос разрешений, сохранение `fcmToken` в `users/{uid}` | AUTH-2, INFRA-2 |
| NOTIF-2 | Cloud Function `onNewComment`: триггер на `comments/{commentId}`, отправка push владельцу доски | BOARD-1 |
| NOTIF-3 | Обработка входящих уведомлений на клиенте (foreground / background / terminated) | NOTIF-1 |

---

## EPIC-9: Polish & QA

| ID | Тикет | Зависимости |
|----|-------|-------------|
| POLISH-1 | Shimmer-загрузки для всех списков и карточек | Все UI |
| POLISH-2 | Пустые состояния (Empty state: иллюстрация + текст + CTA) для всех экранов | Все UI |
| POLISH-3 | Глобальный error handling: retry-кнопки во всех Cubit-состояниях Error | Все Cubits |
| POLISH-4 | Анимации переходов и микровзаимодействия (`flutter_animate`) | Все UI |
| POLISH-5 | Unit-тесты для всех Cubits (`bloc_test` + `mockito`) | Все Cubits |
| POLISH-6 | Deep links: `wtf://profile/{username}` и `wtf://board` в GoRouter | INFRA-4 |
| POLISH-7 | Базовый клиентский фильтр запрещённых слов перед отправкой комментария | COMMENT-3 |

---

## Итого

| Эпик | Тикетов |
|------|---------|
| INFRA | 10 |
| AUTH | 8 |
| BOARD | 8 |
| COMMENT | 3 |
| PROFILE | 8 |
| SEARCH | 6 |
| FAVORITES | 4 |
| NOTIF | 3 |
| POLISH | 7 |
| **Всего** | **57** |
