import React, {useState} from 'react';
import {useProgress} from '../progress/useProgress';
import {exportJson, importJson} from '../progress/store.mjs';

export default function ProgressPanel() {
  const {state, replace} = useProgress();
  const [text, setText] = useState('');
  const [message, setMessage] = useState('');
  const ids = Object.keys(state.done).sort();

  const doExport = () => {
    setText(exportJson(state));
    setMessage('Скопируйте этот текст и сохраните в файл.');
  };
  const doImport = () => {
    try {
      replace(importJson(text));
      setMessage('Прогресс загружен.');
    } catch (e) {
      setMessage(e.message);
    }
  };
  const doReset = () => {
    if (window.confirm('Стереть весь прогресс на этом сайте в этом браузере?')) {
      replace({version: 1, done: {}});
      setText('');
      setMessage('Прогресс стёрт.');
    }
  };

  return (
    <div>
      <p>Отмечено пунктов: <strong>{ids.length}</strong></p>
      {ids.length > 0 && (
        <ul>
          {ids.map((id) => (
            <li key={id}><code>{id}</code></li>
          ))}
        </ul>
      )}
      <div style={{display: 'flex', gap: '0.5rem', flexWrap: 'wrap', margin: '1rem 0'}}>
        <button className="button button--primary" onClick={doExport}>Экспорт</button>
        <button className="button button--secondary" onClick={doImport}>Импорт</button>
        <button className="button button--danger button--outline" onClick={doReset}>Стереть</button>
      </div>
      <textarea
        value={text}
        onChange={(e) => setText(e.target.value)}
        rows={8}
        style={{width: '100%', fontFamily: 'monospace'}}
        placeholder="Здесь появится экспорт. Для импорта вставьте сюда ранее сохранённый текст."
      />
      {message && <p role="status">{message}</p>}
    </div>
  );
}
