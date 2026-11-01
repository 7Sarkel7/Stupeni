# Приложение «Ступени»

Каркас на Flutter: читает уроки из `content/`, помнит прогресс локально, даёт короткую проверку по готовым урокам.

Запуск из корня репозитория:

```bash
./tool/sync_content.sh
cd learner
flutter pub get
flutter run
```

Тексты правят только в `content/`. Каталог `learner/assets/content/` скрипт перезаписывает.

Карьерный трек лежит в `content/career/` и открывается с главного экрана кнопкой «Открыть карьерный трек». Стек найма Android для СНГ лежит в `content/android-cis/` и открывается кнопкой «Открыть стек найма Android». Лаборатории, намёки и спеки капстоунов в приложение не зашиты: их открывают из репозитория. В `pubspec.yaml` указаны только каталоги с уроками. Подкаталоги `lab`, `solutions` и `capstone` туда не добавляют: Flutter забирает файлы прямо из указанной папки, а эти подкаталоги должны остаться на компьютере. Принципы курса — в `PEDAGOGY.md` в корне.

Проверки:

```bash
./tool/sync_content.sh
cd learner
flutter test
```

APK для телефона без локального Flutter собирает GitHub Actions. Как скачать `stupeni-learner.apk` и поставить его: [docs/apk-pipeline.md](../docs/apk-pipeline.md).
