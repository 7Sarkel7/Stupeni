# kotlinx.serialization: JSON в типы

**Модуль:** A. Android: что ещё спрашивают  
**Уровень:** J, полиморфизм — **M.**  
**Время:** около 45 минут  
**Лаборатория:** нет, JVM-тест в `hire-scratch`  
**Намёк:** нет  
**Дальше:** [Runtime-разрешения](03-permissions.md)

## Цель

Описать ответ сервера как `@Serializable data class`, разобрать и собрать JSON, настроить `Json` так, чтобы новое поле на сервере не роняло пульт, и подключить это к Retrofit.

## Зачем это вам

[Урок JSON](../01-fundamentals/03-json.md) учил читать JSON глазами и руками. В приложении его превращают в типы автоматически. На 2026 год стандарт для нового Kotlin-кода — `kotlinx.serialization`: он без рефлексии, работает на JVM и в KMP. Gson и Moshi встретите в старых проектах, поэтому ниже сказано, чем они отличаются.

## Теория

**Подключение.** В `build.gradle.kts` плагин и зависимость; номера берут со страницы [kotlinx.serialization](https://github.com/Kotlin/kotlinx.serialization), не из урока:

```kotlin
plugins {
    kotlin("plugin.serialization") version "<версия Kotlin>"
}
dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:<версия>")
}
```

Версия плагина совпадает с версией Kotlin.

**Модель.**

```kotlin
@Serializable
data class Status(
    val ip: String,
    @SerialName("uptime_ms") val uptimeMs: Long,
    val firmware: String? = null,
)
```

- `@Serializable` включает генерацию кода при сборке.
- `@SerialName` связывает имя в JSON с именем в Kotlin.
- Значение по умолчанию делает поле необязательным: если его нет в JSON, подставится оно.
- `String?` без значения по умолчанию всё равно **обязательно присутствует** в JSON, пусть `null`. Для необязательного нужно `= null`.

**Разбор и сборка.**

```kotlin
val json = Json { ignoreUnknownKeys = true }

val status = json.decodeFromString<Status>("""{"ip":"1.2.3.4","uptime_ms":5000}""")
val text = json.encodeToString(status)
```

Конфигурируйте один `Json` и переиспользуйте.

**Настройки, которые нужны чаще всего.**

| Опция | Зачем |
| --- | --- |
| `ignoreUnknownKeys = true` | сервер добавил поле — клиент не падает |
| `coerceInputValues = true` | `null` или неизвестный enum заменяются значением по умолчанию |
| `explicitNulls = false` | не писать `null` при сборке и не требовать при разборе |
| `encodeDefaults = true` | писать поля со значениями по умолчанию |
| `isLenient = true` | терпеть кавычки там, где их нет; **не включайте без причины** |

Принцип: на клиенте мягкость к чужим добавлениям, строгость к обязательным полям. Тихая подмена обязательного значения хуже падения: ошибку находят в логе, а не у пользователя.

**Ошибки.** Неверный JSON бросает `SerializationException`, а подходящий по синтаксису, но не по схеме — `MissingFieldException` (подкласс). Ловите на границе слоя и превращайте в значение ошибки ([урок 12](../kotlin-core/12-generics-exceptions.md)); `IllegalArgumentException` тоже возможен при неверном значении.

**Enum и sealed.** Enum сериализуется по имени, `@SerialName` на вариантах задаёт строку. Неизвестное значение с `coerceInputValues` и значением по умолчанию не уронит разбор. Для `sealed` — полиморфизм с полем-дискриминатором `type` (**M.**): `@Serializable sealed interface Event`, варианты помечены `@SerialName("done")`.

**Retrofit.** Конвертер для `kotlinx.serialization` входит в семейство Retrofit (`converter-kotlinx-serialization`):

```kotlin
val contentType = "application/json".toMediaType()
val retrofit = Retrofit.Builder()
    .baseUrl("http://192.168.10.1/")
    .client(okHttp)
    .addConverterFactory(json.asConverterFactory(contentType))
    .build()
```

Интерфейс API: `@GET("api/status") suspend fun status(): Status`. Как собирается весь слой данных — [Retrofit, Room, DataStore](../android-cis/07-data.md).

**Отличия от Gson и Moshi.** Gson работает рефлексией и молча ставит `null` в `non-null` поле Kotlin: приложение падает позже и в другом месте. Moshi строже и поддерживает Kotlin, через кодоген или рефлексию. `kotlinx.serialization` проверяет схему при разборе. В старом проекте их не переписывают, новые модели пишут на `kotlinx.serialization`.

**Не доверяйте ответу.** Валидация: значения вне диапазона, пустая строка там, где ждали IP. Разбор типов не заменяет проверку смысла: [`require`](../kotlin-core/12-generics-exceptions.md) в `init` модели или отдельная функция.

## Разбор на примере

Плата ответила на `GET /v1/reading`:

```json
{"ip":"192.168.10.1","uptime_ms":123456,"firmware":"1.2","new_field":true}
```

Модель из теории с `ignoreUnknownKeys = true` разберёт это без ошибки: `new_field` игнорируется. Без этой опции — `SerializationException`, и пульт после обновления прошивки перестаёт работать.

Тест на JVM:

```kotlin
@Test
fun parsesStatusWithUnknownField() {
    val status = json.decodeFromString<Status>(
        """{"ip":"1.2.3.4","uptime_ms":1,"extra":1}"""
    )
    assertEquals(1L, status.uptimeMs)
    assertNull(status.firmware)
}

@Test
fun missingRequiredFieldFails() {
    assertFailsWith<SerializationException> {
        json.decodeFromString<Status>("""{"ip":"1.2.3.4"}""")
    }
}
```

## Упражнения

1. Опишите по примеру из [урока JSON](../01-fundamentals/03-json.md) свою модель и разберите ответ из `curl`.
2. Включите и отключите `ignoreUnknownKeys` и посмотрите на ошибку.
3. Сделайте поле `firmware: String?` без значения по умолчанию и разберите JSON без него. Что за исключение?
4. Добавьте `enum class Mode { Auto, Manual }` с `@SerialName` и пришлите неизвестное значение. Включите `coerceInputValues` с дефолтом.
5. Напишите два JVM-теста по образцу выше.
6. Подключите конвертер к Retrofit и вызовите `suspend fun status()` против `MockWebServer`.
7. Устно: чем `ignoreUnknownKeys` помогает, а чем может мешать (скрывает опечатку в имени поля).

### Самопроверка

- Объясняете разницу между необязательным и nullable полем.
- Знаете три опции `Json` и зачем каждая.
- Понимаете, почему на границе ловят `SerializationException`.

## Типичные ошибки

- Забыть плагин `kotlin("plugin.serialization")`: `@Serializable` ничего не делает.
- Создавать новый `Json` на каждый вызов.
- `isLenient = true` «на всякий случай».
- `String?` без значения по умолчанию и надежда, что поле необязательное.
- Нет теста на ответ с лишним полем.
- Доверять разобранным значениям без проверки диапазона.

## Чеклист

- [ ] `@Serializable`, `@SerialName`, значения по умолчанию.
- [ ] Настроенный общий `Json`.
- [ ] Тест на лишнее и на отсутствующее поле.
- [ ] Конвертер для Retrofit.

## Следующий урок

[Runtime-разрешения](03-permissions.md).
