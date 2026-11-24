# Классы: data, sealed, enum, object, companion, интерфейсы

**Модуль:** K. Kotlin под всё остальное  
**Уровень:** J  
**Время:** около 50 минут  
**Лаборатория:** нет, `Scratch.kt`  
**Намёк:** [solutions/README.md](solutions/README.md)  
**Дальше:** [Generics и исключения](12-generics-exceptions.md)

## Цель

Выбрать нужную форму класса: `data`, `sealed`, `enum`, `object`, `companion object`, интерфейс. Написать состояние экрана на `sealed` и разобрать его через `when`.

## Зачем это вам

Состояние экрана — `sealed interface UiState`. Модель из JSON — `data class`. Команда пульта — `enum` или `sealed`. Синглтон — `object`. Зависимость — интерфейс. Это словарь, на котором говорит весь Android-код.

[Урок моделей](../career/02-models.md) разбирает `data class` и sealed на задачах пульта. Здесь короткая карта всех форм.

## Теория

**Обычный класс.** Первичный конструктор в заголовке, `val`/`var` делают параметры свойствами.

```kotlin
class Device(val ip: String, var name: String)
```

Классы в Kotlin `final` по умолчанию. Наследовать можно только `open`.

**data class.** Для хранения данных. Компилятор генерирует `equals`, `hashCode`, `toString`, `copy`, `componentN` для деструктуризации.

```kotlin
data class Status(val ip: String, val uptimeMs: Long)
val a = Status("1.2.3.4", 10)
val b = a.copy(uptimeMs = 20)
a == Status("1.2.3.4", 10)  // true: сравнивает поля
val (ip, up) = a
```

Правила: хотя бы один параметр в конструкторе; сравнивается то, что в конструкторе. Неизменяемость (`val`) — обычай, который ловит гонки.

**enum class.** Фиксированный набор значений без данных (или с одинаковым набором полей): `enum class Link { Idle, Online }`. Есть `entries`, `name`, `ordinal`, `valueOf`. Хорош для режима, цвета, фиксированной команды.

**sealed class / sealed interface.** Закрытая иерархия: все наследники известны на этапе компиляции и лежат в одном пакете и модуле. Каждый вариант может нести свои данные.

```kotlin
sealed interface UiState {
    data object Loading : UiState
    data class Ready(val files: List<String>) : UiState
    data class Error(val message: String) : UiState
}

fun render(state: UiState) = when (state) {
    UiState.Loading -> "загрузка"
    is UiState.Ready -> "файлов: ${state.files.size}"
    is UiState.Error -> state.message
}
```

`when` без `else` проверяется на полноту: новый вариант сломает сборку, а не забудется. Разница с `enum`: у `enum` значение одно на всех, у `sealed` каждый вариант создаётся с собственными данными.

**object.** Единственный экземпляр, ленивый и потокобезопасный: `object Logger { fun d(msg: String) = println(msg) }`. `data object` — для `toString` без шума. Не злоупотребляйте: синглтон с изменяемым состоянием — глобальная переменная, и тесты о неё спотыкаются. На Android граф зависимостей строит Hilt ([урок](../android-cis/05-hilt.md)).

**companion object.** «Статика» класса:

```kotlin
class Device private constructor(val ip: String) {
    companion object {
        const val DEFAULT_PORT = 80
        fun fromIp(ip: String): Device? = if (ip.isNotBlank()) Device(ip) else null
    }
}
Device.fromIp("1.2.3.4")
```

Companion — настоящий объект, он может реализовывать интерфейс. `const val` только для примитивов и строк. Фабричный метод в companion — идиома, когда конструктор скрыт.

**Интерфейсы.** Контракт: `interface Repository { suspend fun load(): Status }`. Могут иметь реализацию методов по умолчанию и свойства без хранилища. Класс реализует несколько. Интерфейс отделяет «что» от «как» и позволяет подставить подделку в тесте. Интерфейс из одного метода — кандидат на `fun interface` ([урок 04](04-function-types.md)).

**Абстрактные классы.** `abstract class` — когда нужна общая часть состояния. По умолчанию выбирают интерфейс, наследование — когда общая реализация оправдана.

**Видимость.** `public` по умолчанию, `internal` — в модуле, `private` — в файле или классе, `protected` — для потомков.

**Свойства.** Геттер и сеттер пишут, когда есть логика: `val isOnline: Boolean get() = state == Link.Online`. Нет `getX()` и `setX()` в привычном виде.

## Разбор на примере

Ответ пульта: ok, ошибка сети, ошибка кода.

```kotlin
sealed interface Reply {
    data class Ok(val body: String) : Reply
    data class HttpError(val code: Int) : Reply
    data object NoNetwork : Reply
}

fun Reply.toText(): String = when (this) {
    is Reply.Ok -> "ок"
    is Reply.HttpError -> if (code == 400) "плохая команда" else "ошибка $code"
    Reply.NoNetwork -> "нет связи"
}
```

В `is Reply.HttpError` умное приведение уже сработало: `code` доступен без `as`. Попробуйте добавить `Timeout` и посмотрите, где сборка сломается.

## Упражнения

1. Объявите `data class Point(val x: Int, val y: Int)`. Сравните две равные точки через `==` и `===`. Сделайте `copy(x = 5)` и деструктурируйте.
2. Напишите `enum class Command(val path: String)` с тремя командами и найдите по `path` через `entries.firstOrNull`.
3. Сделайте `sealed interface UiState` из теории и функцию `render`. Добавьте четвёртый вариант и прочитайте сообщение компилятора.
4. Реализуйте `Device` с приватным конструктором и фабрикой в `companion object`, которая возвращает `null` на пустой IP.
5. Объявите `interface Clock { fun now(): Long }`, боевую и тестовую реализации. Передайте часы в класс.
6. Устно: когда `enum`, когда `sealed`? (Фиксированный набор без индивидуальных данных — `enum`; варианты с разными данными — `sealed`.)
7. Вспомните, где у вас был бы `object` как глобальная переменная, и как это заменить передачей зависимости.

### Самопроверка

- Сравнение `data class` объясняете на примере.
- Выбираете `enum` или `sealed` под задачу.
- Показываете, что `when` по `sealed` проверяет полноту.

## Типичные ошибки

- `data class` с `var` и изменением после помещения в `Set` или ключ `Map`: `hashCode` поменялся.
- `else` в `when` по `sealed`, который прячет новый вариант.
- `object` с изменяемым состоянием, из-за которого тесты влияют друг на друга.
- Наследование ради переиспользования двух строк.
- `companion object` с десятком несвязанных функций вместо файла-утилиты.
- `lateinit` вместо параметра конструктора.

## Чеклист

- [ ] Знаете, что генерирует `data class`.
- [ ] Умеете выбрать `enum`, `sealed`, `object`, `companion`, интерфейс.
- [ ] `UiState` на `sealed` написали сами.
- [ ] Видели, как `when` ловит забытый вариант.

## Следующий урок

[Generics и исключения](12-generics-exceptions.md).
