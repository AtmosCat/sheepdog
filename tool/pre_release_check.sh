#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== 사용자 기록 보존 점검 =="
flutter test test/user_data_preservation_test.dart
echo "OK: 업데이트 시 기존 기록이 유지됩니다."
