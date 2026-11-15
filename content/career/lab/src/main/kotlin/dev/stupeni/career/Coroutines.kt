package dev.stupeni.career

fun backoffMs(attemptIndex: Int): Long = TODO("C3: backoffMs")

suspend fun fetchWithTimeout(timeoutMs: Long, block: suspend () -> String): Result<String> =
    TODO("C3: fetchWithTimeout")
