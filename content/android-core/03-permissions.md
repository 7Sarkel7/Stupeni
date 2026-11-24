# Разрешения: манифест и runtime

**Модуль:** A. Android: что ещё спрашивают  
**Уровень:** J  
**Время:** около 40 минут  
**Лаборатория:** нет, эмулятор или телефон  
**Намёк:** нет  
**Дальше:** [BLE и Wi-Fi: основы](04-ble-wifi.md)

## Цель

Отличать нормальные и опасные разрешения, объявить их в манифесте, запросить в рантайме через Activity Result API, обработать отказ и «больше не спрашивать». Знать разрешения, которые нужны для сети, уведомлений и Bluetooth.

## Зачем это вам

Любая ветка «подключиться к плате» или «показать напоминание» упирается в разрешение. Без `POST_NOTIFICATIONS` на Android 13+ [пуш](../android-cis/13-push.md) и напоминание [WorkManager](../android-cis/15-work.md) молчат. Без Bluetooth-разрешений скан [следующего урока](04-ble-wifi.md) не стартует. Типичная ошибка junior: запросить всё при запуске, получить отказ и больше никогда не получить доступ.

## Теория

**Манифест.** Все разрешения объявляют в `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

Без объявления запрос в рантайме не сработает.

**Нормальные и опасные.**

- *Нормальные* выдаются при установке без вопроса: `INTERNET`, `ACCESS_NETWORK_STATE`, `VIBRATE`.
- *Опасные* (runtime) требуют согласия пользователя: камера, микрофон, местоположение, уведомления (с Android 13), Bluetooth-сканирование и подключение (с Android 12), чтение медиа.

Список растёт с версиями. Сверяйтесь со страницей [permissions overview](https://developer.android.com/guide/topics/permissions/overview), не с памятью.

**Запрос через Activity Result API.** Старый `onRequestPermissionsResult` не используют:

```kotlin
class MainActivity : ComponentActivity() {
    private val requestNotifications =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            if (granted) scheduleReminder() else showWhyNeeded()
        }

    private fun ensureNotifications() {
        if (Build.VERSION.SDK_INT < 33) { scheduleReminder(); return }
        val granted = ContextCompat.checkSelfPermission(
            this, Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
        if (granted) scheduleReminder()
        else requestNotifications.launch(Manifest.permission.POST_NOTIFICATIONS)
    }
}
```

`registerForActivityResult` объявляют как поле или в `onCreate`, не внутри обработчика клика. Лямбда — это `ActivityResultCallback<Boolean>`: [та самая функция](../kotlin-core/03-lambda-syntax.md), которую система вызовет позже. Несколько разрешений — `RequestMultiplePermissions`, результат `Map<String, Boolean>`.

В Compose: `rememberLauncherForActivityResult(RequestPermission()) { granted -> ... }`.

**Отказ.** Правила:

1. Не запрашивать при старте «на всякий случай». Запрашивать в момент, когда пользователь нажал действие, которому разрешение нужно.
2. Если пользователь отказал один раз, `shouldShowRequestPermissionRationale(...)` вернёт `true`: покажите объяснение и можно спросить ещё раз.
3. После второго отказа система перестаёт показывать диалог: метод снова вернёт `false`, `launch` сразу вернёт `false`. Единственный путь — отправить в настройки: `Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null))`.
4. Приложение должно работать без разрешения, там где это возможно: без уведомлений напоминание можно показать внутри приложения.

Различить «ещё не спрашивали» и «запретили навсегда» только по результату нельзя. Для этого сохраняют флаг «уже спрашивали» (например, в DataStore) и комбинируют его с `shouldShowRequestPermissionRationale`.

**Разрешения Bluetooth и сеть (коротко, подробности в следующем уроке).**

- Android 12+ (API 31): `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`; для скана без геолокации `android:usesPermissionFlags="neverForLocation"`.
- Android 11 и ниже: `BLUETOOTH`, `BLUETOOTH_ADMIN` плюс геолокация для скана.
- Сеть: `INTERNET`, `ACCESS_NETWORK_STATE`; для `NsdManager` и доступа к Wi-Fi-информации ещё `ACCESS_WIFI_STATE`/`CHANGE_WIFI_MULTICAST_STATE` по задаче.
- Android 13+ (API 33): `NEARBY_WIFI_DEVICES` для поиска устройств рядом по Wi-Fi.

**Фото, файлы.** Для одной картинки используют Photo Picker (`PickVisualMedia`): он не требует разрешений. Широкий доступ к медиатеке — только если без него нельзя, и с обоснованием для магазина.

**Политика магазинов.** Google Play и RuStore смотрят, зачем приложению местоположение, SMS и широкий доступ к файлам. Просите минимум.

**Тестирование.** Сброс разрешений: `adb shell pm reset-permissions` или `adb shell pm revoke <пакет> <разрешение>`. Проверьте три сценария: дали, отказали, отказали навсегда.

## Разбор на примере

Кнопка «Напомнить через час». Реализация без запроса при старте:

1. Пользователь нажимает кнопку.
2. Если API 33+ и разрешения нет, запускается запрос.
3. Согласился: ставим работу в WorkManager.
4. Отказал: показываем строку «Без уведомлений напомним только на экране», работа не ставится как уведомление.
5. Запретил навсегда: через экран с кнопкой «Открыть настройки».

Состояния отказа — отдельные варианты `sealed`-состояния экрана ([урок 11](../kotlin-core/11-classes-objects.md)): `Granted`, `Denied`, `PermanentlyDenied`.

## Упражнения

1. Объявите `POST_NOTIFICATIONS` и запросите его по нажатию кнопки через `registerForActivityResult`.
2. Проверьте три сценария на эмуляторе API 34 и запишите, что показывает система.
3. Добавьте экран «Откройте настройки» с `Intent` в настройки приложения для постоянного отказа.
4. Сделайте то же через `rememberLauncherForActivityResult` в Compose.
5. Выпишите для вашего приложения список разрешений: обязательное, нужное для одной функции, лишнее. Лишнее уберите.
6. Устно: почему нельзя запросить разрешение внутри `onCreate` сразу при старте? Как отличить «ещё не спрашивали» от «навсегда запретили»?

### Самопроверка

- Называете нормальные и опасные разрешения на примерах.
- Объясняете, почему `registerForActivityResult` не в обработчике клика.
- Знаете три шага при отказе.

## Типичные ошибки

- Запросить всё при запуске.
- Забыть объявить разрешение в манифесте.
- Не проверить `SDK_INT` и получить `SecurityException` на старом Android или «запрос без эффекта» на новом.
- Нет сценария «запрещено навсегда».
- Постоянный `shouldShowRequestPermissionRationale` без сохранённого флага.
- Широкие разрешения вместо Photo Picker.

## Чеклист

- [ ] Манифест и запрос в рантайме для `POST_NOTIFICATIONS`.
- [ ] Три сценария: дал, отказал, отказал навсегда.
- [ ] Знаете разрешения Bluetooth по версиям.
- [ ] Приложение работает без необязательных разрешений.

## Следующий урок

[BLE и Wi-Fi: основы](04-ble-wifi.md).
