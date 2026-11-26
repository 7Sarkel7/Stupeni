# Extension-функции и свойства

**Модуль:** K. Kotlin под всё остальное  
**Уровень:** J  
**Время:** около 35 минут  
**Лаборатория:** `OperatorsTest.initialsTakesFirstLettersUppercase`, `secondOrNull`  
**Намёк:** [solutions/hint-operators.md](solutions/hint-operators.md)  
**Дальше:** [Классы: data, sealed, enum, object, companion](11-classes-objects.md)

## Цель

Объявить функцию, которая выглядит как метод чужого класса. Понять, что это статический вызов, а не изменение класса. Узнать extension в стандартной библиотеке и Compose.

## Зачем это вам

`list.map { }`, `string.toIntOrNull()`, `Modifier.padding(8.dp)`, `context.dataStore` — всё это extension. Они же стоят за DSL (мини-язык внутри основного, заточенный под одну задачу) и за функциями с получателем из [урока 04](04-function-types.md). Своя extension делает код читаемым без наследования.

## Теория

```kotlin
fun String.lastChar(): Char = this[length - 1]

"станция".lastChar()   // 'я'
```

`String.` перед именем — **получатель** (receiver). Внутри `this` — строка, на которой вызвали. `this.` можно опустить.

**Это не изменение класса.** Компилятор превращает extension в обычную статическую функцию с первым параметром `this`. Поэтому:

- extension **не видит** `private` членов класса;
- extension **не переопределяет** члены: если у класса есть метод с тем же именем, побеждает метод;
- вызов определяется **статическим типом** переменной, не фактическим: `val a: Base = Derived()` вызовет extension для `Base`.

**Nullable-получатель (nullable — тип, значение которого может быть `null`).** `fun String?.orDash(): String = this ?: "—"` вызывается и на `null`: `name.orDash()`. Так устроен `isNullOrEmpty()`.

**Generic.** `fun <T> List<T>.secondOrNull(): T? = if (size >= 2) this[1] else null`.

**Extension-свойства.** Без поля, только геттер (геттер, сеттер — код, который читает или записывает значение свойства):

```kotlin
val String.isIp: Boolean get() = Regex("""\d{1,3}(\.\d{1,3}){3}""").matches(this)
```

**Функции с получателем в параметрах.** Тип `Builder.() -> Unit` — лямбда, внутри которой `this` равен `Builder`. Свои DSL строятся так:

```kotlin
class Report { val lines = mutableListOf<String>(); fun line(s: String) { lines += s } }

fun report(block: Report.() -> Unit): Report = Report().apply(block)

val r = report {
    line("статус: ok")
    line("файлов: 3")
}
```

Это тот же приём, что в `apply` и в Compose: `Column { Text("a") }` — вызов функции с лямбдой-получателем.

**Где держать.** Файл с extension, относящимся к одной теме: `StringExt.kt`, `FlowExt.kt`. Не складывайте всё в `Utils.kt`: через год это помойка.

**Когда не нужно.** Если функция меняет состояние чужого объекта или нужна приватная деталь, пишите метод или обычную функцию. Extension — для чистых преобразований и удобных обёрток.

## Разбор на примере

Показ времени работы платы:

```kotlin
fun Long.asUptime(): String {
    val seconds = this / 1000
    return "%d:%02d".format(seconds / 60, seconds % 60)
}

status.uptimeMs.asUptime()
```

Объект и функция живут отдельно: `Long` стандартный, правило форматирования ваше. На месте вызова читается как метод.

Плохой пример: `fun Any.log(msg: String)` — засоряет автодополнение каждого объекта.

## Упражнения

1. Напишите `fun String.initials(): String`: первые буквы слов в верхнем регистре, пробелы по краям и повторные пробелы игнорируются, пустая строка — пустая. Запустите `initialsTakesFirstLettersUppercase`.
2. Напишите `fun <T> List<T>.secondOrNull(): T?` и запустите `secondOrNull`.
3. Объявите `val String.isIp: Boolean` и проверьте на `"192.168.10.1"`.
4. Создайте `fun String?.orDash()` и вызовите на `null`.
5. Напишите свой мини-DSL `report { line(...) }` из разбора и добавьте `section("Заголовок") { line(...) }`.
6. Проверьте, что при одинаковом имени побеждает метод класса: объявите `fun String.toString(): String = "ext"` и прочитайте предупреждение компилятора: extension скрыта членом.
7. Найдите в стандартной библиотеке три extension, которые вы уже использовали, не зная, что они extension.

### Самопроверка

- Объясняете, что extension — статический вызов и поэтому не видит `private`.
- Пишете функцию с получателем: `Receiver.() -> Unit`.

## Типичные ошибки

- Ждать полиморфизма от extension.
- `Any.xxx()` и другие extension на всех подряд.
- Один `Utils.kt` на всё.
- Extension, которая скрыто ходит в сеть или читает глобальное состояние.
- Одинаковые имена в разных пакетах без явного импорта.

## Чеклист

- [ ] Написали extension-функцию и extension-свойство.
- [ ] Знаете три ограничения extension.
- [ ] Написали мини-DSL на `Receiver.() -> Unit`.
- [ ] `OperatorsTest` для `initials` и `secondOrNull` зелёный.

## Следующий урок

[Классы: data, sealed, enum, object, companion](11-classes-objects.md).
