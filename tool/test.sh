#!/usr/bin/env bash
# Синхронизирует уроки и гоняет тесты приложения.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
"$root/tool/sync_content.sh"
cd "$root/learner"
flutter test
