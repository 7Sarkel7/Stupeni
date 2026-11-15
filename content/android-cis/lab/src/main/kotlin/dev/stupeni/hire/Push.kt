package dev.stupeni.hire

sealed interface PushCommand {
    data object ShiftReminder : PushCommand

    data class SyncNudge(val pending: Int) : PushCommand

    data object Ignore : PushCommand
}

fun parsePush(data: Map<String, String>): PushCommand = TODO("A7: parsePush")
