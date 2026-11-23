import test from 'node:test';
import assert from 'node:assert/strict';
import {parseState, setDone, exportJson, importJson, load, save, STORAGE_KEY} from '../src/progress/store.mjs';

const memory = () => {
  const m = new Map();
  return {getItem: (k) => (m.has(k) ? m.get(k) : null), setItem: (k, v) => m.set(k, v)};
};

test('пустое и битое хранилище дают пустое состояние', () => {
  assert.deepEqual(parseState(null).done, {});
  assert.deepEqual(parseState('{не json').done, {});
  assert.deepEqual(parseState('{"version":2,"done":{}}').done, {});
});

test('setDone ставит и снимает галочку, не меняя исходное состояние', () => {
  const a = parseState(null);
  const b = setDone(a, 'cis-flow/practice', true);
  assert.equal(b.done['cis-flow/practice'], true);
  assert.deepEqual(a.done, {});
  assert.deepEqual(setDone(b, 'cis-flow/practice', false).done, {});
});

test('сохранение и загрузка', () => {
  const s = memory();
  save(s, setDone(parseState(null), 'x', true));
  assert.ok(s.getItem(STORAGE_KEY));
  assert.equal(load(s).done.x, true);
});

test('экспорт и импорт возвращают то же самое', () => {
  const st = setDone(setDone(parseState(null), 'a', true), 'b', true);
  assert.deepEqual(importJson(exportJson(st)), st);
});

test('импорт отбрасывает лишнее и ругается на мусор', () => {
  assert.deepEqual(importJson('{"version":1,"done":{"a":true,"b":"yes"}}').done, {a: true});
  assert.throws(() => importJson('abc'), /не JSON/);
  assert.throws(() => importJson('{"version":9,"done":{}}'), /формат/);
});
