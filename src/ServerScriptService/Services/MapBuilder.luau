--!strict
-- Full-size personal farms: each player gets plaza + 4 zones + plots + scenery.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MapBuilder = {}

local playerFolders: { [Player]: Folder } = {}
local playerSlots: { [Player]: number } = {}
local nextSlot = 0
local SLOT_GAP = 280

local function part(props: {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	parent: Instance,
	canCollide: boolean?,
	shape: Enum.PartType?,
}): Part
	local p = Instance.new("Part")
	p.Name = props.name
	p.Anchored = true
	p.CanCollide = if props.canCollide == nil then true else props.canCollide
	p.Size = props.size
	p.CFrame = props.cframe
	p.Color = props.color
	p.Material = props.material or Enum.Material.Grass
	p.Transparency = props.transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.shape then
		p.Shape = props.shape
	end
	p.Parent = props.parent
	return p
end

local function billboard(parent: Instance, text: string, offset: Vector3, size: Vector2?)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset((size and size.X) or 240, (size and size.Y) or 52)
	bb.StudsOffset = offset
	bb.AlwaysOnTop = true
	bb.MaxDistance = 140
	bb.Parent = parent
	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.35
	label.Text = text
	label.Parent = bb
	return label
end

local function tree(parent: Instance, at: Vector3, scale: number?)
	local s = scale or 1
	part({
		name = "Trunk",
		size = Vector3.new(1.5 * s, 8 * s, 1.5 * s),
		cframe = CFrame.new(at + Vector3.new(0, 4 * s, 0)),
		color = Color3.fromRGB(110, 75, 45),
		material = Enum.Material.Wood,
		parent = parent,
	})
	part({
		name = "Canopy",
		size = Vector3.new(9 * s, 8 * s, 9 * s),
		cframe = CFrame.new(at + Vector3.new(0, 10 * s, 0)),
		color = Color3.fromRGB(68, 138, 72),
		material = Enum.Material.Grass,
		shape = Enum.PartType.Ball,
		canCollide = false,
		parent = parent,
	})
end

local function bush(parent: Instance, at: Vector3, color: Color3?)
	part({
		name = "Bush",
		size = Vector3.new(5, 3.4, 5),
		cframe = CFrame.new(at + Vector3.new(0, 1.7, 0)),
		color = color or Color3.fromRGB(65, 125, 70),
		material = Enum.Material.Grass,
		shape = Enum.PartType.Ball,
		canCollide = false,
		parent = parent,
	})
end

local function lantern(parent: Instance, at: Vector3)
	part({
		name = "Post",
		size = Vector3.new(0.55, 7, 0.55),
		cframe = CFrame.new(at + Vector3.new(0, 3.5, 0)),
		color = Color3.fromRGB(90, 70, 50),
		material = Enum.Material.Wood,
		parent = parent,
	})
	local lamp = part({
		name = "Lamp",
		size = Vector3.new(1.8, 1.8, 1.8),
		cframe = CFrame.new(at + Vector3.new(0, 7.2, 0)),
		color = Color3.fromRGB(255, 220, 140),
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		canCollide = false,
		parent = parent,
	})
	local light = Instance.new("PointLight")
	light.Brightness = 1.3
	light.Range = 26
	light.Color = Color3.fromRGB(255, 230, 170)
	light.Parent = lamp
end

