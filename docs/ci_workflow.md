# CI Workflow Logic

```mermaid
%%{init: { "layout": "elk" }}%%

flowchart TD
    PUSH["fa:fa-code-commit Push"] --> PUSH_CI
    PR["fa:fa-code-pull-request Pull Request"] --> PR_CI
    MAIN["fa:fa-code-branch Main"] --> MAIN_CI

    subgraph PUSH_CI["Push CI — ранние предупреждения"]
        C1("1. flutter pub get") --> C1Q(["Зависимости разрешены?"])
        C1Q -->|Да| C2("2. dart format")
        C1Q -.->|Нет| C1W["fa:fa-triangle-exclamation Предупреждение: зависимости"]
        C1W ~~~ C2

        C2 --> C2Q(["Формат верен?"])
        C2Q -->|Да| C3("3. flutter analyze --no-pub")
        C2Q -.->|Нет| C2W["fa:fa-triangle-exclamation Предупреждение: форматирование"]
        C2W ~~~ C3

        C3 --> C3Q(["Анализ без ошибок?"])
        C3Q -->|Да| C_OK("fa:fa-circle-check Push CI пройден")
        C3Q -.->|Нет| C3W["fa:fa-triangle-exclamation Предупреждение: ошибки анализа"]
        C3W ~~~ C_OK
    end

    subgraph PR_CI["PR CI — полная блокировка"]
        P1("1. flutter test") --> P1Q(["Тесты прошли?"])
        P1Q -->|Да| P_OK("fa:fa-circle-check PR CI пройден — можно мержить")
        P1Q -.->|Нет| P1F("fa:fa-ban Отклонено: тесты")
        P1F ~~~ P_OK
    end

    subgraph MAIN_CI["Main CI — финальная проверка"]
        M1("1. flutter test") --> M1Q(["Тесты прошли?"])
        M1Q -->|Да| M_OK("fa:fa-circle-check Main CI пройден")
        M1Q -.->|Нет| M1F("fa:fa-ban Отклонено: тесты")
        M1F ~~~ M_OK
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

В репозитории настроены рабочие процессы:

- Push CI: запускается при каждом коммите в любую ветку. Проверяет форматирование, зависимости и статический анализ.
- PR CI: запускается при создании или обновлении Pull Request. Запускает тесты с покрытием и блокирует слияние при ошибках.
- Main CI: запускается при пуше в `main`. Запускает тесты с покрытием для гарантии работоспособности.

Подробности — в файлах `.github/workflows/`.
