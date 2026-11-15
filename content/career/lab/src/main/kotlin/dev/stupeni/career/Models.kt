package dev.stupeni.career

sealed interface DeviceEvent

data class Status(val uptimeSec: Int, val lampOn: Boolean) : DeviceEvent

data class Fault(val code: Int, val message: String) : DeviceEvent

fun parseDeviceLine(line: String): DeviceEvent? = TODO("C1: parseDeviceLine")
