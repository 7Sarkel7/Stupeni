// Проверка связности глубокого контента. Запуск: npm run check (из site/).
// Без зависимостей, только Node.js.
import {readFileSync, readdirSync, statSync, existsSync} from 'node:fs';
import {join, relative, resolve, dirname} from 'node:path';
import {fileURLToPath} from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const deepDir = join(root, 'content', 'deep');
const errors = [];
const fail = (file, msg) => errors.push(`${relative(root, file)}: ${msg}`);

function walk(dir) {
  const out = [];
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) out.push(...walk(p));
    else out.push(p);
  }
  return out;
}

function frontMatter(text) {
  const m = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  const fm = {};
  if (!m) return fm;
  for (const line of m[1].split(/\r?\n/)) {
    const kv = line.match(/^([A-Za-z][\w-]*):\s*(.*)$/);
    if (kv) fm[kv[1]] = kv[2].replace(/^["']|["']$/g, '').trim();
  }
  return fm;
}

const catalog = JSON.parse(readFileSync(join(root, 'content', 'catalog.json'), 'utf8'));
const lessonIds = new Set(catalog.tracks.flatMap((t) => t.lessons.map((l) => l.id)));

const linksFile = join(deepDir, 'links.json');
const links = existsSync(linksFile) ? JSON.parse(readFileSync(linksFile, 'utf8')) : {};

const files = walk(deepDir).filter((f) => /\.mdx?$/.test(f));
const chapterDirs = new Map();
const lessonOwners = new Map();

for (const file of files) {
  const text = readFileSync(file, 'utf8');
  const fm = frontMatter(text);

  if (fm.lesson) {
    if (!lessonIds.has(fm.lesson)) fail(file, `lesson "${fm.lesson}" нет в content/catalog.json`);
    const dir = dirname(file);
    if (!lessonOwners.has(fm.lesson)) lessonOwners.set(fm.lesson, new Set());
    lessonOwners.get(fm.lesson).add(dir);
    chapterDirs.set(dir, fm.lesson);
  }

  for (const m of text.matchAll(/<Doc\s+k=["']([^"']+)["']/g)) {
    if (!links[m[1]]) fail(file, `ключ <Doc k="${m[1]}"> нет в content/deep/links.json`);
  }
}

for (const [lesson, dirs] of lessonOwners) {
  if (dirs.size > 1) {
    fail(deepDir, `урок "${lesson}" описан в нескольких главах: ${[...dirs].map((d) => relative(root, d)).join(', ')}`);
  }
}

for (const [dir, lesson] of chapterDirs) {
  const rel = relative(root, dir);
  for (const required of ['index.md', 'razbor.md', 'docs.md', 'practice.md']) {
    if (!existsSync(join(dir, required))) fail(dir, `в главе "${lesson}" нет файла ${required}`);
  }
  const idx = join(dir, 'index.md');
  if (existsSync(idx)) {
    const fm = frontMatter(readFileSync(idx, 'utf8'));
    for (const key of ['title', 'lesson', 'evenings', 'minutesPerEvening']) {
      if (!fm[key]) fail(idx, `нет поля ${key} во front matter`);
    }
  }
  const razbor = join(dir, 'razbor.md');
  if (existsSync(razbor)) {
    const t = readFileSync(razbor, 'utf8');
    for (const word of ['До', 'Действие', 'После']) {
      if (!new RegExp(`\\*\\*${word}[.:]`).test(t)) {
        fail(razbor, `нет блока «**${word}.**» (до / действие / после) [${rel}]`);
      }
    }
  }
  const docs = join(dir, 'docs.md');
  if (existsSync(docs)) {
    const t = readFileSync(docs, 'utf8');
    if (!/https:\/\/(developer\.android\.com|kotlinlang\.org|git-scm\.com)\//.test(t) && !/<Doc\s/.test(t)) {
      fail(docs, 'нет ссылок на официальные доки (developer.android.com, kotlinlang.org, git-scm.com)');
    }
  }
}

const pubspec = readFileSync(join(root, 'learner', 'pubspec.yaml'), 'utf8');
if (/assets\/content\/deep/.test(pubspec)) {
  fail(join(root, 'learner', 'pubspec.yaml'), 'content/deep не должен попадать в ассеты приложения');
}

if (errors.length) {
  console.error(`Найдено проблем: ${errors.length}`);
  for (const e of errors) console.error(' - ' + e);
  process.exit(1);
}
console.log(`OK: файлов ${files.length}, глав ${chapterDirs.size}`);