local function decorateZone(farm: Folder, zoneId: string, unlocked: boolean, offset: Vector3)
	local zone = Config.Zones[zoneId]
	local origin = zone.origin + offset
	local zoneFolder = Instance.new("Folder")
	zoneFolder.Name = "Decor_" .. zoneId
	zoneFolder.Parent = farm

	local groundColor = if unlocked then zone.color else Color3.fromRGB(72, 78, 70)
	part({
		name = "Ground",
		size = zone.groundSize,
		cframe = CFrame.new(origin),
		color = groundColor,
		material = Enum.Material.Grass,
		parent = zoneFolder,
	})

	local gs = zone.groundSize
	part({
		name = "BorderN",
		size = Vector3.new(gs.X + 2, 1.5, 2.2),
		cframe = CFrame.new(origin + Vector3.new(0, 0.75, -gs.Z / 2)),
		color = Config.Palette.Wood,
		material = Enum.Material.Wood,
		parent = zoneFolder,
	})
	part({
		name = "BorderS",
		size = Vector3.new(gs.X + 2, 1.5, 2.2),
		cframe = CFrame.new(origin + Vector3.new(0, 0.75, gs.Z / 2)),
		color = Config.Palette.Wood,
		material = Enum.Material.Wood,
		parent = zoneFolder,
	})
	part({
		name = "BorderE",
		size = Vector3.new(2.2, 1.5, gs.Z),
		cframe = CFrame.new(origin + Vector3.new(gs.X / 2, 0.75, 0)),
		color = Config.Palette.Wood,
		material = Enum.Material.Wood,
		parent = zoneFolder,
	})
	part({
		name = "BorderW",
		size = Vector3.new(2.2, 1.5, gs.Z),
		cframe = CFrame.new(origin + Vector3.new(-gs.X / 2, 0.75, 0)),
		color = Config.Palette.Wood,
		material = Enum.Material.Wood,
		parent = zoneFolder,
	})

	local sign = part({
		name = "Sign",
		size = Vector3.new(16, 5.5, 1.2),
		cframe = CFrame.new(origin + Vector3.new(0, 3.5, -gs.Z / 2 - 3)),
		color = Config.Palette.Wood,
		material = Enum.Material.Wood,
		parent = zoneFolder,
	})
	billboard(sign, if unlocked then zone.name else ("LOCKED · " .. zone.name), Vector3.new(0, 4.2, 0), Vector2.new(300, 58))

	tree(zoneFolder, origin + Vector3.new(-gs.X / 2 + 5, 0, -gs.Z / 2 + 5), 1.15)
	tree(zoneFolder, origin + Vector3.new(gs.X / 2 - 5, 0, -gs.Z / 2 + 5), 1.05)
	tree(zoneFolder, origin + Vector3.new(-gs.X / 2 + 5, 0, gs.Z / 2 - 5), 1.0)
	bush(zoneFolder, origin + Vector3.new(gs.X / 2 - 7, 0, gs.Z / 2 - 6))
	lantern(zoneFolder, origin + Vector3.new(-gs.X / 2 + 10, 0, 0))
	lantern(zoneFolder, origin + Vector3.new(gs.X / 2 - 10, 0, 0))

	if zoneId == "Orchard" or zoneId == "SkyTerrace" then
		for i = -2, 2 do
			part({
				name = "Arch",
				size = Vector3.new(2.2, 15, gs.Z - 10),
				cframe = CFrame.new(origin + Vector3.new(i * 13, 8.5, 0)),
				color = Color3.fromRGB(190, 220, 230),
				material = Enum.Material.Glass,
				transparency = 0.55,
				canCollide = false,
				parent = zoneFolder,
			})
		end
		part({
			name = "GlassRoof",
			size = Vector3.new(gs.X - 6, 1.4, gs.Z - 6),
			cframe = CFrame.new(origin + Vector3.new(0, 16, 0)),
			color = Color3.fromRGB(180, 215, 225),
			material = Enum.Material.Glass,
			transparency = 0.4,
			canCollide = false,
			parent = zoneFolder,
		})
	end

	if not unlocked then
		part({
			name = "LockBarrier",
			size = Vector3.new(gs.X, 14, gs.Z),
			cframe = CFrame.new(origin + Vector3.new(0, 7, 0)),
			color = Color3.fromRGB(35, 40, 38),
			material = Enum.Material.ForceField,
			transparency = 0.62,
			canCollide = false,
			parent = zoneFolder,
		})
	end
end

