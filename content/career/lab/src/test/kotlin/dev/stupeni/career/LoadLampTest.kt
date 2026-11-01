package dev.stupeni.career

import kotlin.test.Test
import kotlin.test.assertEquals

class LoadLampTest {
    @Test
    fun successAndFailureGoThroughTheReducer() {
        val on = LoadLamp(FakeStatus(Result.success(true))).execute(LampState(Phase.Idle, null))
        assertEquals(LampState(Phase.On, null), on)

        val off = LoadLamp(FakeStatus(Result.success(false))).execute(LampState(Phase.On, null))
        assertEquals(LampState(Phase.Off, null), off)

        val failed = LoadLamp(
            FakeStatus(Result.failure(IllegalStateException("timeout"))),
        ).execute(LampState(Phase.Idle, null))
        assertEquals(LampState(Phase.Failed, "timeout"), failed)

        val blank = LoadLamp(
            FakeStatus(Result.failure(IllegalStateException())),
        ).execute(LampState(Phase.Idle, null))
        assertEquals(LampState(Phase.Failed, "нет связи"), blank)
    }

    @Test
    fun doesNotCallTheRepositoryWhileLoading() {
        val fake = FakeStatus(Result.success(true))
        val state = LampState(Phase.Loading, null)
        assertEquals(state, LoadLamp(fake).execute(state))
        assertEquals(0, fake.calls)
    }
}

private class FakeStatus(private val result: Result<Boolean>) : StatusRepository {
    var calls: Int = 0

    override fun fetchLampOn(): Result<Boolean> {
        calls += 1
        return result
    }
}
