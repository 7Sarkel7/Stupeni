# Gradle, version catalog, подпись и публикация

**Модуль:** A. Android: что ещё спрашивают  
**Уровень:** J  
**Время:** около 50 минут  
**Лаборатория:** нет, `hire-scratch`  
**Намёк:** нет  
**Дальше:** [стек найма Android для СНГ](../android-cis/README.md)

## Цель

Читать `build.gradle.kts` Android-проекта, вынести версии в `libs.versions.toml`, настроить типы сборки, подписать release (релиз — выпуск готовой версии приложения для пользователей) и собрать `.aab` и `.apk`. Знать, чем Google Play и RuStore отличаются по формату и подписи.

## Зачем это вам

На скрининге (первый короткий этап собеседования, где проверяют базовые знания) просят показать приложение «на телефоне». Рано или поздно его нужно собрать вне Android Studio, подписать и отдать. Без этого «я сделал приложение» остаётся на вашем ноутбуке. Все остальные уроки опираются на Gradle: [CI](../android-cis/11-ci.md) собирает именно то, что описано здесь.

## Теория

### Структура проекта

```
settings.gradle.kts         список модулей, репозитории плагинов
build.gradle.kts            общий (обычно только плагины с apply false)
gradle/libs.versions.toml   версии и зависимости (version catalog)
app/build.gradle.kts        модуль приложения
```

**`android { }` в модуле `app`.**

```kotlin
android {
    namespace = "dev.example.lamp"
    compileSdk = 36               // номера сверяйте с документацией на день создания
    defaultConfig {
        applicationId = "dev.example.lamp"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
    }
    buildFeatures { compose = true }
}
```

- `applicationId` — идентификатор в магазине, его нельзя менять после публикации. `namespace` — пакет для генерируемого кода, это разные вещи.
- `compileSdk` — против какого API (набор правил, по которым одна программа обращается к другой) компилируете; `targetSdk` — для какой версии поведения вы тестировали (магазины требуют свежий); `minSdk` — самый старый поддерживаемый Android. Чем ниже `minSdk`, тем больше ветвлений по `SDK_INT`.
- `versionCode` растёт с каждой загрузкой в магазин (целое), `versionName` — для людей.

### Version catalog

Файл `gradle/libs.versions.toml` — одно место для версий:

```toml
[versions]
kotlin = "<версия>"
coroutines = "<версия>"

[libraries]
coroutines-core = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core", version.ref = "coroutines" }
okhttp = { module = "com.squareup.okhttp3:okhttp", version = "<версия>" }
junit = { module = "junit:junit", version = "<версия>" }

[plugins]
android-application = { id = "com.android.application", version = "<версия>" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }

[bundles]
networking = ["okhttp"]
```

