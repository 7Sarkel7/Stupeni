package dev.stupeni.hire

enum class OutboxOp { CREATE, UPDATE, DELETE }

data class OutboxRow(val localId: String, val op: OutboxOp, val revision: Int)

fun collapseOutbox(rows: List<OutboxRow>): List<OutboxRow> = TODO("A4: collapseOutbox")
