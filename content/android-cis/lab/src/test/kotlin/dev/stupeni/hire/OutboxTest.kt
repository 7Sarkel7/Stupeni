package dev.stupeni.hire

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class OutboxTest {
    @Test
    fun foldsARealisticQueue() {
        val rows = listOf(
            OutboxRow("a", OutboxOp.CREATE, 1),
            OutboxRow("a", OutboxOp.UPDATE, 2),
            OutboxRow("b", OutboxOp.UPDATE, 1),
            OutboxRow("b", OutboxOp.DELETE, 2),
            OutboxRow("a", OutboxOp.DELETE, 3),
            OutboxRow("c", OutboxOp.CREATE, 1),
            OutboxRow("c", OutboxOp.DELETE, 2),
            OutboxRow("c", OutboxOp.CREATE, 3),
        )
        assertEquals(
            listOf(
                OutboxRow("b", OutboxOp.DELETE, 2),
                OutboxRow("c", OutboxOp.CREATE, 3),
            ),
            collapseOutbox(rows),
        )
    }

    @Test
    fun createThenDeleteVanishesAndUpdateStaysCreate() {
        assertEquals(
            listOf(OutboxRow("d", OutboxOp.UPDATE, 5)),
            collapseOutbox(
                listOf(
                    OutboxRow("a", OutboxOp.CREATE, 1),
                    OutboxRow("a", OutboxOp.DELETE, 2),
                    OutboxRow("d", OutboxOp.UPDATE, 5),
                ),
            ),
        )
        assertEquals(
            listOf(OutboxRow("a", OutboxOp.CREATE, 3)),
            collapseOutbox(
                listOf(
                    OutboxRow("a", OutboxOp.CREATE, 1),
                    OutboxRow("a", OutboxOp.UPDATE, 3),
                ),
            ),
        )
    }

    @Test
    fun laterUpdateAndRecreateKeepFirstSeenOrder() {
        assertEquals(
            listOf(OutboxRow("a", OutboxOp.UPDATE, 4)),
            collapseOutbox(
                listOf(
                    OutboxRow("a", OutboxOp.UPDATE, 1),
                    OutboxRow("a", OutboxOp.UPDATE, 4),
                ),
            ),
        )
        assertEquals(
            listOf(
                OutboxRow("b", OutboxOp.UPDATE, 1),
                OutboxRow("a", OutboxOp.CREATE, 1),
            ),
            collapseOutbox(
                listOf(
                    OutboxRow("b", OutboxOp.UPDATE, 1),
                    OutboxRow("a", OutboxOp.CREATE, 1),
                ),
            ),
        )
        assertEquals(
            listOf(OutboxRow("a", OutboxOp.CREATE, 2)),
            collapseOutbox(
                listOf(
                    OutboxRow("a", OutboxOp.DELETE, 1),
                    OutboxRow("a", OutboxOp.CREATE, 2),
                ),
            ),
        )
    }

    @Test
    fun emptyInputStaysEmpty() {
        assertEquals(emptyList(), collapseOutbox(emptyList()))
    }

    @Test
    fun illegalQueueThrows() {
        assertFailsWith<IllegalArgumentException> {
            collapseOutbox(listOf(OutboxRow(" ", OutboxOp.CREATE, 1)))
        }
        assertFailsWith<IllegalArgumentException> {
            collapseOutbox(listOf(OutboxRow("a", OutboxOp.CREATE, 0)))
        }
        assertFailsWith<IllegalArgumentException> {
            collapseOutbox(
                listOf(
                    OutboxRow("a", OutboxOp.CREATE, 2),
                    OutboxRow("a", OutboxOp.UPDATE, 2),
                ),
            )
        }
        assertFailsWith<IllegalArgumentException> {
            collapseOutbox(
                listOf(
                    OutboxRow("a", OutboxOp.CREATE, 1),
                    OutboxRow("a", OutboxOp.CREATE, 2),
                ),
            )
        }
        assertFailsWith<IllegalArgumentException> {
            collapseOutbox(
                listOf(
                    OutboxRow("a", OutboxOp.DELETE, 1),
                    OutboxRow("a", OutboxOp.UPDATE, 2),
                ),
            )
        }
        assertFailsWith<IllegalArgumentException> {
            collapseOutbox(
                listOf(
                    OutboxRow("a", OutboxOp.DELETE, 1),
                    OutboxRow("a", OutboxOp.DELETE, 2),
                ),
            )
        }
    }
}
