# Как собран курс

Ступени — не пересказ чужого учебника. Ниже принципы и источники, у которых взята форма, не текст и не код. Платные главы и чужие лабораторные в репозиторий не копировались.

## Принципы

Урок короткий и привязан к делу, которое уже можно включить: пульт, плата, локальный HTTP. Сначала механизм, потом проверка, потом работа руками. Проверка в приложении ловит путаницу в четырёх вопросах. Она не заменяет работу.

Самостоятельная работа устроена так, как задачник, а не как решебник. В репозитории есть ТЗ, критерии приёмки и рубрика. Есть каркас, если без него неясно, куда писать. Нет тела функции, готового скетча работы и готового приложения капстоуна. Короткий ключ к устным вопросам уроков 01–03 лежит в `content/hints/` и открывается после своей попытки. Это не решение модульной работы.

Карьерный трек стоит поверх модулей 01–03, а не вместо них. Лаборатория `content/career/lab` даёт красный тест как приёмку. Намёки в `content/career/solutions/` — несколько предложений, без кода, который компилируется вместо вашего. Итоговый проект — DeskNode в вашем репозитории, по [спеке](content/career/capstone/SPEC.md).

Уровень помечен. J закрывает junior и отклик. M не блокирует подачу и не превращается в строку middle в резюме, пока за спиной нет самостоятельной коммерческой фичи. Дневная работа и личный станц не переписываются в чужой стаж.

Модули 04–07 ещё конспекты. У них нет самостоятельной работы специально: конспект не должен выглядеть как задание, которого нельзя сдать.

## Android UI по текущим докам

Экран пульта в модуле 02 и экран DeskNode в капстоуне учат Jetpack Compose и Material 3. Это текущий стек Android UI. Номер Compose BOM в уроки не замораживают: его копируют со страницы документации в день, когда создают проект. Если абзац урока и официальная страница разошлись в имени API или в номере, сдаётся страница. Урок после этого поправляют.

