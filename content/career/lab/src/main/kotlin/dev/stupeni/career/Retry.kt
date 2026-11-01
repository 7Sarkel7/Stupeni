package dev.stupeni.career

data class Attempt(
    val method: Method,
    val code: Int?,
    val networkFailed: Boolean,
)

fun shouldRetry(attempt: Attempt, attemptIndex: Int, maxAttempts: Int): Boolean =
    TODO("C2: shouldRetry")
