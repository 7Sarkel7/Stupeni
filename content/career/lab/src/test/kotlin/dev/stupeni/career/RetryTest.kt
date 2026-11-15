package dev.stupeni.career

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class RetryTest {
    @Test
    fun stopsWhenNoAttemptsRemain() {
        val network = Attempt(Method.GET, null, networkFailed = true)
        assertFalse(shouldRetry(network, attemptIndex = 0, maxAttempts = 1))
        assertFalse(shouldRetry(network, attemptIndex = 2, maxAttempts = 3))
        assertFalse(shouldRetry(network, attemptIndex = -1, maxAttempts = 3))
        assertFalse(shouldRetry(network, attemptIndex = 0, maxAttempts = 0))
    }

    @Test
    fun retriesNetworkAndOverloadedCodes() {
        assertTrue(
            shouldRetry(
                Attempt(Method.POST, null, networkFailed = true),
                attemptIndex = 0,
                maxAttempts = 3,
            ),
        )
        assertTrue(
            shouldRetry(
                Attempt(Method.POST, 503, networkFailed = false),
                attemptIndex = 1,
                maxAttempts = 3,
            ),
        )
        assertTrue(
            shouldRetry(
                Attempt(Method.POST, 429, networkFailed = false),
                attemptIndex = 0,
                maxAttempts = 2,
            ),
        )
    }

    @Test
    fun retries500OnlyForGet() {
        assertTrue(
            shouldRetry(
                Attempt(Method.GET, 500, networkFailed = false),
                attemptIndex = 0,
                maxAttempts = 3,
            ),
        )
        assertFalse(
            shouldRetry(
                Attempt(Method.POST, 500, networkFailed = false),
                attemptIndex = 0,
                maxAttempts = 3,
            ),
        )
    }

    @Test
    fun doesNotRetryClientMistakes() {
        for (code in listOf(400, 401, 403, 404)) {
            assertFalse(
                shouldRetry(
                    Attempt(Method.GET, code, networkFailed = false),
                    attemptIndex = 0,
                    maxAttempts = 3,
                ),
            )
        }
        assertFalse(
            shouldRetry(
                Attempt(Method.GET, null, networkFailed = false),
                attemptIndex = 0,
                maxAttempts = 3,
            ),
        )
    }
}