- [Документация Jetpack Compose](https://developer.android.com/develop/ui/compose/documentation)
- [Material 3 в Compose](https://developer.android.com/develop/ui/compose/designsystems/material3)
- [Compose BOM](https://developer.android.com/develop/ui/compose/bom) и [таблица соответствия](https://developer.android.com/develop/ui/compose/bom/bom-mapping)
- [Navigation 3](https://developer.android.com/guide/navigation/navigation-3) — навигация нового кода
- [Navigation Compose](https://developer.android.com/develop/ui/compose/navigation) — что ещё читают в старых проектах с `NavHost`
- [Тест кадра Compose](https://developer.android.com/develop/ui/compose/testing)

Kotlin Multiplatform — необязательный следующий шаг: вынести чистые функции вроде перехода состояния в общий модуль, когда Android-экран уже собран. Трек пульта и капстоун он не заменяет, UI остаётся на Android. Точка входа: [документация Kotlin Multiplatform](https://kotlinlang.org/docs/multiplatform.html).

## Найм Android в СНГ

Трек [content/android-cis](content/android-cis/README.md) идёт после уроков Compose модуля 02. Он готовит к разговору на junior Android там, где спрашивают корутины, Flow, диспетчеры, Hilt, Retrofit, Room, DataStore, тесты, GitHub Actions, пуши и WorkManager. Капстоун этого трека — журнал «Смена» по [спеке](content/android-cis/capstone/SPEC.md). Капстоун DeskNode остаётся в карьерном треке.

Номера библиотек и версий GitHub Actions в уроки не замораживают. В день проекта их копируют со страницы, на которую ссылается урок. Если абзац и страница разошлись в имени API, сдаётся страница.

- [Корутины Kotlin](https://kotlinlang.org/docs/coroutines-overview.html), [Flow](https://kotlinlang.org/docs/flow.html), [диспетчеры](https://kotlinlang.org/docs/coroutine-context-and-dispatchers.html)
- [Корутины на Android](https://developer.android.com/kotlin/coroutines), [Flow на Android](https://developer.android.com/kotlin/flow), [рекомендации](https://developer.android.com/kotlin/coroutines/coroutines-best-practices)
- [Hilt](https://developer.android.com/training/dependency-injection/hilt-android). Koin в треке только читают: [ViewModel в Koin](https://insert-koin.io/docs/reference/koin-android/viewmodel)
- [Retrofit](https://square.github.io/retrofit/), [OkHttp](https://square.github.io/okhttp/), [Room](https://developer.android.com/training/data-storage/room), [DataStore](https://developer.android.com/topic/libraries/architecture/datastore)
- [Локальные тесты](https://developer.android.com/training/testing/local-tests), [MockK](https://mockk.io/), [Turbine](https://cashapp.github.io/turbine/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [FCM на Android](https://firebase.google.com/docs/cloud-messaging/android/client), [каналы уведомлений](https://developer.android.com/develop/ui/views/notifications/channels), [RuStore Push](https://www.rustore.ru/help/sdk/push-notifications)
- [WorkManager](https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started)

Платные курсы в тексты не переносились. Примеры привязаны к станцу Поле, к лампе DeskNode и к журналу смены, который ученик собирает сам.

## Git

Первая часть фундамента — рабочий Git, не обзор на один вечер. Уроки идут от снимка и трёх деревьев к ежедневным командам, откату, веткам, rebase, stash, remote, pull request, секретам и устным ответам. В конце отдельная песочница: конфликт, склейка коммитов, описание PR, тег. В репозиторий Ступеней эту песочницу не кладут.

Команды те же, что на джуниорской и мидловой работе. Примеры привязаны к пульту и прошивке станца. Справочник рядом, главы в уроки не переносились: [Pro Git, русское издание](https://git-scm.com/book/ru/v2) (CC BY-NC-SA) и [документация команд](https://git-scm.com/docs). Ключ к устным вопросам по-прежнему в `content/hints/`, его открывают после своей попытки. В приложении ссылка на ключ открывается отдельным экраном и не ставит отметку «изучил».

## Что у кого взято

Форма, не содержание.

- [CS50](https://cs50.harvard.edu/x/) — короткий разбор, затем проверка понимания, затем задача, которую делают сами. Видео курса мы не встраиваем и конспекты CS50 не переносим.
- [Android Basics](https://developer.android.com/courses) и [документация Flutter](https://docs.flutter.dev/learn) — ритм «урок, практика, короткий quiz». Flutter в Ступенях остаётся вторым клиентом, не заменой пульта станца. Приложение `learner/` — свой каркас для чтения этих текстов.
- [Exercism](https://exercism.org/) и [The Odin Project](https://www.theodinproject.com/) — задание с приёмкой и без готового решения в учебном репозитории. Тесты лаборатории показывают вход и выход. Они не показывают реализацию.
- [roadmap.sh/android](https://roadmap.sh/android) — идея чеклиста навыков, чтобы было видно, что уже можно защитить, а что только прочитано. Дерево roadmap сюда не скопировано.
- Kotlin in Action, Clean Code, Head First Design Patterns, The Pragmatic Programmer — словарь для собеседования: зачем `data class`, зачем одна ответственность, зачем имя паттерна, если он у вас и так есть в коде. Глав этих книг в уроках нет.
- [ESP-IDF](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/), [Arduino-ESP32](https://docs.espressif.com/projects/arduino-esp32/en/latest/) и [FastAPI](https://fastapi.tiangolo.com/) — куда смотреть факты по железу и по будущему облаку. Уроки не заменяют справочник регистров и не цитируют документацию простынями.

## Связь с станцом

База та же, что у пульта и прошивки Поле: Kotlin уже не с нуля, C++ — на уровне «читал и немного писал», вечер короче смены. Модули 01–03 доводят локальный контракт. Карьера берёт этот контракт и доращивает его до разговора о найме: коллекции, сеть, MVVM, тесты, честное резюме, свой узел DeskNode. Облако, голос и Flutter не идут раньше живого `GET /v1/reading`.

Если правило работы и пример в уроке расходятся, сдаёте правило работы. Пример в уроке объясняет механизм на другом маленьком куске, его не сдают как свою работу.
