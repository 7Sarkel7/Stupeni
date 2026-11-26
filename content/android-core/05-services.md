# Service, foreground service и ограничения фона

**Модуль:** A. Android: что ещё спрашивают  
**Уровень:** J, типы foreground service — **M.**  
**Время:** около 45 минут  
**Лаборатория:** нет  
**Намёк:** нет  
**Дальше:** [Gradle, version catalog, подпись и публикация](06-gradle-release.md)

## Цель

Выбрать между корутиной в ViewModel, WorkManager, foreground service и ничем. Объявить foreground service с типом, показать уведомление и завершить его вовремя.

## Зачем это вам

[WorkManager](../android-cis/15-work.md) покрывает отложенную гарантированную работу. Остаётся вопрос: что делать, если пользователь ждёт сейчас и приложение уйдёт в фон: передача файла на лампу, длинное BLE-соединение (BLE — экономичный режим Bluetooth для маленьких устройств), запись. Для этого foreground service. Вопрос «чем WorkManager отличается от сервиса» — классика.

## Теория

**Что такое Service.** Компонент без UI (пользовательский интерфейс: всё, что видит и нажимает человек), объявленный в манифесте. Работает в главном потоке процесса, поэтому тяжёлую работу в нём делают в корутинах так же, как везде. Виды:

- *started* (`startService` / `startForegroundService`) — работает, пока сам не остановится;
- *bound* — клиент подключается, получает интерфейс (`bindService`), сервис живёт, пока есть клиенты;
- *foreground* — started с постоянным уведомлением. Система считает это работой, видимой пользователю, и не убивает без нужды.

**Фоновые ограничения.** С Android 8 приложение в фоне не может запускать обычные сервисы. Система убивает фоновые процессы, когда не хватает памяти, и ограничивает работу по расписанию (Doze, App Standby). Поэтому выбор инструмента зависит от задачи.

| Задача | Чем |
| --- | --- |
| Запрос данных для экрана | корутина во `viewModelScope` |
| Отправить очередь, когда появится сеть, гарантированно | WorkManager |
| Периодическое обновление (не чаще 15 минут) | WorkManager periodic |
| Пользователь ждёт сейчас, работа длинная и видимая | foreground service |
| Точное напоминание в минуту X | `AlarmManager` (точные будильники требуют разрешения и обоснования) |
| Задача на секунды при уходе с экрана | `WorkManager` expedited или `onStop` + корутина |

Правило: если можно через WorkManager, берут WorkManager. Foreground service — когда задача мгновенная и видимая.

**Объявление.**

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<service
    android:name=".LampTransferService"
    android:foregroundServiceType="connectedDevice"
    android:exported="false" />
```

С Android 14 (API 34) у foreground service **обязателен тип** (`dataSync`, `connectedDevice`, `mediaPlayback`, `location` и другие) и соответствующее разрешение `FOREGROUND_SERVICE_<ТИП>`. Тип выбирают по смыслу и по правилам магазина; точный список и ограничения (например, у `dataSync` есть лимит времени на новых версиях) — в [документации](https://developer.android.com/develop/background-work/services/fgs). Для связи с BLE-устройством подходит `connectedDevice`.

**Запуск и уведомление.**

```kotlin
class LampTransferService : Service() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = buildNotification()
        ServiceCompat.startForeground(
            this, NOTIFICATION_ID, notification,
            ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
        )
        scope.launch {
            transfer()
            stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
```

Из Activity: `ContextCompat.startForegroundService(context, Intent(context, LampTransferService::class.java))`. После этого у вас есть несколько секунд, чтобы вызвать `startForeground`, иначе исключение.

Что важно:

- Уведомление нужно создать с каналом ([каналы уведомлений](../android-cis/13-push.md)). Пользователь может смахнуть его на новых версиях, но сервис продолжит работать.
- Запуск foreground service из фона на новых версиях ограничен (есть исключения, например, по нажатию пользователя или точному будильнику). Планируйте запуск из видимого экрана.
- `START_NOT_STICKY` — не перезапускать сервис автоматически после убийства (для разовой передачи). `START_STICKY` — перезапускать (для долгой службы).
- Свой `CoroutineScope` в сервисе отменяется в `onDestroy` ([урок 13](../kotlin-core/13-job-scope.md)).
- Завершите сервис, как только работа закончена: `stopSelf()`. Бесконечный foreground service — жалоба пользователей и повод для отказа в магазине.

**Bound service.** Связь с UI через `Binder` и состояние через `StateFlow`: Activity подключается в `onStart`, отключается в `onStop`. Для простых задач ViewModel и WorkManager проще. Bound-сервис нужен, когда один компонент должен владеть долгим подключением к устройству, а несколько экранов подписываются на него.

**Что видит пользователь.** Раздел «Активные приложения» показывает foreground service и позволяет остановить. Приложение обязано пережить остановку.

**Экономия батареи.** Doze и App Standby откладывают работу в фоне. Не просите исключение из оптимизации батареи без необходимости (магазин проверяет).

## Разбор на примере

«Отправить большой файл на лампу по BLE, пока экран выключается».

1. Пользователь нажимает «Отправить». Приложение на экране: запускает `LampTransferService` через `startForegroundService`.
2. Сервис сразу вызывает `startForeground` с уведомлением и прогрессом.
3. Корутина шлёт куски, обновляет уведомление. Отмена — кнопка в уведомлении, которая отправляет `Intent` сервису; сервис отменяет `Job`.
4. По завершении `stopSelf()` и итоговое уведомление.
5. Если процесс всё-таки убили, `START_NOT_STICKY`: пользователь увидит, что передача не закончена, и повторит. Если нужно докачивание — состояние (сколько отправлено) лежит в базе.

А «напомнить через час, чтобы проверить лампу» — не сервис: WorkManager с задержкой.

## Упражнения

1. Создайте `Service` с `startForeground` и тестовым уведомлением. Запустите и посмотрите «Активные приложения».
2. Уберите вызов `startForeground` и прочитайте исключение. Верните.
3. Уберите `foregroundServiceType` на эмуляторе API (набор правил, по которым одна программа обращается к другой) 34. Что говорит система?
4. Добавьте кнопку «Отменить» в уведомление: `PendingIntent` на сервис, остановка `Job`.
5. Для каждого из шести сценариев таблицы теории выберите инструмент и запишите причину в одну строку.
6. Устно: чем foreground service отличается от WorkManager? Почему нельзя запустить обычный service из фона?

### Самопроверка

- Для любой фоновой задачи называете инструмент и причину.
- Объясняете, что такое тип foreground service и зачем.
- Знаете, как корректно завершить сервис.

## Типичные ошибки

- Foreground service там, где хватило бы WorkManager.
- Не вызвать `startForeground` вовремя.
- Нет типа и разрешения на API 34+.
- Бесконечный сервис.
- Тяжёлая работа прямо в `onStartCommand`, а не в корутине.
- Корутина без отмены в `onDestroy`.
- Запрос исключения из оптимизации батареи «для надёжности».

## Чеклист

- [ ] Таблица «задача → инструмент».
- [ ] Манифест foreground service с типом и разрешением.
- [ ] `startForeground`, `stopSelf`, отмена корутин.
- [ ] Знаете, чем WorkManager отличается.

## Следующий урок

[Gradle, version catalog, подпись и публикация](06-gradle-release.md).
