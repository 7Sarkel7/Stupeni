package dev.stupeni.hire

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class WorkPolicyTest {
    @Test
    fun enqueuesOnlyWhenThereIsSomethingToSend() {
        val ready = SyncSignals(
            pending = 2,
            networkConnected = true,
            batteryLow = false,
            alreadyRunning = false,
        )
        assertEquals(true, shouldEnqueueSync(ready))
        assertEquals(false, shouldEnqueueSync(ready.copy(pending = 0)))
        assertEquals(false, shouldEnqueueSync(ready.copy(networkConnected = false)))
        assertEquals(false, shouldEnqueueSync(ready.copy(batteryLow = true)))
        assertEquals(false, shouldEnqueueSync(ready.copy(alreadyRunning = true)))
    }

    @Test
    fun negativePendingIsABug() {
        assertFailsWith<IllegalArgumentException> {
            shouldEnqueueSync(
                SyncSignals(
                    pending = -1,
                    networkConnected = true,
                    batteryLow = false,
                    alreadyRunning = false,
                ),
            )
        }
    }
}
