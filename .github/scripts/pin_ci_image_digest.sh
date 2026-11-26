#!/usr/bin/env bash
# Pins the CI builder image to a digest in every workflow that uses it, keeping
# the tag in a comment. Usage: pin_ci_image_digest.sh sha256:<digest>
# The digest is printed in the summary of the "Build CI builder image" run.
set -euo pipefail

digest="${1:?Usage: $0 sha256:<digest>}"
[[ "$digest" =~ ^sha256:[0-9a-f]{64}$ ]] || { echo "Invalid digest: $digest" >&2; exit 1; }

cd "$(dirname "$0")/../.."
tag="$(tr -d '[:space:]' < .flutter-version)"
image="ghcr.io/endurain-project/endurain-flutter-ci"

for wf in ci integration build-android-apk; do
  file=".github/workflows/$wf.yml"
  # Matches both the plain tag and an already pinned `tag@sha256:...  # tag`.
  sed -E -i.bak \
    "s|^( *image: )${image}:[^ ]+( *# .*)?$|\1${image}:${tag}@${digest} # ${tag}|" "$file"
  rm -f "$file.bak"
done
