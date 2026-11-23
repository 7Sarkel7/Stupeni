# A. Android: что ещё спрашивают

Шесть уроков про то, что в других треках только упомянуто или отсутствует: жизненный цикл и `ViewBinding`, `kotlinx.serialization`, разрешения, основы BLE и Wi-Fi, foreground service и ограничения фона, Gradle, version catalog, подпись и публикация. Примеры идут от станца и лампы, но приёмы общие.

Читают после [модуля 02](../02-kotlin-android/README.md) и желательно после [Kotlin: основа и лямбды](../kotlin-core/README.md): уроки по BLE и сервисам опираются на колбэки и корутины. Рядом, не вместо: [стек найма для СНГ](../android-cis/README.md) (Flow, Hilt, Retrofit, Room, DataStore, тесты, CI, пуши, WorkManager) и [карьера](../career/README.md).

| Урок | Тема | Уровень |
| --- | --- | --- |
| [01](01-lifecycle.md) | Activity, Fragment, lifecycle, `ViewBinding`, состояние при повороте | J |
| [02](02-serialization.md) | `kotlinx.serialization`, настройки `Json`, Retrofit | J, кусок M |
| [03](03-permissions.md) | Манифест, runtime-разрешения, отказ и «навсегда» | J |
| [04](04-ble-wifi.md) | BLE: скан, GATT, очередь; Wi-Fi: `NetworkCallback`, SoftAP, NSD | J, кусок M |
| [05](05-services.md) | Service, foreground service, выбор между WorkManager и сервисом | J, кусок M |
| [06](06-gradle-release.md) | Gradle, `libs.versions.toml`, подпись, AAB и APK, Play и RuStore | J |

Лаборатории здесь нет: проверка — эмулятор, телефон и плата. Номера библиотек и SDK в уроках не заморожены, их копируют со страниц документации в день проекта.
