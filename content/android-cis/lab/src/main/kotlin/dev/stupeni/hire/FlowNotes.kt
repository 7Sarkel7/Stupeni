package dev.stupeni.hire

data class NoteDraft(val id: String, val title: String, val updatedAt: Long)

fun normalizeTitle(raw: String): String = TODO("A1: normalizeTitle")

fun latestById(items: List<NoteDraft>): List<NoteDraft> = TODO("A1: latestById")
