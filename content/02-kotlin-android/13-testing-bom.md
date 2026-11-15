# Тест UI и BOM

**Модуль:** 02. Kotlin и Android  
**Время:** около 30 минут  
**Дальше:** [Самостоятельная: пульт на Compose](14-homework-compose.md)

## Цель

Проверить кадр пульта без платы и без живой ViewModel. Подключить Compose так, чтобы версии библиотек брались с актуальной страницы BOM, а не из застывшего номера в чужом конспекте.

## Зачем это вам

Редьюсер проверяют на JVM, это карьерная лаборатория. Кадр «фраза видна, кнопка не жмётся» так не поймать: это дерево Compose. На работе такой тест лежит в `androidTest` и использует `createComposeRule`. Эмулятор или устройство для него нужны, в CI капстоуна уровня J его нет специально. Уметь написать один тест — отдельное требование этого модуля.

Версии — вторая половина того же вечера. На собеседовании спрашивают, зачем BOM. Ответ «поставил номера из статьи» на ревью разъезжается через месяц. Страница, с которой копируют номер в день проекта: [Compose BOM](https://developer.android.com/develop/ui/compose/bom). Таблица, какая библиотека внутрь какого BOM вошла: [сопоставление](https://developer.android.com/develop/ui/compose/bom/bom-mapping). Как подключить компилятор и зависимости: [настройка](https://developer.android.com/develop/ui/compose/setup-compose-dependencies-and-compiler).

## Теория

BOM — это платформенная зависимость. Она не добавляет библиотеки в APK сама. Она фиксирует согласованный набор версий. Строки библиотек Compose пишут без своего номера:

```kotlin
dependencies {
    val composeBom = platform("androidx.compose:compose-bom:<номер со страницы BOM>")
    implementation(composeBom)
    androidTestImplementation(composeBom)
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
```

В файл проекта вместо `<номер со страницы BOM>` попадает значение со страницы в тот день. В этот урок живой номер не записан: через месяц он станет враньём. В своём `build.gradle` рядом с номером оставьте комментарий с датой и ссылкой на страницу. Стабильный BOM без суффикса. Суффиксы `-alpha` и `-beta` в имени артефакта — для проверки будущего, не для пульта, который вы показываете.

Компилятор Compose с Kotlin 2 — плагин `org.jetbrains.kotlin.plugin.compose`, его версия совпадает с версией Kotlin в проекте. Отдельный артефакт компилятора, который указывали до Kotlin 2, в новый проект не добавляют.

Вне BOM остаются артефакты, которые не входят в набор Compose UI: `activity-compose`, `lifecycle-viewmodel-compose`, `lifecycle-runtime-compose`, Navigation 3. У каждого своя страница релизов. Ставить им номер «как у material3» нельзя: это другие линейки.

Тест кадра. Правило `createComposeRule()` поднимает композицию без вашей Activity. В `setContent` передают экран и готовый снимок. Ищут узел по тексту, который видит человек.

```kotlin
@get:Rule val rule = createComposeRule()

@Test fun failurePhrase_isShown() {
    rule.setContent {
        RemoteStatusScreen(
            state = RemoteUiState(host = "192.168.10.1", phrase = "нет связи", busy = true, files = emptyList()),
            onHostChange = {},
            onPing = {},
            onOpenFiles = {},
        )
    }
    rule.onNodeWithText("нет связи").assertIsDisplayed()
}
```

Это форма теста, не работа на сдачу. Фразу и подписи кнопок в своей работе вы берёте из задания. `performClick` по тексту кнопки проверяет, что жест зовёт лямбду один раз. `assertIsNotEnabled` проверяет, что во время загрузки кнопка мертва. Семантика совпадает с тем, что читает TalkBack: если тест не находит кнопку, её часто не находит и человек со читалкой.

`createAndroidComposeRule<MainActivity>()` поднимает Activity. Для снимка, который и так приходит аргументом, хватает `createComposeRule`.

Страница приёмов: [Test your Compose layout](https://developer.android.com/develop/ui/compose/testing).

## Разбор на примере

Снимок с `busy = true` и фразой про связь. Тест находит фразу и убеждается, что кнопка проверки выключена. Репозиторий, Wi-Fi и ESP32 в этом прогоне не участвуют. Сломали условие `enabled = !state.busy` — тест красный до вечера у станца.

Рядом JVM-тест на `describePing` или `reduce` остаётся. Он быстрее и идёт без устройства. UI-тест не заменяет его и не копирует его проверки в `onNodeWithText` всего подряд.

Обновление BOM через полгода: меняете один номер платформы, смотрите примечания к релизу, гоняете оба теста. Номера на каждой строке `material3` при этом нет, править их не нужно. Если строка `material3:1.x.x` всё же появилась рядом с BOM, вы снова ведёте две таблицы.

## Упражнения

1. Что именно подтягивает строка `platform("androidx.compose:compose-bom:…")` и чего она не подтягивает?
2. Куда смотреть номер BOM завтра, если этот урок открыт через год?
3. Какой тест ловит «кнопка жмётся во время загрузки», а какой — «обрыв сети превратился в фразу станц не ответил» как чистую функцию?

### Ориентир для самопроверки

Ключ: [13-testing-bom.md](../hints/13-testing-bom.md).

## Типичные ошибки

- Вписать в репозиторий номер BOM из памяти или из урока, где номера нет.
- Повесить версию и на BOM, и на `material3`.
- Ждать, что BOM подтянет Navigation 3 и `activity-compose`.
- Тестировать кадр только глазами.
- Поднимать в UI-тесте настоящий сокет.

## Чеклист

- [ ] В своём проекте номер BOM скопирован со страницы документации, рядом дата.
- [ ] Библиотеки Compose из BOM записаны без своих версий.
- [ ] Плагин компилятора — Kotlin Compose plugin.
- [ ] Один UI-тест кормит экран готовым снимком.
- [ ] Чистая функция фразы по-прежнему проверяется без устройства.

## Следующий урок

[Самостоятельная: пульт на Compose](14-homework-compose.md).

Kotlin Multiplatform этим уроком не открывается. Общий код с другими платформами — необязательный шаг после своего Android-пульта, он описан в самостоятельной работе и не заменяет трек.
