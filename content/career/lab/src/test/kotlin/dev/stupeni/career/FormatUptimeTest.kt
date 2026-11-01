package dev.stupeni.career

import kotlin.test.Test
import org.junit.jupiter.api.Disabled

@Disabled("Урок C4: удалите аннотацию и напишите проверки сами")
class FormatUptimeTest {
    @Test
    fun zeroSeconds() {
        TODO("0 → 0:00:00")
    }

    @Test
    fun oneMinutePadsSeconds() {
        TODO("60 → 0:01:00")
    }

    @Test
    fun hoursKeepMinutesAndSecondsPadded() {
        TODO("3723 → 1:02:03")
    }

    @Test
    fun negativeIsRejected() {
        TODO("отрицательное значение не форматируют")
    }
}
