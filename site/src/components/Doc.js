import React from 'react';
import links from '@site/../content/deep/links.json';

// Ссылка на официальную документацию по ключу из content/deep/links.json.
// Если страница переехала, правится один файл.
export default function Doc({k, children}) {
  const entry = links[k];
  if (!entry) {
    throw new Error(`Нет ключа "${k}" в content/deep/links.json`);
  }
  return (
    <a href={entry.url} target="_blank" rel="noopener noreferrer">
      {children ?? entry.title}
    </a>
  );
}
