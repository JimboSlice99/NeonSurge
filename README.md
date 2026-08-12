# NEON SURGE

Dark cyberpunk **district mission runner** for Roblox — Rojo + Luau only.

## The loop

- **3:00 missions** in a multi-level neon district
- **Movement tech:** dash, double-jump, ground slam, jump pads
- **Weapons:** Pulse SMG → unlock Shatter Cannon & Phase Rail mid-run
- **Style ranks:** D → SS (kills, dashes, slams, pads)
- **XP gems** → protocol picks → bank credits → permanent loadout

## Controls

| Input | Action |
|-------|--------|
| WASD | Move |
| Space ×2 | Double jump |
| Q / Shift | Dash |
| F | Ground slam |
| 1 / 2 / 3 | Switch weapons |
| R | Return to lobby |

## Run locally

```powershell
aftman install
rojo build -o NeonSurge.rbxlx
```

Open in Studio → Play → **START MISSION**.

Rojo plugin must be **7.7.0** if using `rojo serve`.

## Monetization

Paste Creator Dashboard IDs in `src/ReplicatedStorage/Shared/Config.luau` → `Monetization`.
