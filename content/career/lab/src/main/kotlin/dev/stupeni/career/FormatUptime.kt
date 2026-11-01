package dev.stupeni.career

/**
 * Готовая функция для урока про тесты. Её не переписывают.
 * Пишут проверки в FormatUptimeTest.
 */
fun formatUptime(seconds: Int): String {
    require(seconds >= 0) { "seconds" }
    val hours = seconds / 3600
    val minutes = (seconds % 3600) / 60
    val secs = seconds % 60
    return "%d:%02d:%02d".format(hours, minutes, secs)
}
