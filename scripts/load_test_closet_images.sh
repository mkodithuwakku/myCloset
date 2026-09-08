#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image_directory="${1:-${repository_root}/TestClosetImages}"

if [[ ! -d "$image_directory" ]]; then
  echo "Test image directory does not exist: $image_directory"
  exit 1
fi

booted_devices=()
while IFS= read -r device_id; do
  booted_devices+=("$device_id")
done < <(xcrun simctl list devices booted | sed -nE 's/.*\(([0-9A-Fa-f-]{36})\) \(Booted\).*/\1/p')

if [[ "${#booted_devices[@]}" == "0" ]]; then
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

converted_directory="$(mktemp -d "${TMPDIR:-/tmp}/myClosetSimulatorMedia.XXXXXX")"
trap 'rm -rf "$converted_directory"' EXIT

media_files=()
source_digests=()
media_file_digests=()
while IFS= read -r -d '' image_path; do
  source_digests+=("$(shasum -a 256 "$image_path" | awk '{ print $1 }')")
  if [[ "${image_path##*.}" =~ ^[Ww][Ee][Bb][Pp]$ ]]; then
    converted_path="${converted_directory}/$(basename "${image_path%.*}").jpg"
    if ! sips -s format jpeg "$image_path" --out "$converted_path" >/dev/null; then
      echo "Could not convert WebP image for Simulator Photos: $image_path"
      exit 1
    fi
    media_files+=("$converted_path")
  else
    media_files+=("$image_path")
  fi
  media_index=$((${#media_files[@]} - 1))
  media_file_digests+=("$(shasum -a 256 "${media_files[$media_index]}" | awk '{ print $1 }')")
done < <(find "$image_directory" -type f \( \
  -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o \
  -iname '*.heic' -o -iname '*.heif' -o -iname '*.webp' \
\) -print0)

marker_domain="com.mkodi.myCloset.simulatorMediaLoader"
for device_id in "${booted_devices[@]}"; do
  existing_digests_file="${converted_directory}/existing-${device_id}.txt"
  : > "$existing_digests_file"
  device_data_path="$(xcrun simctl list devices -j | ruby -rjson -e '
    devices = JSON.parse(STDIN.read).fetch("devices").values.flatten
    device = devices.find { |candidate| candidate["udid"] == ARGV.fetch(0) }
    abort "Could not locate Simulator data path" unless device
    print device.fetch("dataPath")
  ' "$device_id")"
  if [[ -d "${device_data_path}/Media/DCIM" ]]; then
    while IFS= read -r -d '' existing_media; do
      shasum -a 256 "$existing_media" | awk '{ print $1 }' >> "$existing_digests_file"
    done < <(find "${device_data_path}/Media/DCIM" -type f -print0)
  fi

  imported_count=0
  skipped_count=0
  for index in "${!media_files[@]}"; do
    marker_key="sha256_${source_digests[$index]}"
    if grep -Fxq "${media_file_digests[$index]}" "$existing_digests_file"; then
      xcrun simctl spawn "$device_id" defaults write "$marker_domain" "$marker_key" -bool YES
      skipped_count=$((skipped_count + 1))
      continue
    fi

    xcrun simctl addmedia "$device_id" "${media_files[$index]}"
    xcrun simctl spawn "$device_id" defaults write "$marker_domain" "$marker_key" -bool YES
    echo "${media_file_digests[$index]}" >> "$existing_digests_file"
    imported_count=$((imported_count + 1))
  done

  echo "Simulator $device_id: loaded $imported_count new image(s); skipped $skipped_count already-loaded or duplicate image(s)."
done

echo "Processed $image_count test closet image file(s)."
