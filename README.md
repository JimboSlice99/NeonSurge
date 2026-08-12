# SURGE GARDEN

A full-size Roblox **grow / idle farm simulator** built to feel publish-ready and chart-competitive.

**Loop:** plant → grow → harvest → upgrade → unlock zones → rebirth.

Built with **Luau + Rojo**. Server-authoritative economy + Robux shop.

## What you get

- Personal farm island (plaza, fountain, market, roads, river, trees, lanterns)
- **4 zones** · up to **56 plots** (Homestead → Riverbend → Crystal Orchard → Sky Terrace)
- **8 crops** from Wheat to Legendary Crystal Bloom
- Tools through Diamond Scythe
- Guided goals + rebirth prestige (+35% coins each)
- Mobile-friendly HUD / tabbed shop
- DataStore saves + MarketplaceService monetization (placeholder IDs)

## Play loop (60 seconds)

1. Spawn in the market plaza → walk through the arch.
2. Use a plot prompt to **Plant** (seed bar at bottom).
3. Watch crops grow → **Harvest** for coins (floating +coins).
4. Open **SHOP** → buy seeds, tools, next zone.
5. When rich enough, **Rebirth** for permanent coin multiplier.

## Setup

```powershell
git checkout cursor/grow-garden-simulator-3712
git pull
aftman install
rojo build -o SurgeGarden.rbxlx
```

Fully close Studio → open `SurgeGarden.rbxlx` → Play.

Enable **Game Settings → Security → API Services** for DataStores.

## Monetization IDs

Edit `src/ReplicatedStorage/Shared/Config.luau`:

```lua
GamePassIds = {
  VIP = 0,           -- +50% harvest coins
  DoubleSpeed = 0,   -- 2x grow speed
  AutoCollect = 0,   -- auto-harvest
},
DevProductIds = {
  CoinsSmall = 0,    -- +5,000 coins
  CoinsBig = 0,      -- +35,000 coins
  RareSeedPack = 0,  -- rare seed crate
  ZoneSkip = 0,      -- unlock next zone
},
```

Create passes/products in Creator Dashboard → paste IDs → rebuild → publish.

## Project layout

```
src/ReplicatedStorage/Shared/     Config, remotes, types
src/ServerScriptService/          Map, data, garden, monetization
src/StarterPlayer/.../Client/     HUD, shop, harvest FX
```

## Publish tips (charts)

1. Strong icon: lush farm + big gold coins + clear title.
2. Thumbnail: plaza arch + growing fields.
3. Description: Plant → Harvest → Unlock farms → Rebirth.
4. Soft launch with VIP / 2x / Auto Collect priced for your audience.
5. Keep first harvest under ~10 seconds (already tuned).
