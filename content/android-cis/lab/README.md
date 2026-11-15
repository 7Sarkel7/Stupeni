# Лаборатория стека найма

Чистые функции без Android SDK. Тест красный, пока в теле стоит `TODO`. Это приёмка уроков трека [android-cis](../README.md), не приложение «Смена» и не решение капстоуна.

Заготовки: `src/main/kotlin/dev/stupeni/hire/`. Сигнатуры не меняйте: тест собирается об эти имена. Намёки лежат в [../solutions](../solutions) и открываются после своей попытки, около 40 минут.

Из этого каталога:

```bash
./gradlew test
```

Один класс:

```bash
./gradlew test --tests dev.stupeni.hire.FlowNotesTest
./gradlew test --tests dev.stupeni.hire.DispatchTest
./gradlew test --tests dev.stupeni.hire.OutboxTest
./gradlew test --tests dev.stupeni.hire.PushTest
./gradlew test --tests dev.stupeni.hire.WorkPolicyTest
```

| Урок | Класс |
| --- | --- |
| Корутины, Flow, StateFlow | `dev.stupeni.hire.FlowNotesTest` |
| Потоки и main-safety | `dev.stupeni.hire.DispatchTest` |
| Room и сеть, очередь | `dev.stupeni.hire.OutboxTest` |
| Push | `dev.stupeni.hire.PushTest` |
| WorkManager | `dev.stupeni.hire.WorkPolicyTest` |

Hilt, тесты MockK/Turbine/Compose и GitHub Actions в эту JVM-лабораторию не входят: их сдают в своём репозитории `hire-scratch`. Капстоун «Смена» сюда не кладут.
