package dev.stupeni.kotlincore

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class OperatorsTest {
    @Test
    fun averageSkipsNullsAndDevicesWithoutData() {
        val readings = listOf(
            Reading("a", 20.0),
            Reading("a", 22.0),
            Reading("a", null),
            Reading("b", null),
            Reading("c", 5.0),
        )
        assertEquals(mapOf("a" to 21.0, "c" to 5.0), averageByDevice(readings))
    }

    @Test
    fun averageOfEmptyIsEmpty() {
        assertEquals(emptyMap(), averageByDevice(emptyList()))
    }

    @Test
    fun initialsTakesFirstLettersUppercase() {
        assertEquals("МХ", "магик  холограм".initials())
        assertEquals("ИП", "иван петров".initials())
        assertEquals("А", "  анна ".initials())
        assertEquals("", "   ".initials())
    }

    @Test
    fun secondOrNull() {
        assertEquals(2, listOf(1, 2, 3).secondOrNull())
        assertNull(listOf(1).secondOrNull())
        assertNull(emptyList<Int>().secondOrNull())
    }
}
