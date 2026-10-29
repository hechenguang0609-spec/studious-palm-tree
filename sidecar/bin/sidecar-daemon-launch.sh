#!/bin/zsh
set -u
ROOT="${SIDECAR_HOME:-$HOME/Scripts/sidecar}"
# shellcheck disable=SC1090
[[ -f "$ROOT/config.env" ]] && source "$ROOT/config.env"
if [[ -z "${SIDECAR_DEVICE_NAME:-}" ]]; then
  echo "Missing SIDECAR_DEVICE_NAME in $ROOT/config.env" >&2
  echo "Run: $ROOT/bin/SidecarLauncher devices" >&2
  exit 2
fi
if [[ "$SIDECAR_DEVICE_NAME" == "Your iPad Name Here" ]]; then
  echo "Replace placeholder SIDECAR_DEVICE_NAME in config.env" >&2
  exit 2
fi
exec /bin/zsh "$ROOT/bin/sidecar-daemon.sh" "$SIDECAR_DEVICE_NAME"
