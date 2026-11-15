package dev.stupeni.hire

import kotlin.test.Test
import kotlin.test.assertEquals

class FlowNotesTest {
    @Test
    fun titleCollapsesSpaceAndCutsAtEighty() {
        assertEquals("", normalizeTitle("   \n\t  "))
        assertEquals("ось 3", normalizeTitle("  ось   3 \n"))
        val long = "а".repeat(90)
        assertEquals("а".repeat(80), normalizeTitle("  $long  "))
    }

    @Test
    fun latestKeepsFirstSeenOrderAndNewerStamp() {
        val rows = latestById(
            listOf(
                NoteDraft("a", "old", 1),
                NoteDraft("b", "b", 1),
                NoteDraft("a", "new", 2),
                NoteDraft("a", "same", 2),
                NoteDraft(" ", "drop", 9),
                NoteDraft("b", "older", 0),
            ),
        )
        assertEquals(
            listOf(
                NoteDraft("a", "same", 2),
                NoteDraft("b", "b", 1),
            ),
            rows,
        )
    }

    @Test
    fun emptyInputStaysEmpty() {
        assertEquals(emptyList(), latestById(emptyList()))
    }
}
