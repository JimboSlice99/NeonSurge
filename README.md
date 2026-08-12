# NEON SURGE

A **Roblox roguelite arena shooter** built with **Rojo + Luau only**.

Survive neon hostiles, level up mid-run, bank credits, and buy permanent power. Designed as a publishable live game with gamepass / developer-product hooks.

## Why this loop can monetize

| Hook | What it does |
|------|----------------|
| **Short runs** | Instant Play → waves → death in minutes |
| **In-run upgrades** | Level-up picks (damage, multi-shot, pierce…) |
| **Meta progression** | Spend banked credits on permanent upgrades |
| **Gamepasses** | 2x Credits, VIP Trail, Extra Dash (IDs in Config) |
| **Dev products** | Credit packs for impulse spends |
| **High score** | Retention + bonus credits on PB |

No pay-to-win wall: gamepasses accelerate / cosmetics; skill still clears waves.

## Controls

- **WASD** move · **auto-fire** · **Q / Shift** dash  
- **Level up** → pick 1 of 3 upgrades  
- **R** returns to lobby after a run  
- Lobby **PLAY RUN** / upgrade shop / gamepass buttons

## Setup (Studio)

```bash
aftman install
rojo build -o NeonSurge.rbxlx
```

Open `NeonSurge.rbxlx` in Roblox Studio → Play.

Or live sync: `rojo serve` + Rojo plugin **7.7.0**.

## Publish checklist (money)

1. Upload the place to a Roblox experience you own  
2. Create gamepasses + developer products in Creator Dashboard  
3. Paste IDs into `src/ReplicatedStorage/Shared/Config.luau` → `Monetization`  
4. Enable **Studio Access to API Services** for DataStore tests  
5. Soft launch, watch session time / pass conversion, patch weekly

## Layout

```
src/ReplicatedStorage/Shared/   Config, upgrades, remotes, types
src/ServerScriptService/        Arena, combat, waves, data, monetization
src/StarterPlayer/...           Lobby, HUD, upgrade picker, input, FX
```

## Tooling

```bash
aftman install
selene src
rojo build -o NeonSurge.rbxlx
```
