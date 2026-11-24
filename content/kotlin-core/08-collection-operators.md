# Операторы коллекций: map, filter, groupBy и друзья

**Модуль:** K. Kotlin под всё остальное  
**Уровень:** J  
**Время:** около 45 минут  
**Лаборатория:** `OperatorsTest.averageByDevice`  
**Намёк:** [solutions/hint-operators.md](solutions/hint-operators.md)  
**Дальше:** [Scope-функции: let, run, apply, also, with](09-scope-functions.md)

## Цель

Описывать обработку списка цепочкой операторов, а не циклом с мутабельной переменной. Знать десяток операторов и разницу между `List` и `Sequence`.

## Зачем это вам

Лямбды — это в первую очередь операторы коллекций. [Урок про коллекции в карьерном треке](../career/01-collections.md) учит выбирать `List`, `Set`, `Map` и писать цикл руками. Здесь следующий шаг: как обрабатывать данные после выбора. На ревью ожидают `map { }` и `filter { }`, а в тестовом задании — понимание, что внутри них.

## Теория

Оператор берёт коллекцию и лямбду, возвращает **новую** коллекцию или значение. Исходная не меняется.

| Оператор | Что делает | Пример |
| --- | --- | --- |
| `map { }` | преобразует каждый элемент | `names.map { it.length }` |
| `filter { }` / `filterNot` | оставляет подходящие | `readings.filter { it > 20 }` |
| `mapNotNull { }` | map и выброс `null` | `lines.mapNotNull { parse(it) }` |
| `forEach { }` | действие над каждым, результата нет | `items.forEach { log(it) }` |
| `any / all / none { }` | булев ответ по условию | `errors.any { it.fatal }` |
| `count { }` | сколько подошло | `files.count { it.isNew }` |
| `find / firstOrNull { }` | первый подходящий или `null` | `devices.find { it.ip == ip }` |
| `first / single` | первый или единственный, иначе исключение | осторожно: падают на пустом |
| `sortedBy { }` / `sortedByDescending` | сортировка по ключу | `files.sortedBy { it.name }` |
| `groupBy { }` | `Map<Ключ, List<Элемент>>` | `readings.groupBy { it.device }` |
| `associateBy { }` | `Map<Ключ, Элемент>`, последний выигрывает | `devices.associateBy { it.ip }` |
| `partition { }` | пара: подошли и не подошли | `val (ok, bad) = list.partition { it.ok }` |
| `flatMap { }` | map, где результат — список; всё склеивается | `rooms.flatMap { it.devices }` |
| `fold(init) { acc, x -> }` / `reduce` | свёртка в одно значение | `list.fold(0) { s, x -> s + x }` |
| `sumOf { }` | сумма по ключу | `files.sumOf { it.size }` |
| `take / drop / takeWhile` | срезы | `list.take(3)` |
| `distinct / distinctBy { }` | убрать повторы | `paths.distinct()` |
| `zip` | пары двух списков | `names.zip(ips)` |
| `windowed / chunked` | окна и порции | `list.chunked(10)` |

**Цепочка.** Оператор возвращает коллекцию, и следующий вызывается на ней:

```kotlin
val avgs = readings
    .filter { it.celsius != null }
    .groupBy { it.device }
    .mapValues { (_, list) -> list.map { it.celsius!! }.average() }
```

Читается сверху вниз как рецепт. Но смотрите, что внутри: `!!` в третьей строке. Его убирает `mapNotNull { it.celsius }`: оператор и выбросит `null`, и сменит тип на `Double`. Лучшие операторы часто те, что убирают `!!`.

**Map как коллекция.** `map.filter { (key, value) -> ... }`, `mapValues`, `mapKeys`, `filterValues`. `forEach { (k, v) -> }` — деструктуризация пары.

**Список против Sequence.** Каждый оператор `List` создаёт промежуточный список. Для тысяч элементов и длинной цепочки это лишние копии. `asSequence()` делает ленивую цепочку: элементы проходят через все шаги по одному, а вычисления начинаются только на терминальном операторе (`toList`, `first`, `count`).

