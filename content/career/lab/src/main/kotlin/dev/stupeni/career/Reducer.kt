package dev.stupeni.career

enum class Phase { Idle, Loading, On, Off, Failed }

data class LampState(val phase: Phase, val message: String?)

sealed interface LampEvent {
    data object Refresh : LampEvent
    data class Loaded(val on: Boolean) : LampEvent
    data object TogglePressed : LampEvent
    data class Failed(val message: String) : LampEvent
}

fun reduce(state: LampState, event: LampEvent): LampState = TODO("C3: reduce")
