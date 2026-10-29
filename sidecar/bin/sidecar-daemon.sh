#!/bin/zsh
set -u
source "$HOME/Scripts/sidecar/bin/sidecar-lib.sh"
require_device_name || exit 2
DEV="${1:-${SIDECAR_DEVICE_NAME:-}}"
STATE="/tmp/sidecar-daemon.state"

log "daemon_start autodetection=on"
ensure_apps
# Cold start settle
sleep 8

fail=0
announced=0
last_wait_log=0
prev_device=0
device_listed && prev_device=1 || prev_device=0

while true; do
  ensure_apps

  cur_device=0
  device_listed && cur_device=1 || cur_device=0

  # Edge: iPad appeared in SidecarLauncher device list → accelerate
  if (( cur_device == 1 && prev_device == 0 )); then
    log "ipad_detected_via_sidecar_devices"
    echo detected >"$STATE"
    # give USB/Yam a moment after plug
    sleep 2
  fi
  prev_device=$cur_device

  if sidecar_connected; then
    echo connected >"$STATE"
    if ! sidecar_mirrored; then
      correct_mirror throttle || true
    fi
    if [[ $announced -eq 0 ]]; then
      correct_mirror || true
      if sidecar_mirrored; then
        log "idle: Sidecar main+mirrored (auto; Yam kept running)"
        notify "原生随航已自动镜像为主屏"
        announced=1
        fail=0
      fi
    fi
    # Healthy: poll slower
    sleep 20
    continue
  fi

  announced=0

  # No Sidecar yet — need device + Yam, then auto connect (no hotkey)
  if (( cur_device == 0 )); then
    echo waiting_cable >"$STATE"
    now=$(date +%s)
    if (( now - last_wait_log >= 45 )); then
      log "wait_ipad_usb (plug cable + unlock; auto will run)"
      last_wait_log=$now
    fi
    sleep 3
    continue
  fi

  if ! yam_ready; then
    echo waiting_yam >"$STATE"
    now=$(date +%s)
    if (( now - last_wait_log >= 20 )); then
      log "ipad_seen wait_yam_or_unlock"
      last_wait_log=$now
    fi
    sleep 2
    continue
  fi

  echo connecting >"$STATE"
  if connect_wired_if_needed; then
    sleep 1
    correct_mirror || true
    sleep 1
    correct_mirror || true
    if sidecar_connected && sidecar_mirrored; then
      echo connected >"$STATE"
      notify "检测到 iPad：已自动随航镜像"
      announced=1
      fail=0
      sleep 20
      continue
    fi
  fi

  ((fail++)) || true
  echo "retrying:$fail" >"$STATE"
  log "auto_retry fail=$fail"
  # Unlock / trust may be needed — keep trying gently
  sleep $(( fail < 10 ? 3 : 12 ))
done
