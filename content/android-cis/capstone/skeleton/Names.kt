package dev.stupeni.smena.skeleton

// Каркас имён для своего репозитория. Это не модуль приложения.
// Реализацию пишете в репозитории smena, не здесь.

interface NoteRepository

interface NoteApi

interface ShiftClock

interface ShiftNotifier

interface PushTokenSource

interface SyncScheduler

data class BatchItem(
    val localId: String,
    val op: String,
    val revision: Int,
    val place: String,
    val body: String,
    val updatedAt: Long,
    val hasPhoto: Boolean,
)

fun collapseForUpload(rows: List<BatchItem>): List<BatchItem> =
    TODO("Смена: сверните очередь в своём репозитории, см. SPEC")
