package dev.stupeni.career

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue

class HttpMappingTest {
    @Test
    fun idempotentMethods() {
        assertTrue(isIdempotent(Method.GET))
        assertTrue(isIdempotent(Method.PUT))
        assertTrue(isIdempotent(Method.DELETE))
        assertFalse(isIdempotent(Method.POST))
    }

    @Test
    fun authIsItsOwnBranch() {
        assertEquals(ApiError.Unauthorized, mapHttp(401, "no"))
        assertEquals(ApiError.Unauthorized, mapHttp(403, "no"))
    }

    @Test
    fun otherErrorsKeepCodeAndBody() {
        assertEquals(ApiError.Http(400, "on must be boolean"), mapHttp(400, "on must be boolean"))
        assertEquals(ApiError.Http(404, ""), mapHttp(404, ""))
        assertEquals(ApiError.Http(500, "boom"), mapHttp(500, "boom"))
        assertEquals(ApiError.Http(503, "busy"), mapHttp(503, "busy"))
    }

    @Test
    fun successIsNotAnErrorMapping() {
        val error = assertFailsWith<IllegalArgumentException> {
            mapHttp(200, "ok")
        }
        assertIs<IllegalArgumentException>(error)
    }
}
