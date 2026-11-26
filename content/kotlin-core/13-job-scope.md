# Job, scope и отмена корутин

**Модуль:** K. Kotlin под всё остальное  
**Уровень:** J, `SupervisorJob` — **M.**  
**Время:** около 50 минут  
**Лаборатория:** нет, `Scratch.kt` и проект `hire-scratch`  
**Намёк:** [solutions/README.md](solutions/README.md)  
**Дальше:** [Android: lifecycle и ViewBinding](../android-core/01-lifecycle.md)

## Цель

Объяснить, что такое `CoroutineScope`, `Job`, `launch` против `async`, структурная конкурентность, отмена и таймаут (предельное время ожидания ответа, после которого ожидание обрывают). Отличать `viewModelScope`, `lifecycleScope` и `GlobalScope`.

## Зачем это вам

[Первый урок модуля 02](../02-kotlin-android/01-coroutines.md) вынес сеть с главного потока. [Flow и StateFlow](../android-cis/01-flow.md) и [потоки](../android-cis/03-threads.md) показали диспетчеры. Остался каркас: кто владеет корутиной и что с ней происходит при уходе с экрана. Это любимый вопрос на скрининге (первый короткий этап собеседования, где проверяют базовые знания): «что будет, если пользователь закрыл экран во время запроса?».

Лямбда в `launch { ... }` — [функция с типом `suspend CoroutineScope.() -> Unit`](04-function-types.md), так что здесь работает всё, что вы уже знаете.

## Теория

**Корутина** — лёгкая задача, которую можно приостановить, не блокируя поток. Запускается строителем: `launch`, `async`, `runBlocking` (в основном для тестов и `main`).

**CoroutineScope** — область, которой принадлежат корутины. Область знает, когда её закрыть, и отменяет всё внутри.

**Job** — «ручка» корутины: состояние (`isActive`, `isCompleted`, `isCancelled`), `cancel()`, `join()`. `launch` возвращает `Job`.

**launch и async.**

| | launch | async |
| --- | --- | --- |
| Возвращает | `Job` | `Deferred<T>` (это тоже `Job`) |
| Результат | нет | `await()` |
| Исключение | сразу вверх по иерархии | при `await()` и в родителе |
| Когда | «сделать и забыть» в пределах scope | параллельно посчитать несколько значений |

```kotlin
val (a, b) = coroutineScope {
    val x = async { api.status() }
    val y = async { api.files() }
    x.await() to y.await()
}
```

Оба запроса идут параллельно, а `coroutineScope` не вернётся, пока не закончатся оба.

**Структурная конкурентность.** Корутина запущена внутри родителя:

- родитель не завершится, пока не завершатся дети;
- отмена родителя отменяет детей;
- ошибка ребёнка отменяет родителя и братьев (кроме `SupervisorJob`).

Это защита от утечек: «забытых» работ нет, пока вы запускаете в нужном scope.

**Scope на Android.**

| Scope | Живёт | Когда использовать |
| --- | --- | --- |
| `viewModelScope` | пока жива ViewModel | загрузка данных для экрана |
| `lifecycleScope` | пока жива Activity/Fragment | работа, связанная с UI (пользовательский интерфейс: всё, что видит и нажимает человек) |
| `rememberCoroutineScope()` | пока composable в композиции | запуск из обработчика клика в Compose |
| `GlobalScope` | весь процесс | почти никогда: нет владельца, нет отмены |
| свой `CoroutineScope(SupervisorJob() + Dispatchers.Default)` | пока вы не вызвали `cancel()` | сервис, репозиторий, где нужен свой жизненный цикл |

Правило: у каждой корутины есть владелец, и вы знаете, когда он умрёт.

**Отмена кооперативна.** `job.cancel()` ничего не прерывает насильно. Корутина обязана сама проверить отмену: приостанавливающая функция (`delay`, `withContext`, `await`, `emit`) её проверит сама. Тяжёлый цикл без приостановки — нет, нужны `ensureActive()` или `yield()`:

```kotlin
suspend fun crunch(items: List<Item>) {
    for (item in items) {
        ensureActive()
        heavy(item)
    }
}
```

**CancellationException** — способ сообщить об отмене. Ловить широкий `Exception` и молчать нельзя ([урок 12](12-generics-exceptions.md)). Очистку делают в `finally`; если в `finally` нужны приостанавливающие вызовы, оборачивают в `withContext(NonCancellable) { ... }`.

**Таймаут.** `withTimeout(5_000) { ... }` бросает `TimeoutCancellationException`, `withTimeoutOrNull` возвращает `null`:

```kotlin
val status = withTimeoutOrNull(3_000) { api.status() } ?: return NoNetwork
```

