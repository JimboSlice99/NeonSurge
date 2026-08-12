# SURGE GARDEN

A publish-ready Roblox **grow / idle garden simulator** with tycoon-style progression and a Robux shop.

**Loop:** plant → grow → harvest → sell → upgrade → unlock zones.

Built with **Luau + Rojo**. One currency (Coins). Clear progression. Server-authoritative purchases.

## Gameplay

1. Walk up to a dirt plot and use the **ProximityPrompt** to plant your selected seed.
2. Wait for the crop to grow (watch the plant get taller).
3. Harvest when ready — coins are granted automatically (sell-on-harvest).
4. Open **Shop** to buy seed packs, better tools, and new zones.
5. Unlock **Sunny Meadow** then **Glass Greenhouse** for more plots.
6. Optional Robux: VIP, 2x grow speed, auto-collect, coin packs, rare seeds, zone skip.

### Controls

| Action | Input |
|--------|--------|
| Move | WASD / thumbstick |
| Plant / Harvest | ProximityPrompt on plot (mobile + desktop) |
| Select seed | Bottom seed bar |
| Shop | Top-right **Shop** button |

## Project layout

```
default.project.json
aftman.toml
src/
  ReplicatedStorage/Shared/
    Config.luau          seeds, tools, zones, shop, monetization IDs
    Remotes.luau
    Types.luau
  ServerScriptService/
    Main.server.luau
    Services/
      DataService.luau         DataStore save/load
      MapBuilder.luau          map + plots
      GardenService.luau       plant/grow/harvest/shop
      MonetizationService.luau Game Passes + Dev Products
  StarterPlayer/StarterPlayerScripts/
    Main.client.luau
    Client/Hud.luau
    Client/ShopUi.luau
```

## Setup (Studio)

### 1. Install tools

```bash
aftman install
```

Windows tip: install the Aftman **release** zip, run `.\aftman.exe self-install`, then open a new terminal.

### 2. Build a place file (recommended)

```bash
rojo build -o SurgeGarden.rbxlx
```

Open `SurgeGarden.rbxlx` in Roblox Studio (**fully close** Studio before rebuilding/reopening).

Optional live sync:

```bash
rojo serve
```

Then in Studio: **Plugins → Rojo → Connect** (Rojo plugin version should match CLI; this repo pins `7.4.4`).

### 3. Enable DataStores

In Studio: **Home → Game Settings → Security → Enable Studio Access to API Services**.

Publish the place at least once so DataStores and monetization can be configured.

## Create Game Passes & Developer Products

1. Publish the experience (File → Publish to Roblox).
2. Open [Creator Dashboard](https://create.roblox.com/) → your experience → **Monetization**.
3. Create **Game Passes**:
   - VIP
   - 2x Grow Speed
   - Auto Collect
4. Create **Developer Products**:
   - Small Coin Pack (hint: 2500 coins)
   - Big Coin Pack (hint: 15000 coins)
   - Rare Seed Pack
   - Zone Skip
5. Copy each numeric ID.

## Where to paste IDs

Edit `src/ReplicatedStorage/Shared/Config.luau`:

```lua
Monetization = {
  GamePassIds = {
    VIP = 0,          -- paste Game Pass ID
    DoubleSpeed = 0,  -- paste Game Pass ID
    AutoCollect = 0,  -- paste Game Pass ID
  },
  DevProductIds = {
    CoinsSmall = 0,     -- paste Dev Product ID
    CoinsBig = 0,       -- paste Dev Product ID
    RareSeedPack = 0,   -- paste Dev Product ID
    ZoneSkip = 0,       -- paste Dev Product ID
  },
},
```

Rebuild / sync, then test purchases in Studio with a published place (IDs must be non-zero).

Until IDs are set, Robux buttons show a toast: *Set … ID in Config.luau first*. Coin shop works without IDs.

## Monetization behavior (server-authoritative)

| Offer | Effect |
|-------|--------|
| VIP | +50% harvest coins |
| DoubleSpeed | Crops grow 2× faster |
| AutoCollect | Auto-harvests ready plots |
| CoinsSmall / CoinsBig | Grants coins via `ProcessReceipt` |
| RareSeedPack | Grants Crystal / Melon / Berry seeds |
| ZoneSkip | Unlocks the next locked zone |

- Coin shop purchases validated on the server.
- Game Pass ownership checked with `UserOwnsGamePassAsync` on join + purchase finished.
- Dev Products fulfilled only inside `MarketplaceService.ProcessReceipt` (receipts deduped).
- Clients cannot grant coins/items directly.

## Publish checklist

1. `rojo build -o SurgeGarden.rbxlx` and open in Studio.
2. Publish the place.
3. Create Game Passes + Dev Products; paste IDs into `Config.luau`.
4. Rebuild / sync again and publish.
5. Game Settings → Security: API Services on.
6. Set experience name, icon, description, genre (Simulation / Idle).
7. Test on phone emulator: shop UI, prompts, seed bar.
8. Play test: plant → harvest → buy tool → unlock Meadow → try a Dev Product in a published test.

## Tuning

All balance knobs live in `Config.luau`: grow times, sell values, shop prices, pass multipliers, starting coins.

## Tooling

```bash
selene src
stylua src
rojo build -o SurgeGarden.rbxlx
```
