package dev.stupeni.hire

import kotlin.coroutines.CoroutineContext
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Runnable
import kotlinx.coroutines.test.runTest

class DispatchTest {
    @Test
    fun namesMatchThePlatformDispatchers() {
        assertEquals("Main", dispatcherFor(WorkKind.Ui))
        assertEquals("IO", dispatcherFor(WorkKind.Io))
        assertEquals("Default", dispatcherFor(WorkKind.Cpu))
    }

    @Test
    fun uiStaysOnTheCaller() = runTest {
        val log = mutableListOf<String>()
        val value = switchFor(WorkKind.Ui, label("IO", log), label("Default", log)) { "ui" }
        assertEquals("ui", value)
        assertEquals(emptyList(), log)
    }

    @Test
    fun ioAndCpuUseTheInjectedDispatcher() = runTest {
        val log = mutableListOf<String>()
        val io = label("IO", log)
        val cpu = label("Default", log)
        assertEquals("disk", switchFor(WorkKind.Io, io, cpu) { "disk" })
        assertEquals("cpu", switchFor(WorkKind.Cpu, io, cpu) { "cpu" })
        assertEquals(listOf("IO", "Default"), log)
    }

    private fun label(name: String, log: MutableList<String>): CoroutineDispatcher =
        object : CoroutineDispatcher() {
            override fun isDispatchNeeded(context: CoroutineContext): Boolean = true

            override fun dispatch(context: CoroutineContext, block: Runnable) {
                log += name
                block.run()
            }
        }
}