**Ошибки и SupervisorJob.** **M.** По умолчанию ошибка ребёнка отменяет родителя, а значит и всех братьев. Для независимых задач (три картинки загружаются, одна упала — остальные нужны) используют `supervisorScope { }` или `SupervisorJob`. В `viewModelScope` уже `SupervisorJob`, но исключение в `launch` без обработчика всё равно уронит приложение: нужен `try/catch` внутри или `CoroutineExceptionHandler` на верхнем `launch`. Для `async` исключение приходит при `await()`.

**Диспетчеры в двух словах.** `Dispatchers.Main` — UI, `IO` — сеть и диск, `Default` — вычисления. Не хардкодьте (значение, вписанное прямо в код вместо настроек или параметров) их во внутренних классах: принимайте `CoroutineDispatcher` параметром, в тесте подставляйте тестовый ([урок про тесты](../android-cis/09-tests.md)). Переключение — `withContext(Dispatchers.IO) { ... }`, не `launch(IO)` внутри `launch`.

**Лямбда как отложенное действие и корутины.** Паттерн (типовой проверенный приём решения задачи) [`pendingAction`](05-nullable-lambdas.md) заменяется на `CompletableDeferred`: `val connected = CompletableDeferred<Unit>()`, при подключении `connected.complete(Unit)`, где нужно — `connected.await()`. Тот же результат без поля и без ручного сброса. Знание обоих вариантов — на собеседовании плюс.

## Разбор на примере

Экран загружает статус. Пользователь ушёл.

```kotlin
class StatusViewModel(private val api: LampApi) : ViewModel() {
    private val _state = MutableStateFlow<UiState>(UiState.Loading)
    val state: StateFlow<UiState> = _state

    private var job: Job? = null

    fun refresh() {
        job?.cancel()                       // новый запрос заменяет старый
        job = viewModelScope.launch {
            _state.value = UiState.Loading
            _state.value = try {
                UiState.Ready(withTimeout(3_000) { api.status() })
            } catch (e: CancellationException) {
                throw e
            } catch (e: IOException) {
                UiState.Error("нет связи")
            }
        }
    }
}
```

- `viewModelScope` уничтожается вместе с ViewModel: запрос не переживёт экран.
- `job?.cancel()` — защита от гонки (гонка — ошибка, при которой результат зависит от того, какой из параллельных процессов успеет раньше) двух запросов: старый ответ не перезапишет новый.
- Таймаут и ошибка сети превращены в значения. Заметьте: `TimeoutCancellationException` — подкласс `CancellationException`, так что порядок веток важен; если вам нужно показать «таймаут», используйте `withTimeoutOrNull`.

## Упражнения

1. Запустите `launch { delay(100); println("a") }` в `runBlocking` и отмените через `job.cancel()`. Напечатается ли «a»?
2. Напишите функцию, которая параллельно считает два числа через `async` и складывает. Замерьте время для `delay(500)` в каждом: должно быть около 500 мс, не 1000.
3. Сделайте цикл `while (true) { }` без приостановки в корутине и вызовите `cancel()`. Исправьте `ensureActive()`.
4. Напишите `launch { try { delay(1000) } finally { println("чистим") } }`, отмените, посмотрите вывод.
5. Перепишите счётчик из [урока 06](06-capture-inline.md) с `AtomicInteger` и запустите 100 корутин по 1000 увеличений.
6. В `hire-scratch` найдите все `GlobalScope` и объясните, кто их владелец. Если никого, замените.
7. Устно: почему `launch(Dispatchers.IO)` внутри `viewModelScope.launch` — не нужно, а `withContext(IO)` — да?

### Самопроверка

- Объясняете, что такое владелец корутины.
- Различаете `launch` и `async`, `cancel` и `join`.
- Знаете, что отмена кооперативна.
- Не глотаете `CancellationException`.

## Типичные ошибки

- `GlobalScope.launch`.
- Новый `CoroutineScope(...)` в каждом вызове без отмены.
- `async { }` без `await()`: ошибка потеряется или приедет не туда.
- `runBlocking` в обычном коде приложения: блокирует поток.
- Широкий `catch` внутри корутины без проброса отмены.
- Тяжёлый цикл без `ensureActive()`.
- Диспетчер, прибитый гвоздями в классе, который надо тестировать.

## Чеклист

- [ ] Назовёте scope для экрана, для компонента и для работы, пережившей экран.
- [ ] Объясните структурную конкурентность одним абзацем.
- [ ] Знаете, чем `withTimeout` и `withTimeoutOrNull` различаются.
- [ ] Умеете остановить корутину и корректно почистить.

## Следующий урок

[Android: lifecycle и ViewBinding](../android-core/01-lifecycle.md).