```kotlin
val firstBig = hugeList.asSequence().filter { it > 100 }.map { it * 2 }.first()
```

Для короткого списка на экране `List` быстрее и проще. `Sequence` нужен для больших данных или когда нужен только первый результат.

**Исключения.** `first()` на пустом списке падает; `firstOrNull()` не падает. `average()` для пустого списка даёт `NaN`, не ошибку. `sorted()` для `Double` с `NaN` ведёт себя неочевидно. Пустая коллекция — отдельный тест.

**Порядок и изменяемость.** `groupBy` сохраняет порядок первого появления ключа. `toSet()` теряет повторы, но не обещает порядок для вас. Оператор не должен менять внешнюю переменную: `list.map { total += it }` — запах, для этого есть `sumOf` или `fold`.

## Разбор на примере

Показания датчиков, часть `null`:

```kotlin
data class Reading(val device: String, val celsius: Double?)

fun hotDevices(readings: List<Reading>, limit: Double): List<String> =
    readings
        .mapNotNull { r -> r.celsius?.let { r.device to it } }
        .filter { (_, t) -> t > limit }
        .map { (device, _) -> device }
        .distinct()
        .sorted()
```

Шаги: отбросить `null`, оставить горячие, оставить только имена, убрать повторы, отсортировать. Про `?.let` — [следующий урок](09-scope-functions.md).

Тот же текст циклом занял бы десять строк и две `mutableList`. Но у цикла есть своё место: когда нужен ранний выход или несколько результатов за один проход. Выбирайте читаемое.

## Упражнения

В `Scratch.kt` и в лаборатории.

1. `val xs = listOf(1, 2, 3, 4, 5, 6)`. Одной цепочкой получите сумму квадратов чётных чисел.
2. Из `listOf("a=1", "b=2", "oops", "c=3")` получите `Map<String, Int>`: пропустите строки без `=`.
3. Дан список файлов с полем `ext`. Узнайте, сколько файлов каждого расширения (`groupBy`, `mapValues`). Затем то же через `groupingBy().eachCount()` — на вкус.
4. Чем `associateBy { it.id }` отличается от `groupBy { it.id }`, если id повторяются?
5. Реализуйте `averageByDevice` в `Operators.kt`: среднее по `celsius`, `null` пропускать, устройство без данных не попадает в карту. `./gradlew test --tests dev.stupeni.kotlincore.OperatorsTest.averageSkipsNullsAndDevicesWithoutData`.
6. Перепишите цикл `for` из своего прошлого кода (например, подсчёт слов из [урока коллекций](../career/01-collections.md)) оператором. Читается ли лучше? Запишите, когда нет.
7. Вызовите `emptyList<Int>().first()` и `.firstOrNull()`. Затем `emptyList<Int>().average()`.

### Самопроверка

- Для «посчитать», «сгруппировать», «найти первый», «разбить на две части» вы называете оператор без подсказки.
- Объясняете, когда цепочка лучше цикла и когда нет.
- Знаете, что `Sequence` ленивая.

## Типичные ошибки

- `!!` внутри цепочки, когда есть `mapNotNull`.
- Менять внешнюю переменную внутри `map` или `filter`.
- `first()` вместо `firstOrNull()` на списке, который может быть пустым.
- Сортировать каждый раз в `Composable` без `remember`.
- Класть `Sequence` в состояние экрана: ленивая последовательность перечитает источник заново.
- Сто операторов подряд без промежуточных имён: читать невозможно.

## Чеклист

- [ ] Десяток операторов вы знаете без шпаргалки.
- [ ] Знаете, что вернёт `groupBy`, `associateBy`, `partition`.
- [ ] `averageByDevice` пишете одной цепочкой.
- [ ] Знаете `List` против `Sequence`.

## Следующий урок

[Scope-функции: let, run, apply, also, with](09-scope-functions.md).
