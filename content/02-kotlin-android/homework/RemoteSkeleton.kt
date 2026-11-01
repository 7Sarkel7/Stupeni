package dev.stupeni.station.remote

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

// Каркас самостоятельной работы «пульт на Compose».
// В приложении «Ступени» этот файл не открывается: его берут из клона.
// Скопируйте к себе в проект вне этого репозитория и замените TODO.
// Здесь нет темы, ViewModel, навигации, Gradle и теста.
// Номер Compose BOM в этот файл не пишите: его копируют со страницы
// https://developer.android.com/develop/ui/compose/bom в день вашего проекта.

data class RemoteUiState(
    val host: String,
    val phrase: String,
    val busy: Boolean,
    val files: List<String>,
)

@Composable
fun RemoteStatusScreen(
    state: RemoteUiState,
    onHostChange: (String) -> Unit,
    onPing: () -> Unit,
    onOpenFiles: () -> Unit,
    modifier: Modifier = Modifier,
) {
    TODO("Scaffold Material 3: поле хоста, фраза, кнопки проверки и перехода к файлам")
}

@Composable
fun RemoteFilesScreen(
    files: List<String>,
    onFileClick: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    TODO("LazyColumn, key = путь на карте, пустой список — отдельная фраза")
}
