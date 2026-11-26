#!/usr/bin/env bash
# Runs the coverage gate with the thresholds and the shared exclusion list
# (.github/coverage-excludes.txt). Used by ci.yml and documented in README.md
# and CONTRIBUTING.md; run `flutter test --coverage` first.
set -euo pipefail

cd "$(dirname "$0")/../.."

excludes=()
while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  excludes+=(--exclude "$line")
done < .github/coverage-excludes.txt

exec dart run tool/check_coverage.dart \
  --min-line-coverage 80 \
  --min-file-line-coverage 60 \
  "${excludes[@]}"