local function buildFarmscape(farm: Folder, offset: Vector3, unlockedZones: { [string]: boolean })
	part({
		name = "Island",
		size = Vector3.new(340, 6, 340),
		cframe = CFrame.new(offset + Vector3.new(0, -3, 50)),
		color = Color3.fromRGB(68, 125, 62),
		material = Enum.Material.Grass,
		parent = farm,
	})
	part({
		name = "IslandCliff",
		size = Vector3.new(350, 12, 350),
		cframe = CFrame.new(offset + Vector3.new(0, -11, 50)),
		color = Color3.fromRGB(95, 80, 55),
		material = Enum.Material.Slate,
		parent = farm,
	})

	local plaza = Instance.new("Folder")
	plaza.Name = "Plaza"
	plaza.Parent = farm

	part({
		name = "PlazaFloor",
		size = Vector3.new(60, 1.3, 60),
		cframe = CFrame.new(offset + Vector3.new(0, 0.65, -28)),
		color = Config.Palette.Path,
		material = Enum.Material.Cobblestone,
		parent = plaza,
	})
	part({
		name = "MarketRing",
		size = Vector3.new(30, 0.7, 30),
		cframe = CFrame.new(offset + Vector3.new(0, 1.2, -28)),
		color = Color3.fromRGB(155, 135, 105),
		material = Enum.Material.Slate,
		parent = plaza,
	})

	local fountainBase = part({
		name = "FountainBase",
		size = Vector3.new(13, 2.2, 13),
		cframe = CFrame.new(offset + Vector3.new(0, 2.1, -28)),
		color = Config.Palette.Stone,
		material = Enum.Material.Slate,
		shape = Enum.PartType.Cylinder,
		parent = plaza,
	})
	fountainBase.CFrame = CFrame.new(offset + Vector3.new(0, 2.1, -28)) * CFrame.Angles(0, 0, math.rad(90))
	local water = part({
		name = "FountainWater",
		size = Vector3.new(10, 1.3, 10),
		cframe = CFrame.new(offset + Vector3.new(0, 3, -28)),
		color = Config.Palette.Water,
		material = Enum.Material.Glass,
		transparency = 0.22,
		shape = Enum.PartType.Cylinder,
		canCollide = false,
		parent = plaza,
	})
	water.CFrame = CFrame.new(offset + Vector3.new(0, 3, -28)) * CFrame.Angles(0, 0, math.rad(90))
	part({
		name = "FountainSpout",
		size = Vector3.new(1.4, 6, 1.4),
		cframe = CFrame.new(offset + Vector3.new(0, 5.5, -28)),
		color = Config.Palette.Stone,
		material = Enum.Material.Slate,
		parent = plaza,
	})

	local stall = part({
		name = "ShopStall",
		size = Vector3.new(20, 1.6, 11),
		cframe = CFrame.new(offset + Vector3.new(24, 1.9, -28)),
		color = Config.Palette.Wood,
		material = Enum.Material.Wood,
		parent = plaza,
	})
	part({
		name = "StallRoof",
		size = Vector3.new(22, 1.2, 13),
		cframe = CFrame.new(offset + Vector3.new(24, 7.5, -28)) * CFrame.Angles(0, 0, math.rad(-8)),
		color = Config.Palette.Roof,
		material = Enum.Material.Wood,
		parent = plaza,
	})
	part({
		name = "StallPostL",
		size = Vector3.new(1.1, 8, 1.1),
		cframe = CFrame.new(offset + Vector3.new(15, 5, -33)),
		color = Config.Palette.Wood,
		material = Enum.Material.Wood,
		parent = plaza,
	})
	part({
		name = "StallPostR",
		size = Vector3.new(1.1, 8, 1.1),
		cframe = CFrame.new(offset + Vector3.new(33, 5, -23)),
		color = Config.Palette.Wood,
		material = Enum.Material.Wood,
		parent = plaza,
	})
	billboard(stall, "FARM MARKET", Vector3.new(0, 5.5, 0), Vector2.new(260, 54))

	part({
		name = "ArchL",
		size = Vector3.new(2.2, 14, 2.2),
		cframe = CFrame.new(offset + Vector3.new(-11, 7.5, -2)),
		color = Config.Palette.Wood,
		material = Enum.Material.Wood,
		parent = plaza,
	})
	part({
		name = "ArchR",
		size = Vector3.new(2.2, 14, 2.2),
		cframe = CFrame.new(offset + Vector3.new(11, 7.5, -2)),
		color = Config.Palette.Wood,
		material = Enum.Material.Wood,
		parent = plaza,
	})
	local archTop = part({
		name = "ArchTop",
		size = Vector3.new(26, 3.4, 2.8),
		cframe = CFrame.new(offset + Vector3.new(0, 15, -2)),
		color = Config.Palette.Roof,
		material = Enum.Material.Wood,
		parent = plaza,
	})
	billboard(archTop, Config.GameName, Vector3.new(0, 3.8, 0), Vector2.new(340, 64))

	for _, x in { -22, -12, 12, 22 } do
		lantern(plaza, offset + Vector3.new(x, 0, -50))
		tree(plaza, offset + Vector3.new(x * 1.35, 0, -58), 1.2)
	end
	for i = 1, 10 do
		bush(plaza, offset + Vector3.new(-27 + i * 5.5, 0, -8), Color3.fromRGB(70 + (i % 3) * 8, 130, 75))
	end

	local paths = Instance.new("Folder")
	paths.Name = "Paths"
	paths.Parent = farm
	part({
		name = "RoadNorth",
		size = Vector3.new(16, 0.7, 190),
		cframe = CFrame.new(offset + Vector3.new(0, 0.45, 55)),
		color = Config.Palette.Path,
		material = Enum.Material.Ground,
		parent = paths,
	})
	part({
		name = "RoadEast",
		size = Vector3.new(110, 0.7, 14),
		cframe = CFrame.new(offset + Vector3.new(55, 0.45, 40)),
		color = Config.Palette.Path,
		material = Enum.Material.Ground,
		parent = paths,
	})
	part({
		name = "RoadWest",
		size = Vector3.new(110, 0.7, 14),
		cframe = CFrame.new(offset + Vector3.new(-55, 0.45, 40)),
		color = Config.Palette.Path,
		material = Enum.Material.Ground,
		parent = paths,
	})

	local nature = Instance.new("Folder")
	nature.Name = "Nature"
	nature.Parent = farm
	part({
		name = "River",
		size = Vector3.new(30, 1.2, 130),
		cframe = CFrame.new(offset + Vector3.new(58, 0.3, 40)),
		color = Config.Palette.Water,
		material = Enum.Material.Glass,
		transparency = 0.18,
		canCollide = false,
		parent = nature,
	})
	part({
		name = "RiverBed",
		size = Vector3.new(32, 1, 132),
		cframe = CFrame.new(offset + Vector3.new(58, -0.5, 40)),
		color = Color3.fromRGB(90, 80, 55),
		material = Enum.Material.Slate,
		parent = nature,
	})
	local pond = part({
		name = "Pond",
		size = Vector3.new(34, 1.4, 24),
		cframe = CFrame.new(offset + Vector3.new(-58, 0.35, 95)),
		color = Config.Palette.Water,
		material = Enum.Material.Glass,
		transparency = 0.2,
		shape = Enum.PartType.Cylinder,
		canCollide = false,
		parent = nature,
	})
	pond.CFrame = CFrame.new(offset + Vector3.new(-58, 0.35, 95)) * CFrame.Angles(0, 0, math.rad(90))

	local spots = {
		Vector3.new(-75, 0, -45),
		Vector3.new(75, 0, -45),
		Vector3.new(-120, 0, 15),
		Vector3.new(120, 0, 15),
		Vector3.new(-45, 0, 105),
		Vector3.new(45, 0, 105),
		Vector3.new(-125, 0, 75),
		Vector3.new(125, 0, 75),
		Vector3.new(0, 0, 175),
		Vector3.new(-85, 0, 155),
		Vector3.new(85, 0, 155),
	}
	for i, spot in spots do
		tree(nature, offset + spot, 1 + (i % 3) * 0.18)
	end

	for _, zoneId in Config.ZoneOrder do
		decorateZone(farm, zoneId, unlockedZones[zoneId] == true, offset)
	end
