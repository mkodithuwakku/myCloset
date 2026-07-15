#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image_directory="${1:-${repository_root}/TestClosetImages}"

if [[ ! -d "$image_directory" ]]; then
  echo "Test image directory does not exist: $image_directory"
  exit 1
fi

if ! xcrun simctl list devices booted | grep -q '(Booted)'; then
  echo "Boot an iPhone Simulator before loading test images."
  exit 1
fi

image_count="$(find "$image_directory" -type f \( \
  -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o \
  -iname '*.heic' -o -iname '*.heif' -o -iname '*.webp' \
\) -print | wc -l | tr -d ' ')"

if [[ "$image_count" == "0" ]]; then
  echo "No supported images found in: $image_directory"
  exit 1
fi

find "$image_directory" -type f \( \
  -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o \
  -iname '*.heic' -o -iname '*.heif' -o -iname '*.webp' \
\) -exec xcrun simctl addmedia booted {} +

echo "Loaded $image_count test closet image(s) into the booted Simulator Photos library."
