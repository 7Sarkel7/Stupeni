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

Проверки:

```bash
./tool/sync_content.sh
cd learner
flutter test
```