end

local function makePlotModel(zoneId: string, plotIndex: number, origin: Vector3, cols: number): Model
	local col = (plotIndex - 1) % cols
	local row = math.floor((plotIndex - 1) / cols)
	local spacing = 8.8
	local startX = -((cols - 1) * spacing) / 2
	local pos = origin + Vector3.new(startX + col * spacing, 0.9, -12 + row * spacing)

	local model = Instance.new("Model")
	model.Name = zoneId .. "_" .. tostring(plotIndex)
	model:SetAttribute("PlotId", zoneId .. "_" .. tostring(plotIndex))
	model:SetAttribute("ZoneId", zoneId)
	model:SetAttribute("PlotIndex", plotIndex)

	local bed = Instance.new("Part")
	bed.Name = "Bed"
	bed.Anchored = true
	bed.CanCollide = true
	bed.Size = Vector3.new(7.4, 0.75, 7.4)
	bed.CFrame = CFrame.new(pos + Vector3.new(0, -0.15, 0))
	bed.Color = Color3.fromRGB(90, 70, 45)
	bed.Material = Enum.Material.Ground
	bed.Parent = model

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Anchored = true
	base.CanCollide = true
	base.Size = Vector3.new(6.3, 0.9, 6.3)
	base.CFrame = CFrame.new(pos)
	base.Color = Config.Palette.Dirt
	base.Material = Enum.Material.Ground
	base.TopSurface = Enum.SurfaceType.Smooth
	base.Parent = model
	model.PrimaryPart = base

	local plantFolder = Instance.new("Folder")
	plantFolder.Name = "PlantVisual"
	plantFolder.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Prompt"
	prompt.ActionText = "Plant"
	prompt.ObjectText = "Empty plot"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = Vector2.new(0, -20)
	prompt.Parent = base

	local marker = Instance.new("BillboardGui")
	marker.Name = "ReadyMarker"
	marker.Size = UDim2.fromOffset(44, 44)
	marker.StudsOffset = Vector3.new(0, 5, 0)
	marker.AlwaysOnTop = true
	marker.Enabled = false
	marker.Parent = base
	local mark = Instance.new("TextLabel")
	mark.Size = UDim2.fromScale(1, 1)
	mark.BackgroundTransparency = 1
	mark.Font = Enum.Font.FredokaOne
	mark.TextScaled = true
	mark.TextColor3 = Config.Palette.Gold
	mark.TextStrokeTransparency = 0.25
	mark.Text = "!"
	mark.Parent = marker

	return model
