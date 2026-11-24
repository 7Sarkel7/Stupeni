// Прогресс веб-версии. Хранится только в браузере (localStorage), с приложением не связан.
export const STORAGE_KEY = 'stupeni-web-v1';

function emptyState() {
  return {version: 1, done: {}};
}

export function parseState(raw) {
  if (!raw) return emptyState();
  let data;
  try {
    data = JSON.parse(raw);
  } catch {
    return emptyState();
  }
  if (!data || data.version !== 1 || typeof data.done !== 'object' || data.done === null) {
    return emptyState();
  }
  const done = {};
  for (const [id, value] of Object.entries(data.done)) {
    if (value === true) done[id] = true;
  }
  return {version: 1, done};
}

export function load(storage) {
  try {
    return parseState(storage.getItem(STORAGE_KEY));
  } catch {
    return emptyState();
  }
}

export function save(storage, state) {
  storage.setItem(STORAGE_KEY, JSON.stringify(state));
}

export function setDone(state, id, value) {
  const done = {...state.done};
  if (value) done[id] = true;
  else delete done[id];
  return {version: 1, done};
}

export function exportJson(state) {
  return JSON.stringify(state, null, 2);
}

// Возвращает новое состояние или бросает Error с понятным текстом.
export function importJson(text) {
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    throw new Error('Это не JSON. Вставьте текст, который вы получили кнопкой «Экспорт».');
  }
  if (!data || data.version !== 1 || typeof data.done !== 'object' || data.done === null) {
    throw new Error('Неизвестный формат: ожидается version: 1 и поле done.');
  }
  return parseState(JSON.stringify(data));
}
