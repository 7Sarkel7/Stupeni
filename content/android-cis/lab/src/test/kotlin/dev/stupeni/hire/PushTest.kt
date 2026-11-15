package dev.stupeni.hire

import kotlin.test.Test
import kotlin.test.assertEquals

class PushTest {
    @Test
    fun knownTypesBecomeCommands() {
        assertEquals(PushCommand.ShiftReminder, parsePush(mapOf("type" to "shift_reminder")))
        assertEquals(
            PushCommand.ShiftReminder,
            parsePush(mapOf("type" to "shift_reminder", "extra" to "x")),
        )
        assertEquals(PushCommand.SyncNudge(3), parsePush(mapOf("type" to "sync_nudge", "pending" to "3")))
        assertEquals(PushCommand.SyncNudge(0), parsePush(mapOf("type" to "sync_nudge", "pending" to "0")))
    }

    @Test
    fun garbageIsIgnored() {
        assertEquals(PushCommand.Ignore, parsePush(emptyMap()))
        assertEquals(PushCommand.Ignore, parsePush(mapOf("type" to "SHIFT_REMINDER")))
        assertEquals(PushCommand.Ignore, parsePush(mapOf("type" to "")))
        assertEquals(PushCommand.Ignore, parsePush(mapOf("type" to "other")))
        assertEquals(PushCommand.Ignore, parsePush(mapOf("type" to "sync_nudge")))
        assertEquals(PushCommand.Ignore, parsePush(mapOf("type" to "sync_nudge", "pending" to "-1")))
        assertEquals(PushCommand.Ignore, parsePush(mapOf("type" to "sync_nudge", "pending" to "01")))
        assertEquals(PushCommand.Ignore, parsePush(mapOf("type" to "sync_nudge", "pending" to "2 ")))
        assertEquals(PushCommand.Ignore, parsePush(mapOf("type" to "sync_nudge", "pending" to "foo")))
    }
}
