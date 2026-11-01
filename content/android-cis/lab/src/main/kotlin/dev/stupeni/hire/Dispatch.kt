package dev.stupeni.hire

import kotlinx.coroutines.CoroutineDispatcher

enum class WorkKind { Ui, Io, Cpu }

fun dispatcherFor(kind: WorkKind): String = TODO("A2: dispatcherFor")

suspend fun <T> switchFor(
    kind: WorkKind,
    io: CoroutineDispatcher,
    cpu: CoroutineDispatcher,
    block: suspend () -> T,
): T = TODO("A2: switchFor")