end

function MapBuilder.Build()
	local existing = Workspace:FindFirstChild("GardenWorld")
	if existing then
		existing:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "GardenWorld"
	world.Parent = Workspace

	local farms = Instance.new("Folder")
	farms.Name = "Farms"
	farms.Parent = world

	for _, old in Workspace:GetChildren() do
		if old:IsA("SpawnLocation") then
			old:Destroy()
		end
	end

	-- Temporary shared spawn until player farm loads
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(0, 1.5, -18)
	spawn.Color = Color3.fromRGB(110, 170, 95)
	spawn.Material = Enum.Material.Grass
	spawn.Transparency = 0.2
	spawn.Parent = world

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Color = Color3.fromRGB(95, 165, 220)
		baseplate.Material = Enum.Material.SmoothPlastic
		baseplate.Size = Vector3.new(2048, 1, 2048)
		baseplate.Position = Vector3.new(0, -20, 200)
	end

	Lighting.Ambient = Color3.fromRGB(145, 155, 135)
	Lighting.OutdoorAmbient = Color3.fromRGB(155, 165, 145)
	Lighting.Brightness = 2.3
	Lighting.ClockTime = 15.5
	Lighting.FogEnd = 700
	Lighting.FogStart = 280
	Lighting.FogColor = Color3.fromRGB(180, 200, 210)
end

function MapBuilder.EnsurePlayerPlots(player: Player, unlockedZones: { [string]: boolean }?): Folder
	local world = Workspace:WaitForChild("GardenWorld")
	local farms = world:WaitForChild("Farms") :: Folder

	local existing = playerFolders[player]
	if existing then
		return existing
	end

	local slot = playerSlots[player]
	if slot == nil then
		slot = nextSlot
		nextSlot += 1
		playerSlots[player] = slot
	end
	local offset = Vector3.new(0, 0, slot * SLOT_GAP)

	local farm = Instance.new("Folder")
	farm.Name = "Farm_" .. player.Name
	farm.Parent = farms
	farm:SetAttribute("GardenOffsetZ", offset.Z)

	local unlocks = unlockedZones or {
		Homestead = true,
		Riverbend = false,
		Orchard = false,
		SkyTerrace = false,
	}
	buildFarmscape(farm, offset, unlocks)

	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	plots.Parent = farm

	for zoneId, zone in Config.Zones do
		for i = 1, zone.plotCount do
			local model = makePlotModel(zoneId, i, zone.origin + offset, zone.cols)
			model.Parent = plots
		end
	end

	-- Personal spawn on their plaza
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlayerSpawn"
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(offset.X, 1.6, -18 + offset.Z)
	spawn.Color = Color3.fromRGB(110, 170, 95)
	spawn.Material = Enum.Material.Grass
	spawn.Transparency = 0.15
	spawn.Parent = farm

	playerFolders[player] = plots
	return plots
end

function MapBuilder.GetGardenOffset(player: Player): Vector3
	local slot = playerSlots[player] or 0
	return Vector3.new(0, 0, slot * SLOT_GAP)
end

function MapBuilder.ClearPlayerPlots(player: Player)
	local plots = playerFolders[player]
	if plots then
		local farm = plots.Parent
		if farm then
			farm:Destroy()
		else
			plots:Destroy()
		end
		playerFolders[player] = nil
	end
	playerSlots[player] = nil
end

