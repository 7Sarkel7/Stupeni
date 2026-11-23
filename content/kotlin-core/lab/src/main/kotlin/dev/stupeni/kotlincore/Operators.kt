package dev.stupeni.kotlincore

data class Reading(val device: String, val celsius: Double?)

fun averageByDevice(readings: List<Reading>): Map<String, Double> = TODO("K: averageByDevice")

fun String.initials(): String = TODO("K: initials")

fun <T> List<T>.secondOrNull(): T? = TODO("K: secondOrNull")
