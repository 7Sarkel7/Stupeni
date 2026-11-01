package dev.stupeni.career

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class AlgorithmsTest {
    @Test
    fun binarySearchHitsEdgesAndMisses() {
        val values = intArrayOf(1, 3, 5, 7, 9)
        assertEquals(0, binarySearch(values, 1))
        assertEquals(3, binarySearch(values, 7))
        assertEquals(4, binarySearch(values, 9))
        assertEquals(-1, binarySearch(values, 4))
        assertEquals(-1, binarySearch(intArrayOf(), 1))
    }

    @Test
    fun firstDuplicateReturnsTheValueSeenAgain() {
        assertEquals(2, firstDuplicate(listOf(1, 2, 3, 2, 1)))
        assertEquals(1, firstDuplicate(listOf(1, 1)))
        assertNull(firstDuplicate(listOf(1, 2, 3)))
        assertNull(firstDuplicate(emptyList()))
        assertEquals(0, firstDuplicate(listOf(0, 4, 0)))
    }
}