function MapBuilder.UpdateZoneLocks(player: Player, unlockedZones: { [string]: boolean })
	local plots = playerFolders[player]
	if not plots then
		return
	end
	local farm = plots.Parent
	if not farm then
		return
	end
	for zoneId, unlocked in unlockedZones do
		local zone = farm:FindFirstChild("Decor_" .. zoneId)
		if zone then
			local barrier = zone:FindFirstChild("LockBarrier")
			if unlocked and barrier then
				barrier:Destroy()
			end
			local ground = zone:FindFirstChild("Ground")
			if ground and ground:IsA("BasePart") and unlocked and Config.Zones[zoneId] then
				ground.Color = Config.Zones[zoneId].color
			end
			local sign = zone:FindFirstChild("Sign")
			if sign then
				local bb = sign:FindFirstChildOfClass("BillboardGui")
				local label = bb and bb:FindFirstChild("Title")
				if label and label:IsA("TextLabel") and Config.Zones[zoneId] then
					label.Text = if unlocked then Config.Zones[zoneId].name else ("LOCKED · " .. Config.Zones[zoneId].name)
				end
			end
		end
	end
end

function MapBuilder.SetPlantVisual(model: Model, seedId: string?, progress: number, ready: boolean)
	local folder = model:FindFirstChild("PlantVisual")
	local base = model:FindFirstChild("Base")
	if not folder or not base or not base:IsA("BasePart") then
		return
	end
	folder:ClearAllChildren()

	local marker = base:FindFirstChild("ReadyMarker")
	if marker and marker:IsA("BillboardGui") then
		marker.Enabled = ready
	end

	if not seedId then
		base.Color = Config.Palette.Dirt
		return
	end

	local def = Config.Seeds[seedId]
	if not def then
		return
	end
	base.Color = Color3.fromRGB(95, 68, 42)
	local p = math.clamp(progress, 0, 1)
	local shape = def.shape

	local function add(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, shapeType: Enum.PartType?)
		local pr = Instance.new("Part")
		pr.Name = name
		pr.Anchored = true
		pr.CanCollide = false
		pr.Size = size
		pr.CFrame = cf
		pr.Color = color
		pr.Material = mat or Enum.Material.SmoothPlastic
		if shapeType then
			pr.Shape = shapeType
		end
		pr.Parent = folder
		return pr
	end

	if shape == "root" then
		local h = 0.45 + p * 2
		add("Root", Vector3.new(1, h, 1), base.CFrame * CFrame.new(0, 0.35 + h / 2, 0), def.color)
		if p > 0.4 then
			add("Leaves", Vector3.new(2, 0.7, 2), base.CFrame * CFrame.new(0, 0.55 + h, 0), def.leaf, Enum.Material.Grass, Enum.PartType.Ball)
		end
	elseif shape == "bush" or shape == "round" then
		local s = 0.9 + p * 2.6
		add("Bush", Vector3.new(s, s * 0.85, s), base.CFrame * CFrame.new(0, 0.55 + s * 0.35, 0), if ready then def.color else def.leaf, Enum.Material.Grass, Enum.PartType.Ball)
		if ready then
			add("Fruit", Vector3.new(s * 0.5, s * 0.5, s * 0.5), base.CFrame * CFrame.new(0.55, 1.3 + s * 0.2, 0.25), def.color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		end
	elseif shape == "flower" or shape == "crystal" then
		local h = 0.8 + p * 3.4
		add("Stem", Vector3.new(0.6, h, 0.6), base.CFrame * CFrame.new(0, 0.45 + h / 2, 0), def.leaf)
		if p > 0.45 then
			local bloom = 1.2 + p * 1.5
			local head = add("Bloom", Vector3.new(bloom, bloom, bloom), base.CFrame * CFrame.new(0, 0.7 + h, 0), def.color, if shape == "crystal" then Enum.Material.Glass else Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			if ready then
				local light = Instance.new("PointLight")
				light.Color = def.color
				light.Brightness = 1.5
				light.Range = 12
				light.Parent = head
			end
		end
	else
		local h = 0.9 + p * 3.8
		add("Stalk", Vector3.new(0.65, h, 0.65), base.CFrame * CFrame.new(0, 0.45 + h / 2, 0), def.leaf)
		if p > 0.5 then
			add("Head", Vector3.new(1.4, 1.6, 1.4), base.CFrame * CFrame.new(0, 0.55 + h, 0), def.color, Enum.Material.SmoothPlastic)
		end
		if ready then
			add("Accent", Vector3.new(0.9, 0.9, 0.9), base.CFrame * CFrame.new(0.45, 0.9 + h, 0), def.color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		end
	end
end

return MapBuilder
