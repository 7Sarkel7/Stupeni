import React from 'react';
import {useProgress} from '../progress/useProgress';

// Галочка «сделано». id вида "cis-flow/practice". Хранится только в этом браузере.
export default function ProgressCheck({id, children}) {
  const {state, toggle} = useProgress();
  return (
    <label style={{display: 'flex', gap: '0.5rem', alignItems: 'center', cursor: 'pointer'}}>
      <input
        type="checkbox"
        checked={state.done[id] === true}
        onChange={(e) => toggle(id, e.target.checked)}
      />
      <span>{children ?? 'Отметить как сделанное'}</span>
    </label>
  );
}
