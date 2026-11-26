# Лаборатория

Gradle-проект без Android. Здесь функции, которые вы пишете сами, и тесты, которые проверяют результат. Тест — приёмка. Реализации в репозитории нет.

Заготовки: `src/main/kotlin/dev/stupeni/career/`. Тела с `TODO(...)` заменяете вы. Типы данных уже объявлены, чтобы тест собирался. `FormatUptime.kt` трогать не нужно: в уроке C4 вы пишете к ней проверки.

Намёки без кода лежат выше, в `../solutions/`. Открывайте один файл, если застряли примерно на 40 минут. В лабораторию из той папки ничего не копируется: готовых тел функций там нет.

## Как запустить один тест

Нужен JDK 21. Из этого каталога:

```bash
./gradlew test --tests dev.stupeni.career.WordCountTest
```

Имя класса меняется по уроку. `./gradlew test` без фильтра гоняет всё сразу и будет красным, пока не закрыты все модули C1–C3. Это ожидаемо. Идите по одному классу.

| Урок | Класс теста |
| --- | --- |
| Коллекции | `dev.stupeni.career.WordCountTest` |
| Модели | `dev.stupeni.career.ParseDeviceLineTest` |
| Алгоритмы | `dev.stupeni.career.AlgorithmsTest` |
| Контракт HTTP | `dev.stupeni.career.HttpMappingTest` |
| Повтор | `dev.stupeni.career.RetryTest` |
| Телефон и плата | `dev.stupeni.career.TransportTest` |
| MVVM (схема, где данные, экран и «посредник» между ними, ViewModel, разделены) | `dev.stupeni.career.ReducerTest` |
| Clean lite | `dev.stupeni.career.LoadLampTest` |
| Корутины | `dev.stupeni.career.CoroutinesTest` |
| Свои тесты | снимите `@Disabled` с `FormatUptimeTest` |

Отчёт падения: `build/reports/tests/test/index.html`.

Первый запуск скачает Gradle и зависимости. Дальше сеть для тестов не нужна.
