#!/bin/bash
set -euo pipefail

# Run pre-action for the shared Xcode scheme. All destination and product
# values come from Xcode, so another booted simulator is never selected.
if [[ "${PLATFORM_NAME:-}" != "iphonesimulator" ]]; then
  exit 0
fi

device_id="${TARGET_DEVICE_IDENTIFIER:-}"
app_path="${TARGET_BUILD_DIR:-}/${FULL_PRODUCT_NAME:-}"
if [[ ! "$device_id" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]]; then
  echo "error: Simulator preparation requires Xcode's selected device UUID." >&2
  exit 1
fi
if [[ "${FULL_PRODUCT_NAME:-}" != "myCloset.app" || ! -d "$app_path" ]]; then
  echo "error: Simulator preparation requires the built myCloset.app." >&2
  exit 1
fi

# Unsigned compile-only products must never replace the runnable app.
/usr/bin/codesign --verify --deep --strict "$app_path"

echo "Preparing myCloset on simulator $device_id"
xcrun simctl bootstatus "$device_id" -b

# A completed Xcode delta install can leave SpringBoard holding an updating
# placeholder (SBMainWorkspace Busy / failed preflight checks). A synchronous
# install of the built bundle refreshes registration and clears that state.
# This replaces only the executable bundle; it does not uninstall the app,
# erase the simulator, or clear its Documents/Library data.
xcrun simctl install "$device_id" "$app_path"
echo "myCloset simulator installation is ready."
if [[ -n "${TARGET_TEMP_DIR:-}" && -d "$TARGET_TEMP_DIR" ]]; then
  printf 'Prepared simulator %s at %s\n' "$device_id" "$(date -u)" > "$TARGET_TEMP_DIR/myCloset-simulator-run.log"
fi
