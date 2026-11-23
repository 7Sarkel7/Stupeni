# Лаборатория K

Gradle-проект без Android: функции, которые вы пишете сами, и тесты, которые проверяют результат. Тест — приёмка. Реализации в репозитории нет.

Тела с `TODO(...)` в `src/main/kotlin/dev/stupeni/kotlincore/` заменяете вы. Сигнатуры не меняйте. Нужен JDK 21. Номер версии Kotlin и корутин в `build.gradle.kts` сверяйте с актуальными, если открываете проект в новой IDE.

```bash
./gradlew test --tests dev.stupeni.kotlincore.LambdasTest
```

| Урок | Класс теста |
| --- | --- |
| Лямбды (03–07) | `dev.stupeni.kotlincore.LambdasTest` |
| Отложенное действие (05, 07) | `dev.stupeni.kotlincore.PendingLinkTest` |
| Операторы и extension (08, 10) | `dev.stupeni.kotlincore.OperatorsTest` |

`./gradlew test` без фильтра гоняет всё. Красный прогон до вашей реализации — норма, не поломка Gradle. Намёки без кода: [../solutions](../solutions/README.md).
