---
title: "Читаем официальные доки"
sidebar_position: 3
lesson: cis-flow
---

# Читаем официальные доки

В тексте главы ответов на эти вопросы **нет**. Их надо найти в официальной документации. Так вы учитесь читать доки, а это половина работы Android-разработчика.

**Правила:**

- Ответ — своими словами, 1–3 предложения, плюс **цитата одной строкой** из доки (в кавычках, с названием раздела).
- Записывайте в файл `notes/flow.md` своего репозитория (см. [практику](./practice.md)).
- Если страница на английском, это нормально: ищите нужное слово, ключевые термины даны ниже.
- Если страница и эта глава расходятся, верна страница. Напишите об этом в сдаче.

## Вопросы

**1. `StateFlow` и `SharedFlow`: когда что.**
Страница: [StateFlow и SharedFlow на Android](https://developer.android.com/kotlin/flow/stateflow-and-sharedflow).
Что искать: слова *conflated*, *replay*, *initial value*.
Вопрос: что такое `replay` у `SharedFlow`, и чему он равен у `StateFlow`?

**2. Сколько живёт сбор потока в интерфейсе.**
Страница: [Flow на Android](https://developer.android.com/kotlin/flow).
Что искать: *lifecycle*, `repeatOnLifecycle`, `collectAsStateWithLifecycle`.
Вопрос: чем `collectAsStateWithLifecycle` отличается от `collectAsState`? В каком состоянии жизненного цикла сбор идёт?

**3. Отмена корутин.**
Страница: [Cancellation and timeouts](https://kotlinlang.org/docs/cancellation-and-timeouts.html).
Что искать: *cooperative*, `CancellationException`.
Вопрос: почему отмена корутины «кооперативная»? Что произойдёт с корутиной, которая считает в цикле без `suspend`-вызовов, если её отменить?

**4. Холодный поток и `flowOn`.**
Страница: [Flow, раздел Flow context](https://kotlinlang.org/docs/flow.html).
Что искать: *context preservation*, `flowOn`.
Вопрос: что делает `flowOn`, и почему нельзя менять диспетчер внутри `flow { }` вызовом `withContext`?

**5. `stateIn`** (необязательный, уровень M).
Страница: [StateFlow и SharedFlow на Android](https://developer.android.com/kotlin/flow/stateflow-and-sharedflow) (искать `stateIn`).
Вопрос: за что отвечает стратегия `SharingStarted.WhileSubscribed(5000)` и зачем пять секунд?

## Как понять, что ответ хороший

- Он отвечает на вопрос, а не пересказывает страницу.
- Есть цитата, которую можно найти по ссылке.
- Есть пример из жизни или из кода (хоть строчка).

Ключ для ревьюера хранится отдельно и ученику не показывается.

Дальше: [практика](./practice.md).
