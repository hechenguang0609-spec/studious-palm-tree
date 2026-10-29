#!/bin/zsh
# Shared helpers for Sidecar wired + mirror automation.
# Constraints: never disconnect when already connected; never kill Yam.


# --- load per-machine device name ---
_SIDECAR_ROOT="${SIDECAR_HOME:-$HOME/Scripts/sidecar}"
if [[ -f "$_SIDECAR_ROOT/config.env" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$_SIDECAR_ROOT/config.env"
  set +a
fi
# Prefer env; fall back to first CLI arg only if caller passes one; never assume "iPad"
if [[ -n "${SIDECAR_DEVICE_NAME:-}" ]]; then
  DEV="$SIDECAR_DEVICE_NAME"
elif [[ -n "${1:-}" && "${0:t}" != "sidecar-lib.sh" ]]; then
  :
else
  :
fi
L="${L:-$HOME/Scripts/sidecar/bin/SidecarLauncher}"
M="${M:-$HOME/Scripts/sidecar/bin/set-ipad-main}"
BD="${BD:-/Applications/BetterDisplay.app/Contents/MacOS/BetterDisplay}"
YAM_APP="${YAM_APP:-/Applications/Yam Display.app}"
DEV="${SIDECAR_DEVICE_NAME:-${DEV:-}}"
LOG="${SIDECAR_LOG:-/tmp/sidecar-autoconnect.log}"

log() { print -r -- "$(date '+%F %T') $*" >>"$LOG" }
notify() { osascript -e "display notification \"$1\" with title \"有线随航\"" >/dev/null 2>&1 || true }

sidecar_connected() {
  system_profiler SPDisplaysDataType 2>/dev/null | grep -q 'Sidecar Display'
}

# Hardware / software mirror with Sidecar as master (or any Mirror: On under Sidecar Display)
sidecar_mirrored() {
  system_profiler SPDisplaysDataType 2>/dev/null | awk '
    /Sidecar Display:/ {p=1; next}
    /^        [A-Za-z]/ { if (p) p=0 }
    p && /Mirror: On/ { found=1 }
    p && /Main Display: Yes/ { main=1 }
    END { exit (found && main) ? 0 : 1 }
  '
}

yam_app_running() {
  pgrep -xq "Yam Display" || pgrep -f "/Applications/Yam Display.app" >/dev/null 2>&1
}

# Yam display present in profiler (name varies by version/locale)
yam_display_present() {
  system_profiler SPDisplaysDataType 2>/dev/null | grep -qiE 'Yam Display|YamDisplay|^[[:space:]]+Yam:'
}

device_listed() {
  "$L" devices 2>/dev/null | grep -F "$DEV" >/dev/null
}

ensure_apps() {
  open -ga /Applications/BetterDisplay.app >/dev/null 2>&1 || true
  open -ga "$HOME/Applications/SidecarHotkey.app" >/dev/null 2>&1 || true
  open -ga "$YAM_APP" >/dev/null 2>&1 || true
  "$BD" set -name=SidecarVirtual -connected=on >/dev/null 2>&1 || true
}

# User finding: Yam must be up first for stable Sidecar mirror.
# Ready when: Yam app running AND (Yam display seen OR iPad already listed for long enough with Yam up).
yam_ready() {
  yam_app_running || return 1
  if yam_display_present; then
    return 0
  fi
  # Fallback: Yam process up + device listed. Prefer waiting a bit for real Yam display.
  device_listed || return 1
  return 0
}

wait_for_sidecar_display() {
  local i
  for i in {1..20}; do
    if sidecar_connected; then
      return 0
    fi
    sleep 1
  done
  return 1
}

# Apply Sidecar-as-main + mirror. Safe to call when already connected.
# Throttle via stamp file if SECOND arg "throttle" and last run < 45s.
correct_mirror() {
  local mode="${1:-}"
  local stamp="/tmp/sidecar-last-mirror.stamp"
  if [[ "$mode" == "throttle" && -f "$stamp" ]]; then
    local now last
    now=$(date +%s)
    last=$(cat "$stamp" 2>/dev/null || echo 0)
    if (( now - last < 45 )); then
      log "mirror_skip_throttle"
      return 0
    fi
  fi
  if ! sidecar_connected; then
    log "mirror_skip_no_sidecar"
    return 1
  fi
  if sidecar_mirrored; then
    date +%s >"$stamp"
    return 0
  fi
  log "mirror_apply set-ipad-main"
  "$M" >>"$LOG" 2>&1 || true
  sleep 1
  if sidecar_mirrored; then
    date +%s >"$stamp"
    log "mirror_ok"
    return 0
  fi
  # one immediate retry
  "$M" >>"$LOG" 2>&1 || true
  sleep 1
  if sidecar_mirrored; then
    date +%s >"$stamp"
    log "mirror_ok_retry"
    return 0
  fi
  log "mirror_still_not_ok"
  return 1
}

# Connect only if not already connected. Never disconnect when connected.
connect_wired_if_needed() {
  if sidecar_connected; then
    log "connect_skip_already_connected"
    return 0
  fi
  if ! device_listed; then
    log "connect_fail_no_device"
    return 2
  fi
  local out ec
  set +e
  out="$("$L" connect "$DEV" -wired 2>&1)"
  ec=$?
  set -e
  log "connect_attempt ec=$ec: $out"
  # AlreadyInUse but no display: one careful disconnect+reconnect
  if ! sidecar_connected; then
    if print -r -- "$out" | grep -qiE 'already.?in.?use|AlreadyInUse'; then
      log "already_in_use_without_display — one disconnect"
      "$L" disconnect "$DEV" >/dev/null 2>&1 || true
      sleep 2
      set +e
      out="$("$L" connect "$DEV" -wired 2>&1)"
      ec=$?
      set -e
      log "reconnect_after_inuse ec=$ec: $out"
    fi
  fi
  wait_for_sidecar_display || return 3
  return 0
}


require_device_name() {
  if [[ -z "${DEV:-}" ]]; then
    print -r -- "ERROR: SIDECAR_DEVICE_NAME is empty. Copy config.env.example → config.env and set your iPad name from: $L devices" >&2
    return 2
  fi
  if [[ "$DEV" == "Your iPad Name Here" || "$DEV" == "iPad" && "${SIDECAR_ALLOW_GENERIC_IPAD:-0}" != "1" ]]; then
    # Allow literal "iPad" only with explicit override — many users have that name, but warn.
    if [[ "$DEV" == "Your iPad Name Here" ]]; then
      print -r -- "ERROR: replace the placeholder SIDECAR_DEVICE_NAME in config.env" >&2
      return 2
    fi
    print -r -- "WARN: DEV is the generic name 'iPad'. Confirm with: $L devices  (export SIDECAR_ALLOW_GENERIC_IPAD=1 to silence)" >&2
  fi
}
