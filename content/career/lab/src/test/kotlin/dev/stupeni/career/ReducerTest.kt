package dev.stupeni.career

import kotlin.test.Test
import kotlin.test.assertEquals

class ReducerTest {
    private val idle = LampState(Phase.Idle, null)

    @Test
    fun refreshAndToggleEnterLoadingOnce() {
        assertEquals(LampState(Phase.Loading, null), reduce(idle, LampEvent.Refresh))
        assertEquals(LampState(Phase.Loading, null), reduce(idle, LampEvent.TogglePressed))
        val loading = LampState(Phase.Loading, "старое")
        assertEquals(loading, reduce(loading, LampEvent.Refresh))
        assertEquals(loading, reduce(loading, LampEvent.TogglePressed))
    }

    @Test
    fun loadedAndFailedReplaceState() {
        val loading = LampState(Phase.Loading, null)
        assertEquals(LampState(Phase.On, null), reduce(loading, LampEvent.Loaded(true)))
        assertEquals(LampState(Phase.Off, null), reduce(loading, LampEvent.Loaded(false)))
        assertEquals(
            LampState(Phase.Failed, "timeout"),
            reduce(LampState(Phase.On, null), LampEvent.Failed(" timeout ")),
        )
        assertEquals(
            LampState(Phase.Failed, "нет связи"),
            reduce(LampState(Phase.On, null), LampEvent.Failed("   ")),
        )
    }

    @Test
    fun failedCanBeRetried() {
        val failed = LampState(Phase.Failed, "timeout")
        assertEquals(LampState(Phase.Loading, null), reduce(failed, LampEvent.Refresh))
        assertEquals(LampState(Phase.Loading, null), reduce(failed, LampEvent.TogglePressed))
    }
}
