# Mac mini wired Sidecar auto-mirror (reference)

Plug USB → unlock iPad → **native Sidecar as main display + hardware mirror**.

Keeps **Yam Display** running (needed for stable mirror). Never disconnects a healthy Sidecar session. Hotkey is optional fallback.

## ⚠️ Device name is NOT portable

Every iPad has its **own name**. Blindly copying `iPad` from another machine will break or connect the wrong device.

1. On the iPad: **Settings → General → About → Name**
2. On the Mac run:
   ```bash
   ~/Scripts/sidecar/bin/SidecarLauncher devices
   ```
3. Put the **exact** string into `config.env` as `SIDECAR_DEVICE_NAME`.

The LaunchAgent must pass that same name (or load `config.env`).

## Install (summary)

1. Copy this `sidecar/` folder to `~/Scripts/sidecar` (or keep layout and adjust paths).
2. `cp config.env.example config.env` and set `SIDECAR_DEVICE_NAME`.
3. Build helpers if needed:
   ```bash
   cd ~/Scripts/sidecar/bin
   swiftc -O -o set-ipad-main set-ipad-main.swift
   swiftc -O -o sidecar-hotkey sidecar-hotkey.swift   # optional
   ```
4. Install LaunchAgents from `LaunchAgents/`, editing the device argument / config path first.
5. Login items: Yam Display + BetterDisplay (virtual screen `SidecarVirtual` if you use it).

## Behavior

| State | Action |
|-------|--------|
| Sidecar already connected | Only run `set-ipad-main` (correct mirror). No reconnect. |
| Device listed + Yam ready | `SidecarLauncher connect "<name>" -wired` then mirror |
| Locked iPad | Wait / fail gently until unlocked |

## Constraints (do not remove)

- No `disconnect` when Sidecar Display is present.
- Do not kill Yam Display.
- Prefer CLI over System Settings “Add display” UI.
