package dev.stupeni.career

import kotlin.test.Test
import kotlin.test.assertEquals

class TransportTest {
    @Test
    fun lanWinsEvenIfEverythingElseIsUp() {
        assertEquals(
            Link.LocalHttp,
            chooseTransport(
                DeviceFacts(
                    sameLan = true,
                    bleProvenOnDevice = true,
                    cloudReachable = true,
                    needsLowLatency = true,
                ),
            ),
        )
    }

    @Test
    fun bleOnlyWhenProvenAndLatencyMatters() {
        assertEquals(
            Link.Ble,
            chooseTransport(
                DeviceFacts(
                    sameLan = false,
                    bleProvenOnDevice = true,
                    cloudReachable = true,
                    needsLowLatency = true,
                ),
            ),
        )
        assertEquals(
            Link.Cloud,
            chooseTransport(
                DeviceFacts(
                    sameLan = false,
                    bleProvenOnDevice = true,
                    cloudReachable = true,
                    needsLowLatency = false,
                ),
            ),
        )
    }

    @Test
    fun unprovenBleIsNotAStoryForTheResume() {
        assertEquals(
            Link.Cloud,
            chooseTransport(
                DeviceFacts(
                    sameLan = false,
                    bleProvenOnDevice = false,
                    cloudReachable = true,
                    needsLowLatency = true,
                ),
            ),
        )
        assertEquals(
            Link.None,
            chooseTransport(
                DeviceFacts(
                    sameLan = false,
                    bleProvenOnDevice = false,
                    cloudReachable = false,
                    needsLowLatency = true,
                ),
            ),
        )
    }
}
