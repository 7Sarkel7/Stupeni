# Generics и исключения

**Модуль:** K. Kotlin под всё остальное  
**Уровень:** J, `in`/`out` и `reified` — **M.**  
**Время:** около 45 минут  
**Лаборатория:** нет, `Scratch.kt`  
**Намёк:** [solutions/README.md](solutions/README.md)  
**Дальше:** [Job, scope и отмена корутин](13-job-scope.md)

## Цель

Читать и писать простые дженерики (`List<T>`, `fun <T> ...`, `Result<T>`). Правильно ловить исключения: не глотать, не ловить лишнее, не ломать отмену корутин.

## Зачем это вам

`List<String>`, `StateFlow<UiState>`, `Result<Status>`, `Response<T>`, `Flow<List<Item>>` — все они дженерики. А `try/catch` вокруг сети в каждом экране: ошибка сети — норма, а не исключение из ряда вон. Для корутин у `catch` есть тонкость, которая ломает отмену, если её не знать.

## Теория

### Generics

**Класс и функция с параметром типа.**

```kotlin
class Box<T>(val value: T)

fun <T> firstOr(list: List<T>, default: T): T = list.firstOrNull() ?: default

val b = Box("станция")      // Box<String>
val n = firstOr(emptyList<Int>(), 0)
```

`T` — «какой-то тип, определите по месту использования». Компилятор подставит его сам, `Box<String>` писать не нужно.

**Ограничения.** `fun <T : Comparable<T>> maxOf(a: T, b: T): T` — `T` обязан уметь сравниваться. Верхняя граница по умолчанию `Any?`; `T : Any` запрещает `null`.

**Стирание типов.** На JVM `T` во время выполнения не известен: `value is T` не скомпилируется, `List<String>` и `List<Int>` — один класс. Исключение — `inline fun <reified T>`: тип подставляется в место вызова, поэтому можно `value is T` и `parse<Status>(json)`. Так сделаны `Json.decodeFromString<T>`, `hiltViewModel<T>()`. **M.**

**Вариантность `in` и `out`.** **M.** `List<out E>` — только отдаёт элементы, поэтому `List<String>` можно передать как `List<Any>`. `MutableList<E>` и отдаёт, и принимает, поэтому такая подмена запрещена. Если встретили `out`/`in` в сигнатуре — смотрите, кто производит значение, а кто потребляет. Junior достаточно знать слова и не удивляться.

**Star projection.** `List<*>` — список чего-то. Читать можно как `Any?`, класть нельзя.

### Исключения

**Основа.** `throw IllegalStateException("...")` бросает; `try { } catch (e: IOException) { } finally { }` ловит. В Kotlin нет checked exceptions: компилятор не заставляет ловить. `try` — выражение: `val n = try { s.toInt() } catch (e: NumberFormatException) { 0 }`.

**Что ловить.**

- Конкретный тип: `IOException`, `SocketTimeoutException`. Не `Exception` и не `Throwable`: они захватят и баг, и `OutOfMemoryError`.
- Не молчать: пустой `catch` — потеря причины. Минимум лог.
- Не использовать исключения вместо ветвления: ожидаемое состояние («нет сети») — это значение, не `throw`. Для этого `Result` или `sealed`-ответ (см. [урок 11](11-classes-objects.md)).

**Функции проверки.** `require(cond) { "сообщение" }` — проверка аргументов, `IllegalArgumentException`. `check(cond) { }` — состояния, `IllegalStateException`. `error("...")` — бросить `IllegalStateException`. `requireNotNull`, `checkNotNull` — для `null`.

**Result.** `runCatching { risky() }` оборачивает исключение в `Result.failure`. Удобно для границы слоя: репозиторий возвращает `Result<Status>`, ViewModel разбирает `fold(onSuccess = ..., onFailure = ...)`. Но осторожно: `runCatching` ловит **всё**, включая `CancellationException`.

**Корутины и CancellationException.** Отмена корутины реализована через исключение `CancellationException`. Если вы поймали его и не пробросили, корутина продолжает работать, хотя её отменили.

```kotlin
suspend fun load(): Result<Status> = try {
    Result.success(api.status())
} catch (e: CancellationException) {
    throw e                     // отмену не глотаем
} catch (e: IOException) {
    Result.failure(e)
}
```

Практика: ловите узкие типы, а при `catch (e: Exception)` в `suspend`-коде добавляйте `catch (e: CancellationException) { throw e }` выше. Подробности про отмену — [следующий урок](13-job-scope.md).

**finally.** Освобождает ресурс. `use { }` у `Closeable` делает это за вас: `File.bufferedReader().use { it.readText() }`.

## Разбор на примере

Загрузка статуса станции. Сеть может упасть, ответ может быть мусором:

```kotlin
sealed interface StatusResult {
    data class Ok(val uptimeMs: Long) : StatusResult
    data object NoNetwork : StatusResult
    data class BadBody(val reason: String) : StatusResult
}

suspend fun loadStatus(client: LampClient): StatusResult = try {
    StatusResult.Ok(client.fetchUptime())
} catch (e: CancellationException) {
    throw e
} catch (e: IOException) {
    StatusResult.NoNetwork
} catch (e: IllegalArgumentException) {
    StatusResult.BadBody(e.message ?: "пусто")
}
```

Ожидаемые сбои стали значениями. Остальные исключения (баги) улетают выше и роняют приложение громко, как и положено багам. `CancellationException` не проглочен.

## Упражнения

1. Напишите `class Box<T>(val value: T)` и extension `fun <T, R> Box<T>.map(f: (T) -> R): Box<R>` и проверьте на `Box(2).map { it * 3 }`.
2. Объявите `fun <T : Comparable<T>> largest(list: List<T>): T?` и проверьте на строках и числах.
3. Что будет с `val n = "12a".toInt()`? Перепишите без исключения, через `toIntOrNull()`.
4. Напишите `fun parsePort(s: String): Int` с `require` на диапазон 1..65535. Какое исключение при 0?
5. Сделайте `File("x.txt").bufferedReader().use { it.readLine() }` и объясните, что закрылось и когда.
6. Вставьте в `suspend`-функцию `try { delay(1000) } catch (e: Exception) { }` и отмените корутину. Что произойдёт? Исправьте.
7. Устно: чем `require` отличается от `check`? Когда `Result`, а когда `sealed`?

### Самопроверка

- Объясняете, зачем `T` и что значит `reified` одним предложением.
- Знаете, что `catch (e: Exception)` в корутине без перебрасывания отмены — баг.

## Типичные ошибки

- Пустой `catch`.
- `catch (e: Throwable)` в обычном коде.
- `runCatching` внутри корутины без проброса `CancellationException`.
- `!!` вместо `requireNotNull` с сообщением.
- Исключение как нормальный путь («нет интернета» через `throw`).
- Дженерик `Any` вместо `T`: теряется типобезопасность.

## Чеклист

- [ ] Пишете простые дженерики и ограничение `T : Comparable<T>`.
- [ ] Ловите конкретные исключения и не молчите.
- [ ] Различаете `require`, `check`, `error`.
- [ ] Не глотаете `CancellationException`.

## Следующий урок

[Job, scope и отмена корутин](13-job-scope.md).
