# Activity, Fragment, lifecycle и ViewBinding

**Модуль:** A. Android: что ещё спрашивают  
**Уровень:** J  
**Время:** около 50 минут  
**Лаборатория:** нет, `hire-scratch`  
**Намёк:** нет, ответы проверяет эмулятор  
**Дальше:** [kotlinx.serialization](02-serialization.md)

## Цель

Назвать порядок вызовов жизненного цикла `Activity` и `Fragment`, объяснить, что происходит при повороте экрана, где живёт состояние, и подключить экран на Views через ViewBinding. Понимать, почему Compose не отменяет эти знания.

## Зачем это вам

Модуль 02 учит Compose, но `ComponentActivity` остаётся контейнером. Большая часть кода в вакансиях СНГ до сих пор на `Fragment` и XML (формат разметки с тегами в угловых скобках). Вопросы «что вызывается при повороте», «чем `onStop` отличается от `onPause`», «где хранить состояние» задают на каждом junior-скрининге (джун, junior — разработчик начального уровня).

## Теория

### Activity

| Колбэк (функция, которую вызовут позже, когда что-то произойдёт) | Что происходит | Что делать |
| --- | --- | --- |
| `onCreate` | экран создан, один раз за экземпляр | `setContent` или inflate, подписки через lifecycle-aware API (набор правил, по которым одна программа обращается к другой) |
| `onStart` | экран становится видимым | то, что нужно, пока экран виден |
| `onResume` | на переднем плане, принимает ввод | камера, сенсоры, если нужны только здесь |
| `onPause` | частично потерял фокус (диалог, мультиоконность) | быстро, без тяжёлой работы |
| `onStop` | не виден | отписки, остановка того, что нужно только на виду |
| `onDestroy` | экземпляр уничтожается | очистка; не гарантирован при убийстве процесса |

Порядок: `onCreate → onStart → onResume`, на выходе `onPause → onStop → onDestroy`. Если пользователь вернулся: `onRestart → onStart → onResume`.

**Что при повороте.** По умолчанию Activity **пересоздаётся**: `onPause → onStop → onDestroy → onCreate → onStart → onResume`. Поля Activity пропадают. Поэтому состояние хранят:

- в `ViewModel`: переживает поворот, но не смерть процесса;
- в `SavedStateHandle` (в `ViewModel`) или `onSaveInstanceState`: небольшие данные (id, текст поля), переживают и смерть процесса;
- в базе или `DataStore`: то, что не должно пропасть никогда ([урок](../android-cis/07-data.md)).

**Смерть процесса.** Система убивает фоновое приложение без вызова `onDestroy`. При возврате вы получаете `onCreate` с `savedInstanceState`. Проверка: в «Параметры разработчика» включить «Не сохранять действия» или `adb shell am kill <пакет>`.

### Lifecycle-aware компоненты

Не нужно вручную звать подписку в `onStart` и отписку в `onStop`. `Lifecycle` — объект, на который можно подписаться:

```kotlin
lifecycleScope.launch {
    repeatOnLifecycle(Lifecycle.State.STARTED) {
        viewModel.state.collect { render(it) }
    }
}
```

Блок запускается при `STARTED` и отменяется при `STOPPED`, пока Activity жива. Это стандартный способ собирать `Flow` в Views. Для Compose аналог — `collectAsStateWithLifecycle()` ([урок 10 модуля 02](../02-kotlin-android/10-viewmodel-compose.md)).

### Fragment

Fragment — кусок экрана с собственным жизненным циклом, плюс отдельный цикл **View**:

`onAttach → onCreate → onCreateView → onViewCreated → onStart → onResume ... onPause → onStop → onDestroyView → onDestroy → onDetach`

Важное: у Fragment два «времени жизни» — сам фрагмент и его view. Фрагмент может жить в back stack без view. Поэтому:

- подписки на `Flow` делают в `viewLifecycleOwner.lifecycleScope`, не в `lifecycleScope` фрагмента;
- ссылку на binding обнуляют в `onDestroyView`, иначе утечка view;
- `ViewModel` фрагмента — `by viewModels()`, общая с Activity — `by activityViewModels()`.

### ViewBinding

Включается в `build.gradle.kts` модуля:

```kotlin
android {
    buildFeatures { viewBinding = true }
}
```

