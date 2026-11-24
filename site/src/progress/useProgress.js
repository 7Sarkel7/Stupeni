import {useCallback, useEffect, useState} from 'react';
import {STORAGE_KEY, load, save, setDone} from './store.mjs';

const EVENT = 'stupeni-progress-changed';

export function useProgress() {
  const [state, setState] = useState({version: 1, done: {}});

  useEffect(() => {
    const refresh = () => setState(load(window.localStorage));
    refresh();
    const onStorage = (e) => {
      if (e.key === STORAGE_KEY || e.key === null) refresh();
    };
    window.addEventListener(EVENT, refresh);
    window.addEventListener('storage', onStorage);
    return () => {
      window.removeEventListener(EVENT, refresh);
      window.removeEventListener('storage', onStorage);
    };
  }, []);

  const replace = useCallback((next) => {
    save(window.localStorage, next);
    window.dispatchEvent(new Event(EVENT));
  }, []);

  const toggle = useCallback(
    (id, value) => replace(setDone(load(window.localStorage), id, value)),
    [replace],
  );

  return {state, toggle, replace};
}
