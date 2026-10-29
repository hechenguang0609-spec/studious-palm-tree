# proactive-codex

Open-source recipe for **initiative-first** technical assistants:

1. Decide and act (ask only for real decisions).
2. When stuck → search GitHub / docs before retrying the same approach.
3. Proactively run local [OpenAI Codex CLI](https://github.com/openai/codex).
4. Verify before claiming done.

## Contents

| Path | What |
|------|------|
| `skills/proactive-codex/SKILL.md` | Portable skill (Grok Bot / Cursor-style) |
| `.cursor/skills/proactive-codex/SKILL.md` | Same skill for Cursor Agent Skills |
| `sidecar/` | Optional reference: Mac mini USB Sidecar auto mirror (Yam + native Sidecar) |

## Install the skill

### Cursor
Copy `.cursor/skills/proactive-codex` into a repo's `.cursor/skills/`, or into your user skills folder.

### Grok Bot
Import or paste `skills/proactive-codex/SKILL.md` as a user skill named `proactive-codex`.

## Sidecar reference (optional)

**Different iPads have different names.** Set `sidecar/config.env` → `SIDECAR_DEVICE_NAME` from `SidecarLauncher devices`. Never copy another machine's device name.


See `sidecar/README.md`. Automates: plug iPad → unlock → native Sidecar as main + hardware mirror, without hotkey. Keeps Yam Display running; never disconnects a healthy session.

## License

MIT