Для `activity_main.xml` генерируется `ActivityMainBinding`. В Activity:

```kotlin
class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        binding.sendButton.setOnClickListener { viewModel.send() }
    }
}
```

В Fragment — паттерн (типовой проверенный приём решения задачи) с обнулением:

```kotlin
class StatusFragment : Fragment(R.layout.fragment_status) {
    private var _binding: FragmentStatusBinding? = null
    private val binding get() = _binding!!

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        _binding = FragmentStatusBinding.bind(view)
        binding.refresh.setOnClickListener { viewModel.refresh() }
    }

    override fun onDestroyView() {
        _binding = null
        super.onDestroyView()
    }
}
```

Здесь `!!` — единственное оправданное место: между `onViewCreated` и `onDestroyView` binding гарантированно есть. Понимаете, почему: [урок 01 модуля K](../kotlin-core/01-basics.md) называл `!!` «почти всегда запахом» (запах кода, code smell — признак того, что код хоть и работает, но написан рискованно и, скорее всего, приведёт к ошибкам).

Плюсы перед `findViewById`: безопасность типов и null, проверка на этапе компиляции. Перед старым `kotlin-android-extensions`: тот удалён, не используйте.

### Compose рядом

В Compose Activity вызывает `setContent { ... }`, фрагмент не нужен, состояние — в `ViewModel` и `rememberSaveable`. Знание lifecycle не исчезает: ViewModel живёт по тем же правилам, `collectAsStateWithLifecycle` слушает тот же `Lifecycle`. Interop: `AndroidView` вставляет View в Compose, `ComposeView` — Compose во Fragment.

## Разбор на примере

Пульт: поле IP и кнопка. Пользователь ввёл адрес и повернул телефон.

- Без ничего: Activity пересоздана, поле пустое.
- Если View имеет `id`, `EditText` сам сохраняет текст в `onSaveInstanceState`.
- В Compose `rememberSaveable { mutableStateOf("") }` делает то же для состояния.
- Результат запроса в `ViewModel` как `StateFlow`: после поворота новый экран подписывается и сразу получает последнее значение, запрос не повторяется.

Типичное падение: корутина запущена в `lifecycleScope.launch { }` без `repeatOnLifecycle` и пишет в `binding` фрагмента после `onDestroyView`.

## Упражнения

В `hire-scratch` или любом проекте с Activity.

1. Добавьте логи (журнал, куда программа записывает, что делает) во все колбэки Activity и откройте экран, нажмите Home, вернитесь, поверните, закройте. Запишите порядок.
2. Повторите для Fragment, включая `onCreateView`, `onViewCreated`, `onDestroyView`. Что вызывается в back stack?
3. Включите ViewBinding, замените `findViewById` в одном экране. Для фрагмента сделайте обнуление.
4. Сохраните в `ViewModel` счётчик и поверните: пережил ли поворот. Затем `adb shell am kill` и вернитесь: пережил ли смерть процесса? Перенесите счётчик в `SavedStateHandle`.
5. Соберите `Flow` в Fragment через `viewLifecycleOwner.lifecycleScope` и `repeatOnLifecycle(STARTED)`. Нажмите Home и проверьте по логам, что сбор остановился.
6. Устно: чем `onPause` отличается от `onStop`? Где хранить черновик письма?

### Самопроверка

- Порядок колбэков вы называете без подсказки.
- Объясняете, что переживает поворот, а что смерть процесса.
- Знаете, почему binding фрагмента обнуляют.

## Типичные ошибки

- Хранить данные в полях Activity.
- Запуск корутин через `lifecycleScope` фрагмента, а не `viewLifecycleOwner`.
- Не обнулять binding.
- Тяжёлая работа в `onPause`.
- Передавать `Activity` в синглтон (объект, который существует в программе в единственном экземпляре) и забыть отписаться.
- Считать, что `onDestroy` вызывается всегда.
- Использовать `kotlin-android-extensions`.

## Чеклист

- [ ] Порядок lifecycle Activity и Fragment.
- [ ] Поворот, смерть процесса и что где хранится.
- [ ] ViewBinding в Activity и Fragment.
- [ ] `repeatOnLifecycle` для сбора Flow.

## Следующий урок

[kotlinx.serialization](02-serialization.md).
