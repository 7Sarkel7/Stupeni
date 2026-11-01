#!/usr/bin/env bash
# Копирует канонические уроки в ассеты Flutter-приложения.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/content"
dst="$root/learner/assets/content"

if [[ ! -f "$src/catalog.json" ]]; then
  echo "Нет $src/catalog.json" >&2
  exit 1
fi

rm -rf "$dst"
mkdir -p "$dst"
cp -a "$src"/. "$dst/"
echo "Скопировано $src → $dst"
