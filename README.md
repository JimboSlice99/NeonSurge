# SURGE GARDEN

Full-size Roblox **grow / idle farm simulator** — polished and upload-ready.

**Loop:** plant → grow → harvest → shop upgrades → unlock zones → daily reward → rebirth.

## Quick start (Windows)

```powershell
git pull origin cursor/grow-garden-simulator-3712
aftman install
rojo build -o SurgeGarden.rbxlx
```

1. Fully close Roblox Studio  
2. Open `SurgeGarden.rbxlx`  
3. **Game Settings → Security → Enable Studio Access to API Services**  
4. Press **Play**

### First-session checklist
- [ ] Tutorial card appears  
- [ ] Walk through arch → plant a plot  
- [ ] Harvest (floating coins + particles + sound)  
- [ ] **Plant All** / **Harvest All** work  
- [ ] Shop buys seeds / tools  
- [ ] Daily button grants coins  
- [ ] leaderstats show Coins + Rebirths  

In **Studio**, Robux buttons mock-grant rewards so you can test without IDs.

## Publish (go live)

### 1. Publish the place
File → Publish to Roblox (create experience if needed).

### 2. Create monetization
Creator Dashboard → your experience → **Monetization**:

| Type | Name | Suggested effect |
|------|------|------------------|
| Game Pass | VIP | +50% harvest coins |
| Game Pass | 2x Grow Speed | crops grow 2× |
| Game Pass | Auto Collect | auto Harvest All |
| Dev Product | Small Coin Pack | +5,000 coins |
| Dev Product | Big Coin Pack | +35,000 coins |
| Dev Product | Rare Seed Crate | rare seeds |
| Dev Product | Zone Skip | unlock next zone |

### 3. Paste IDs
Edit `src/ReplicatedStorage/Shared/Config.luau` → `Monetization.GamePassIds` / `DevProductIds`  
Set `StudioMockPasses = false` for production.

```powershell
rojo build -o SurgeGarden.rbxlx
```

Re-open in Studio → Publish again.

### 4. Store page
- Icon: lush farm + coins + title  
- Thumbnails: plaza arch, growing fields, shop UI  
- Description: Plant crops, unlock farms, rebirth for power.  
- Genre: Simulation  

### 5. Live test
Join the published game (not just Studio) and buy one cheap Dev Product to confirm `ProcessReceipt`.

## Features
- Personal farm island (plaza, market, river, 4 zones, up to 56 plots)
- 8 crops · 4 tools · zone unlocks · rebirth prestige
- Plant All / Harvest All · daily reward · tutorial · leaderstats
- Sounds, harvest particles, floating +coins
- DataStores · rate-limited remotes · server-authoritative Robux

## Project layout
```
src/ReplicatedStorage/Shared/   Config (IDs here), remotes, types
src/ServerScriptService/        map, data, garden, monetization
src/StarterPlayer/.../Client/   HUD, shop, FX, audio, tutorial
```
