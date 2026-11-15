package dev.stupeni.career

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class ParseDeviceLineTest {
    @Test
    fun statusOnAndOff() {
        assertEquals(Status(12, true), parseDeviceLine("OK uptime=12 lamp=1"))
        assertEquals(Status(0, false), parseDeviceLine("  OK uptime=0 lamp=0  "))
    }

    @Test
    fun faultKeepsTheRestOfTheLine() {
        assertEquals(Fault(503, "board is hot"), parseDeviceLine("ERR 503 board is hot"))
        assertEquals(Fault(503, ""), parseDeviceLine("ERR 503"))
    }

    @Test
    fun garbageAndBrokenNumbers() {
        assertNull(parseDeviceLine("nope"))
        assertNull(parseDeviceLine("OK uptime=x lamp=1"))
        assertNull(parseDeviceLine("OK uptime=12 lamp=2"))
        assertNull(parseDeviceLine("OK uptime=12"))
        assertNull(parseDeviceLine("ERR nope"))
    }
}
