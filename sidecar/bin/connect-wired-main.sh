#!/bin/zsh
set -u
source "$HOME/Scripts/sidecar/bin/sidecar-lib.sh"
require_device_name || exit 2
DEV="${1:-${SIDECAR_DEVICE_NAME:-}}"

ensure_apps

# Already connected: ONLY correct mirror, never reconnect
if sidecar_connected; then
  if correct_mirror; then
    notify "已校正：Sidecar 主屏镜像"
    exit 0
  fi
  notify "随航已连接，但镜像校正失败"
  exit 1
fi

# Wait for Yam readiness (and unlock)
local_ok=0
for i in {1..60}; do
  ensure_apps
  if yam_ready; then
    local_ok=1
    break
  fi
  sleep 1
done
if [[ $local_ok -ne 1 ]]; then
  notify "请先解锁 iPad，并让 Yam Display 连上"
  exit 2
fi

# Small settle after Yam appears
sleep 2

ok=0
for i in {1..12}; do
  if sidecar_connected; then
    ok=1
    break
  fi
  if connect_wired_if_needed; then
    ok=1
    break
  fi
  sleep 2
done

if [[ $ok -ne 1 ]] || ! sidecar_connected; then
  notify "连不上随航：请确认已插线并解锁 iPad"
  exit 3
fi

sleep 1
if correct_mirror; then
  notify "Yam + 原生随航镜像已就绪"
  exit 0
fi
notify "随航已连上，请再按一次热键校正镜像"
exit 4
