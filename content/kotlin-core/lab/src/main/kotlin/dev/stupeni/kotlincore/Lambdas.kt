package dev.stupeni.kotlincore

fun applyTwice(x: Int, f: (Int) -> Int): Int = TODO("K: applyTwice")

fun repeatIndexed(times: Int, action: (Int) -> Unit): Unit = TODO("K: repeatIndexed")

fun compose(first: (Int) -> Int, second: (Int) -> Int): (Int) -> Int = TODO("K: compose")

fun makeCounter(start: Int): () -> Int = TODO("K: makeCounter")

fun notifyIfPresent(callback: ((String) -> Unit)?, message: String): Boolean =
    TODO("K: notifyIfPresent")

fun <T> firstSuccess(maxAttempts: Int, attempt: (Int) -> T?): T? = TODO("K: firstSuccess")