Использование: `implementation(libs.coroutines.core)`, `alias(libs.plugins.kotlin.android)`. Ошибка в имени — ошибка на этапе синхронизации, а не опечатка в строке. Обновление: одна правка в `[versions]`. Версии берут со страниц библиотек и Android Studio (не копируйте из урока). Для Compose — [BOM](https://developer.android.com/develop/ui/compose/bom): `implementation(platform(libs.compose.bom))`, затем артефакты без версий.

**Конфигурации зависимостей.** `implementation` — внутри модуля; `api` — видно потребителям (для библиотек); `testImplementation` — локальные тесты; `androidTestImplementation` — инструментальные; `debugImplementation` — только debug (например, инструменты Compose).

### Типы сборки и flavors

```kotlin
buildTypes {
    debug { applicationIdSuffix = ".debug" }
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        signingConfig = signingConfigs.getByName("release")
    }
}
```

- `debug` подписан общим debug-ключом, подходит для себя.
- `release` с R8 (`isMinifyEnabled`) сжимает и обфусцирует код. Библиотеки с рефлексией (`Gson`, часть логики) требуют правил keep; `kotlinx.serialization` и Compose приносят свои правила. После включения R8 **обязательно** проверьте release-сборку руками: ошибки видны только там.
- *Product flavors* — варианты продукта (`play`, `rustore`), если нужны разные SDK (набор инструментов для разработки под платформу) или ключи. Для учебных проектов не нужны.

### Подпись

Android требует, чтобы каждый APK (файл установки приложения для Android) и AAB были подписаны. Ключ — файл хранилища (`.jks`). Потеряли ключ загрузки — обновлять приложение сложно (Play позволяет восстановить через поддержку; для RuStore и ручной раздачи ключ — единственная идентичность приложения).

Создание ключа:

```bash
keytool -genkeypair -v -keystore release.jks -alias lamp \
  -keyalg RSA -keysize 2048 -validity 10000
```

**Секреты не в репозитории.** Ключ и пароли лежат вне git (`.gitignore`), а в `build.gradle.kts` читаются из переменных окружения или `local.properties`:

```kotlin
signingConfigs {
    create("release") {
        val path = System.getenv("RELEASE_STORE_FILE")
        if (path != null) {
            storeFile = file(path)
            storePassword = System.getenv("RELEASE_STORE_PASSWORD")
            keyAlias = System.getenv("RELEASE_KEY_ALIAS")
            keyPassword = System.getenv("RELEASE_KEY_PASSWORD")
        }
    }
}
```

В CI (автоматическая сборка и проверка проекта на сервере при каждом изменении) ключ хранится как секрет репозитория (в base64) и восстанавливается в файл на время сборки ([урок CI](../android-cis/11-ci.md)). Пароли в `git log` не уходят никогда: если случайно закоммитили (коммит — сохранённый в Git снимок изменений с подписью), ключ считается скомпрометированным.

### Артефакты

| Формат | Что это | Куда |
| --- | --- | --- |
| `.apk` | готовый установочный файл | установка вручную, RuStore, раздача по ссылке |
| `.aab` | Android App Bundle, из него магазин делает APK под устройство | Google Play (обязателен для новых приложений) |

Сборка: `./gradlew assembleRelease` (APK), `./gradlew bundleRelease` (AAB). Результаты в `app/build/outputs/`.

**Google Play.** Использует *Play App Signing*: вы подписываете загружаемый AAB «ключом загрузки», а итоговый ключ приложения хранит Google. Нужен аккаунт разработчика, проверка и тесты (закрытое тестирование для новых личных аккаунтов; правила меняются — смотрите актуальную [справку Play Console](https://support.google.com/googleplay/android-developer)).

**RuStore.** Принимает APK (и AAB по актуальным требованиям консоли), подпись вашим ключом, проверка приложения; требования смотрите в [документации RuStore](https://www.rustore.ru/help/developers/). Этот ключ — ваша идентичность: храните резервную копию в двух местах.

**Проверка подписи.** `apksigner verify --print-certs app-release.apk` показывает сертификат. Установка: `adb install app-release.apk`.

**Что ещё до публикации.** Иконка и название, политика конфиденциальности (если собираете данные), список разрешений с объяснением ([урок 03](03-permissions.md)), тест release-сборки на нескольких версиях, `versionCode` больше предыдущего, `targetSdk` не устарел.

### Git рядом

Версионирование: тег (постоянная метка на коммите, обычно с номером версии) на релиз (`git tag v0.1.0`), ветка `main` всегда собирается, release из тега. Основы Git — [модуль 01](../01-fundamentals/01-git.md), PR (pull request — просьба на GitHub проверить ваши изменения и добавить их в основную ветку) — [урок 11 карьерного трека](../career/11-git-pr.md).

## Разбор на примере

«Отдать APK другу, без Play».

1. Создать `release.jks` (один раз), положить вне репозитория, резервную копию — в двух местах.
2. Задать переменные окружения со своими паролями.
3. `./gradlew assembleRelease`. Если R8 включён, открыть APK на телефоне и пройти весь сценарий.
4. `apksigner verify`.
5. Передать файл. Версия: `versionName = 0.1.0`, `versionCode = 1`. Следующая сборка: `0.1.1` и `2`.
6. Если друг ставит поверх сборки, подписанной другим ключом (например, debug), Android откажет: подпись должна совпадать.

Типичный провал: release собирается, но падает при запуске, потому что R8 удалил класс, который достают рефлексией. Лечится правилом keep и тестом release-сборки.

## Упражнения

1. Вынесите все версии зависимостей `hire-scratch` в `libs.versions.toml` и пересоберите.
2. Добавьте Compose BOM («список версий»: подключаете его один раз, и версии связанных библиотек подбираются сами) и уберите версии отдельных артефактов Compose.
3. Создайте ключ, настройте `signingConfig` через переменные окружения, соберите `assembleRelease` и проверьте `apksigner verify`.
4. Включите `isMinifyEnabled` и пройдите приложение в release. Найдите, что сломалось (если ничего — запишите, какие правила пришли от библиотек).
5. Соберите `bundleRelease` и откройте `.aab` в `bundletool` (или просто убедитесь, что файл создан).
6. Добавьте тег `v0.1.0` и подпишите релизную сборку в CI ([урок](../android-cis/12-homework-ci.md)) без ключа в репозитории.
7. Устно: чем `applicationId` отличается от `namespace`? Что будет, если потерять ключ? Чем AAB отличается от APK?

### Самопроверка

- Читаете `app/build.gradle.kts` и объясняете блоки.
- Объясняете, где хранится ключ и почему не в git.
- Различаете Play App Signing и подпись в RuStore.

## Типичные ошибки

- Ключ и пароли в репозитории.
- Единственная копия ключа.
- Менять `applicationId` после публикации.
- Не проверить release-сборку после включения R8.
- `versionCode` не вырос: магазин отклонит загрузку.
- Версии зависимостей в десяти местах и дубликаты в разных модулях.
- Копировать версии из статей двухлетней давности.
- `usesCleartextTraffic` на всё приложение ради отладки и остался в release.

## Чеклист

- [ ] `libs.versions.toml` и BOM в проекте.
- [ ] Подписанный release APK и AAB.
- [ ] Ключ вне git, с резервной копией.
- [ ] Release проверен на телефоне.
- [ ] Знаете различия Play и RuStore.

## Следующий урок

Дальше по Android: [стек найма для СНГ](../android-cis/README.md), если ещё не пройден, и [карьерный трек](../career/README.md).
