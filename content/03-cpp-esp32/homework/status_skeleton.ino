#include <WiFi.h>
#include <WebServer.h>

// Каркас самостоятельной работы модуля 03.
// Пароль сети сюда не пишите. Тела функций пишете вы.
// Урок «Плата как сайт» показывает один маршрут status.
// Здесь нужны два маршрута и честный код, когда «карты нет».

WebServer server(80);
bool sdReady = false;

void handleApiStatus() {
  // GET /v1/reading
  // 200, text/plain, строка содержит OK, fw: и board:
}

void handleApiHealth() {
  // GET /v1/sensors
  // sdReady == false -> 503 и ровно текст SD unavailable
  // sdReady == true  -> 200 и ровно текст OK sd
}

void setup() {
  Serial.begin(115200);
  // Поднимите точку доступа или свою сеть так, как уже умеете.
  // Зарегистрируйте оба пути со слэшем и запустите сервер один раз.
}

void loop() {
  // Обслужите клиента.
  // Длинный delay здесь не проходит приёмку: HTTP перестаёт жить.
}
