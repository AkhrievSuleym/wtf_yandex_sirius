# CI Workflow Logic

```mermaid
%%{init: { "layout": "elk" }}%%

flowchart TD
    PUSH["fa:fa-code-commit Push"] --> PUSH_CI
    PR["fa:fa-code-pull-request Pull Request"] --> PR_CI

    subgraph PUSH_CI["Push CI — ранние предупреждения"]
        C1("1. dart format") --> C1Q(["Формат верен?"])
        C1Q -->|Да| C2("2. flutter pub get")
        C1Q -.->|Нет| C1W["fa:fa-triangle-exclamation Предупреждение: форматирование"]
        C1W ~~~ C2

        C2 --> C2Q(["Зависимости разрешены?"])
        C2Q -->|Да| C3("3. flutter analyze")
        C2Q -.->|Нет| C2W["fa:fa-triangle-exclamation Предупреждение: зависимости"]
        C2W ~~~ C3

        C3 --> C3Q(["Анализ без ошибок?"])
        C3Q -->|Да| C_OK("fa:fa-circle-check Push CI пройден")
        C3Q -.->|Нет| C3W["fa:fa-triangle-exclamation Предупреждение: ошибки анализа"]
        C3W ~~~ C_OK
    end

    subgraph PR_CI["PR CI — полная блокировка"]
        P1("1. dart format") --> P1Q(["Формат верен?"])
        P1Q -->|Да| P2("2. flutter pub get")
        P1Q -.->|Нет| P1F("fa:fa-ban Отклонено: форматирование")
        P1F ~~~ P2

        P2 --> P2Q(["Зависимости разрешены?"])
        P2Q -->|Да| P3("3. flutter analyze")
        P2Q -.->|Нет| P2F("fa:fa-ban Отклонено: зависимости")
        P2F ~~~ P3

        P3 --> P3Q(["Анализ без ошибок?"])
        P3Q -->|Да| P4("4. flutter test")
        P3Q -.->|Нет| P3F("fa:fa-ban Отклонено: lint и Flutter-правила")
        P3F ~~~ P4

        P4 --> P4Q(["Все тесты прошли?"])
        P4Q -->|Да| P_OK("fa:fa-circle-check PR CI пройден — можно мержить")
        P4Q -.->|Нет| P4F("fa:fa-ban Отклонено: тесты")
        P4F ~~~ P_OK
    end
```

## Описание

### Push CI

**Цель** — раннее выявление проблем в коде до того, как они станут критичными.

Процесс включает:

1. Проверку форматирования (`dart format`),
2. Разрешение зависимостей (`flutter pub get`),
3. Статический анализ (`flutter analyze`).

**Результат**: Предупреждения, но не блокировка.

### PR CI

**Цель** — строгий контроль качества перед слиянием изменений.

Процесс включает:

1. Проверку форматирования (`dart format`),
2. Разрешение зависимостей (`flutter pub get`),
3. Статический анализ (`flutter analyze`),
4. Запуск тестов (`flutter test`).

**Результат**: Блокировка при ошибках.

## GitHub Actions

В репозитории настроены два рабочих процесса:

- Push CI: запускается при каждом коммите в любую ветку.
- PR CI: запускается при создании или обновлении Pull Request.

Подробности — в файлах `.github/workflows/`.
