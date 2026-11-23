package dev.stupeni.kotlincore

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class LambdasTest {
    @Test
    fun applyTwiceCallsFunctionTwice() {
        assertEquals(12, applyTwice(3) { it * 2 })
        assertEquals(5, applyTwice(3) { it + 1 })
    }

    @Test
    fun repeatIndexedPassesIndexes() {
        val seen = mutableListOf<Int>()
        repeatIndexed(3) { seen += it }
        assertEquals(listOf(0, 1, 2), seen)
        repeatIndexed(0) { seen += 99 }
        repeatIndexed(-2) { seen += 99 }
        assertEquals(listOf(0, 1, 2), seen)
    }

    @Test
    fun composeRunsFirstThenSecond() {
        val f = compose({ it + 1 }, { it * 10 })
        assertEquals(40, f(3))
    }

    @Test
    fun counterKeepsOwnState() {
        val a = makeCounter(5)
        val b = makeCounter(100)
        assertEquals(5, a())
        assertEquals(6, a())
        assertEquals(100, b())
        assertEquals(7, a())
    }

    @Test
    fun nullableCallbackIsSafe() {
        val got = mutableListOf<String>()
        assertTrue(notifyIfPresent({ got += it }, "готово"))
        assertFalse(notifyIfPresent(null, "никто не слушает"))
        assertEquals(listOf("готово"), got)
    }

    @Test
    fun firstSuccessStopsAtFirstNonNull() {
        val calls = mutableListOf<Int>()
        val result = firstSuccess(5) { i ->
            calls += i
            if (i == 2) "ok$i" else null
        }
        assertEquals("ok2", result)
        assertEquals(listOf(0, 1, 2), calls)
    }

    @Test
    fun firstSuccessGivesUp() {
        var calls = 0
        assertNull(firstSuccess<String>(3) { calls++; null })
        assertEquals(3, calls)
        assertNull(firstSuccess<String>(0) { "never" })
    }
}
