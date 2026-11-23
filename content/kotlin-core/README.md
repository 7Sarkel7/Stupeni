# K. Kotlin: основа и лямбды

Отдельный трек про язык. Он закрывает то, на чём спотыкаются на скрининге и в чужом коде: null-safety, `when`, **лямбды и функции высшего порядка**, nullable-колбэки, коллекции и их операторы, scope-функции, extension, классы, исключения, `Job` и `scope`. Уроки не привязаны к одному проекту: примеры взяты из пульта станца и лампы DeskNode, но руками пишутся в `Scratch.kt` и в лаборатории.

Открывайте, когда [модуль 01](../01-fundamentals/README.md) пройден. Уроки K1–K2 можно пролистать, если `?.`, `?:`, `when` и значения по умолчанию уже автоматизм. Лямбды (K3–K7) читают подряд: у каждого урока следующий опирается на предыдущий. Рядом с модулем 02 это не замена, а опора: Compose и корутины целиком держатся на лямбдах.

Цель — читать и писать `(() -> Unit)?`, `list.filter { }`, `viewModelScope.launch { }` без догадок. В текстах нет коммерческих лет, которых не было.

## Порядок

| Урок | Тема | Уровень |
| --- | --- | --- |
| [01](01-basics.md) | `val`/`var`, типы, null-safety, `lateinit`, `lazy` | J |
| [02](02-control-functions.md) | `if`, `when`, циклы, функции, именованные аргументы | J |
| [03](03-lambda-syntax.md) | Лямбды: синтаксис, `it`, trailing lambda, `return@` | J |
| [04](04-function-types.md) | Функциональные типы, функции высшего порядка, ссылки `::` | J |
| [05](05-nullable-lambdas.md) | `(() -> Unit)?`, `?.invoke()`, отложенное действие `pendingAction` | J |
| [06](06-capture-inline.md) | Захват переменных, утечки, `inline` | J, кусок M |
| [07](07-homework-lambdas.md) | Самостоятельная: `LambdasTest`, `PendingLinkTest` | J |
| [08](08-collection-operators.md) | `map`, `filter`, `groupBy`, `fold`, `Sequence` | J |
| [09](09-scope-functions.md) | `let`, `run`, `apply`, `also`, `with` | J |
| [10](10-extensions.md) | Extension-функции, функции с получателем, мини-DSL | J |
| [11](11-classes-objects.md) | `data`, `sealed`, `enum`, `object`, `companion`, интерфейсы | J |
| [12](12-generics-exceptions.md) | Generics, исключения, `Result`, `CancellationException` | J, кусок M |
| [13](13-job-scope.md) | `Job`, `scope`, `launch`/`async`, отмена, таймаут | J, кусок M |

После 13 урока идёт [Android: что ещё спрашивают](../android-core/README.md) или [стек найма для СНГ](../android-cis/README.md).

## Лаборатория

`lab` — Gradle-проект без Android, как в [карьерном треке](../career/lab/README.md). Заготовки с `TODO(...)`, тесты красные до вашей реализации. JDK 21.

```bash
cd content/kotlin-core/lab
./gradlew test --tests dev.stupeni.kotlincore.LambdasTest
./gradlew test --tests dev.stupeni.kotlincore.PendingLinkTest
./gradlew test --tests dev.stupeni.kotlincore.OperatorsTest
```

| Урок | Класс теста |
| --- | --- |
| 03–06, 07 | `LambdasTest` (`applyTwice`, `repeatIndexed`, `compose`, `makeCounter`, `notifyIfPresent`, `firstSuccess`) |
| 05, 07 | `PendingLinkTest` (отложенное действие, повторный запрос, обрыв) |
| 08, 10 | `OperatorsTest` (`averageByDevice`, `initials`, `secondOrNull`) |

Намёки без кода — в [solutions](solutions/README.md). Открывайте после своей попытки примерно в 40 минут.

Проверка в приложении — четыре–пять вопросов. Она не заменяет лабораторную и упражнения.
