# NEON SURGE

A fast neon arena survivor for Roblox — **Rojo + Luau only**.

Dash through hostile pulse units, auto-fire surge bolts, chain combos, and clear escalating waves before the grid overloads.

## Gameplay

- **Move** with WASD / thumbstick
- **Auto-fire** locks onto the nearest hostile (mouse aim preferred when available)
- **Dash** with `Q`, `Left Shift`, or gamepad `L2` (brief i-frames)
- **Survive waves** of Pulse Runners, Volt Bruisers, and Neon Overlords
- **Reboot** with `R` after a system failure

## Project layout

```
default.project.json          Rojo place mapping
aftman.toml                   Toolchain pins (Rojo, Selene, StyLua)
src/
  ReplicatedStorage/Shared/   Config, remotes, types
  ServerScriptService/        Arena, waves, combat, enemies
  StarterPlayer/
    StarterPlayerScripts/     Input, HUD, VFX
```

## Setup

1. Install [Aftman](https://github.com/LPGhatguy/aftman), then from this repo:

   ```bash
   aftman install
   ```

2. Install the [Rojo](https://rojo.space/) plugin in Roblox Studio.

3. Serve the project:

   ```bash
   rojo serve
   ```

4. In Studio, open a new Baseplace → **Plugins → Rojo → Connect**.

5. Press Play. The neon arena builds itself and the first surge begins automatically.

### One-shot place file

```bash
rojo build -o NeonSurge.rbxlx
```

Open `NeonSurge.rbxlx` in Studio if you prefer not to live-sync.

## Tooling

```bash
selene src
stylua src
```

## Architecture notes

- Server owns waves, damage, scoring, projectiles, and enemy AI
- Client owns input, HUD, and juice (bursts / shake / hurt flash)
- Tunables live in `src/ReplicatedStorage/Shared/Config.luau`

No TypeScript, React, or web scaffold — this repository is a Roblox game.
