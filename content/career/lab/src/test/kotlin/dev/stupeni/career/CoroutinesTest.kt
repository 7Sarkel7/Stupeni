package dev.stupeni.career

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.TimeoutCancellationException

class CoroutinesTest {
    @Test
    fun backoffGrowsAndCaps() {
        assertEquals(200L, backoffMs(0))
        assertEquals(400L, backoffMs(1))
        assertEquals(800L, backoffMs(2))
        assertEquals(1_600L, backoffMs(3))
        assertEquals(3_200L, backoffMs(4))
        assertEquals(5_000L, backoffMs(5))
        assertEquals(5_000L, backoffMs(20))
        assertFailsWith<IllegalArgumentException> { backoffMs(-1) }
    }

    @Test
    fun timeoutWrapsOnlyTheTimeout() = runTest {
        assertEquals("ok", fetchWithTimeout(1_000) { "ok" }.getOrThrow())

        var called = false
        val bad = fetchWithTimeout(0) {
            called = true
            "x"
        }
        assertFalse(called)
        assertIs<IllegalArgumentException>(bad.exceptionOrNull())

        val late = fetchWithTimeout(50) {
            delay(10_000)
            "late"
        }
        assertIs<TimeoutCancellationException>(late.exceptionOrNull())

        assertFailsWith<IllegalStateException> {
            fetchWithTimeout(1_000) { error("boom") }
        }
    }

    @Test
    fun parentCancellationIsNotSwallowed() = runTest {
        val job = launch {
            fetchWithTimeout(60_000) {
                delay(60_000)
                "x"
            }
        }
        job.cancel()
        job.join()
        assertTrue(job.isCancelled)
    }
}
