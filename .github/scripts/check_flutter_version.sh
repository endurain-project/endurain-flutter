#!/usr/bin/env bash
# Fails when a Flutter version pin drifts from .flutter-version, the single
# source of truth. GitHub workflow `env:` cannot read files, so the pins stay
# where they are and this check keeps them equal (run by ci.yml).
set -euo pipefail

cd "$(dirname "$0")/../.."

want="$(tr -d '[:space:]' < .flutter-version)"
status=0

check() {
  local file="$1" pattern="$2" label="$3" found
  found="$(grep -E "$pattern" "$file" || true)"
  if [[ -z "$found" ]]; then
    echo "::error file=$file::No $label found; update .github/scripts/check_flutter_version.sh" >&2
    status=1
    return
  fi
  while IFS= read -r line; do
    if [[ "$line" != *"$want"* ]]; then
      echo "::error file=$file::$label '$line' does not match .flutter-version ($want)" >&2
      status=1
    fi
  done <<< "$found"
}

for wf in ci integration ios build-android-apk; do
  check ".github/workflows/$wf.yml" '^ *FLUTTER_VERSION:' FLUTTER_VERSION
done
check .github/workflows/build-ci-docker-image.yml '^ *IMAGE_TAG:' IMAGE_TAG
check docker/flutter-build/Dockerfile '^ARG FLUTTER_(VERSION|ARCHIVE)=' 'Dockerfile Flutter ARG'
for wf in ci integration build-android-apk; do
  check ".github/workflows/$wf.yml" 'image: ghcr.io/endurain-project/endurain-flutter-ci' 'CI image'
done

exit "$status"
