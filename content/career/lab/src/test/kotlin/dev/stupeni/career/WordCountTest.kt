package dev.stupeni.career

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class WordCountTest {
    @Test
    fun countsCaseAndPunctuation() {
        assertEquals(mapOf("станц" to 2, "led" to 1), wordCount("Станц станц, LED"))
    }

    @Test
    fun emptyAndSeparators() {
        assertEquals(emptyMap(), wordCount(""))
        assertEquals(emptyMap(), wordCount("  ,,, --- "))
    }

    @Test
    fun keepsFirstSeenOrder() {
        val counts = wordCount("b a a")
        assertEquals(listOf("b", "a"), counts.keys.toList())
        assertEquals(2, counts["a"])
    }

    @Test
    fun digitsStickToTheWord() {
        assertEquals(mapOf("fw1" to 1), wordCount("fw1"))
    }

    @Test
    fun topBreaksTiesByWord() {
        assertEquals(listOf("a" to 2, "b" to 2), topWords("b a b a", 2))
        assertEquals(listOf("a" to 2), topWords("b a b a", 1))
    }

    @Test
    fun topRejectsNonPositiveAndEmpty() {
        assertEquals(emptyList(), topWords("a a", 0))
        assertEquals(emptyList(), topWords("a a", -1))
        assertEquals(emptyList(), topWords("", 3))
    }

    @Test
    fun topDoesNotAskForMoreThanExists() {
        assertEquals(listOf("a" to 1), topWords("a", 5))
    }
}
