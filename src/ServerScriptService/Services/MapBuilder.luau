--!strict
-- Shared cozy map + per-player interactive plot models.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MapBuilder = {}

local playerFolders: { [Player]: Folder } = {}
local playerSlots: { [Player]: number } = {}
local nextSlot = 0

local function part(props: {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	parent: Instance,
	canCollide: boolean?,
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
	p.Parent = props.parent
	return p
end

local function decorateZone(folder: Folder, zoneId: string, origin: Vector3, unlocked: boolean)
	local zone = Config.Zones[zoneId]
	local zoneFolder = Instance.new("Folder")
	zoneFolder.Name = zoneId
	zoneFolder.Parent = folder

	local groundColor = if unlocked then zone.color else Color3.fromRGB(70, 75, 70)
	part({
		name = "Ground",
		size = Vector3.new(42, 1, 28),
		cframe = CFrame.new(origin),
		color = groundColor,
		material = Enum.Material.Grass,
		parent = zoneFolder,
	})

	part({
		name = "Path",
		size = Vector3.new(8, 0.4, 28),
		cframe = CFrame.new(origin + Vector3.new(-18, 0.2, 0)),
		color = Config.Palette.Path,
		material = Enum.Material.Ground,
		parent = zoneFolder,
	})

	local sign = part({
		name = "Sign",
		size = Vector3.new(8, 3, 0.6),
		cframe = CFrame.new(origin + Vector3.new(0, 2.5, -12)),
		color = Config.Palette.Wood,
		material = Enum.Material.Wood,
		parent = zoneFolder,
	})
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(180, 40)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = sign
	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Text = if unlocked then zone.name else ("Locked: " .. zone.name)
	label.Parent = bb

	if not unlocked then
		-- Visual lock only; progression is enforced per-player on plots
		part({
			name = "LockBarrier",
			size = Vector3.new(42, 8, 28),
			cframe = CFrame.new(origin + Vector3.new(0, 4, 0)),
			color = Color3.fromRGB(40, 40, 40),
			material = Enum.Material.ForceField,
			transparency = 0.55,
			canCollide = false,
			parent = zoneFolder,
		})
	end

	if zoneId == "Greenhouse" then
		part({
			name = "GlassRoof",
			size = Vector3.new(44, 1, 30),
			cframe = CFrame.new(origin + Vector3.new(0, 9.5, 0)),
			color = Color3.fromRGB(180, 210, 220),
			material = Enum.Material.Glass,
			transparency = 0.45,
			canCollide = false,
			parent = zoneFolder,
		})
	end
end

function MapBuilder.Build()
	local existing = Workspace:FindFirstChild("GardenWorld")
	if existing then
		existing:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "GardenWorld"
	world.Parent = Workspace

	part({
		name = "Island",
		size = Vector3.new(160, 4, 100),
		cframe = CFrame.new(0, -2, 20),
		color = Color3.fromRGB(70, 120, 60),
		material = Enum.Material.Grass,
		parent = world,
	})

	part({
		name = "Plaza",
		size = Vector3.new(24, 1, 24),
		cframe = CFrame.new(0, 0.5, -20),
		color = Config.Palette.Path,
		material = Enum.Material.Cobblestone,
		parent = world,
	})

	part({
		name = "ShopStall",
		size = Vector3.new(10, 6, 6),
		cframe = CFrame.new(14, 3.5, -20),
		color = Config.Palette.Wood,
		material = Enum.Material.Wood,
		parent = world,
	})

	for _, old in Workspace:GetChildren() do
		if old:IsA("SpawnLocation") then
			old:Destroy()
		end
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 1, -20)
	spawn.Color = Color3.fromRGB(100, 160, 90)
	spawn.Material = Enum.Material.Grass
	spawn.Transparency = 0.2
	spawn.Parent = world

	decorateZone(world, "Starter", Config.Zones.Starter.origin, true)
	decorateZone(world, "Meadow", Config.Zones.Meadow.origin, false)
	decorateZone(world, "Greenhouse", Config.Zones.Greenhouse.origin, false)

	local plotsRoot = Instance.new("Folder")
	plotsRoot.Name = "PlayerPlots"
	plotsRoot.Parent = world

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Color = Color3.fromRGB(90, 160, 220)
		baseplate.Material = Enum.Material.SmoothPlastic
		baseplate.Size = Vector3.new(512, 1, 512)
		baseplate.Position = Vector3.new(0, -6, 0)
	end

	-- Soft lighting
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(140, 150, 130)
	lighting.OutdoorAmbient = Color3.fromRGB(150, 160, 140)
	lighting.Brightness = 2
	lighting.ClockTime = 14
end

local function makePlotModel(zoneId: string, plotIndex: number, origin: Vector3): Model
	local cols = 3
	local col = (plotIndex - 1) % cols
	local row = math.floor((plotIndex - 1) / cols)
	local pos = origin + Vector3.new(-6 + col * 8, 0.7, -4 + row * 8)

	local model = Instance.new("Model")
	model.Name = zoneId .. "_" .. tostring(plotIndex)
	model:SetAttribute("PlotId", zoneId .. "_" .. tostring(plotIndex))
	model:SetAttribute("ZoneId", zoneId)
	model:SetAttribute("PlotIndex", plotIndex)

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Anchored = true
	base.CanCollide = true
	base.Size = Vector3.new(6, 0.8, 6)
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
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = base

	return model
end

function MapBuilder.EnsurePlayerPlots(player: Player): Folder
	local world = Workspace:WaitForChild("GardenWorld")
	local root = world:FindFirstChild("PlayerPlots")
	if not root then
		root = Instance.new("Folder")
		root.Name = "PlayerPlots"
		root.Parent = world
	end

	local existing = playerFolders[player]
	if existing then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = "Plots_" .. player.Name
	folder.Parent = root

	-- Separate gardens on Z so multiplayer plots do not stack
	local slot = playerSlots[player]
	if slot == nil then
		slot = nextSlot
		nextSlot += 1
		playerSlots[player] = slot
	end
	local offset = Vector3.new(0, 0, slot * 48)

	for zoneId, zone in Config.Zones do
		for i = 1, zone.plotCount do
			local model = makePlotModel(zoneId, i, zone.origin + offset)
			model.Parent = folder
		end
	end

	folder:SetAttribute("GardenOffsetZ", offset.Z)
	playerFolders[player] = folder
	return folder
end

function MapBuilder.GetGardenOffset(player: Player): Vector3
	local slot = playerSlots[player] or 0
	return Vector3.new(0, 0, slot * 48)
end

function MapBuilder.ClearPlayerPlots(player: Player)
	local folder = playerFolders[player]
	if folder then
		folder:Destroy()
		playerFolders[player] = nil
	end
	playerSlots[player] = nil
end

function MapBuilder.UpdateZoneLocks(unlockedZones: { [string]: boolean })
	local world = Workspace:FindFirstChild("GardenWorld")
	if not world then
		return
	end
	for zoneId, unlocked in unlockedZones do
		local zone = world:FindFirstChild(zoneId)
		if zone then
			local barrier = zone:FindFirstChild("LockBarrier")
			if unlocked and barrier then
				barrier:Destroy()
			end
			local ground = zone:FindFirstChild("Ground")
			if ground and ground:IsA("BasePart") and unlocked then
				ground.Color = Config.Zones[zoneId].color
			end
			local sign = zone:FindFirstChild("Sign")
			if sign then
				local bb = sign:FindFirstChildOfClass("BillboardGui")
				local label = bb and bb:FindFirstChild("Title")
				if label and label:IsA("TextLabel") then
					label.Text = if unlocked then Config.Zones[zoneId].name else ("Locked: " .. Config.Zones[zoneId].name)
				end
			end
		end
	end

	-- Hide other players' locked-zone plot bases? Keep visible but prompts only work if unlocked in data.
end

function MapBuilder.SetPlantVisual(model: Model, seedId: string?, progress: number, ready: boolean)
	local folder = model:FindFirstChild("PlantVisual")
	local base = model:FindFirstChild("Base")
	if not folder or not base or not base:IsA("BasePart") then
		return
	end
	folder:ClearAllChildren()

	if not seedId then
		base.Color = Config.Palette.Dirt
		return
	end

	local def = Config.Seeds[seedId]
	if not def then
		return
	end
	base.Color = Color3.fromRGB(90, 65, 40)

	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Anchored = true
	stem.CanCollide = false
	stem.Material = Enum.Material.SmoothPlastic
	stem.Color = if ready then def.color else Color3.fromRGB(70, 120, 55)
	local height = 0.6 + math.clamp(progress, 0, 1) * 2.4
	stem.Size = Vector3.new(0.7, height, 0.7)
	stem.CFrame = base.CFrame * CFrame.new(0, 0.4 + height / 2, 0)
	stem.Parent = folder

	if ready or progress > 0.55 then
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Anchored = true
		head.CanCollide = false
		head.Shape = Enum.PartType.Ball
		head.Material = Enum.Material.SmoothPlastic
		head.Color = def.color
		local scale = if ready then 1 else 0.7
		head.Size = Vector3.new(1.4, 1.4, 1.4) * scale
		head.CFrame = stem.CFrame * CFrame.new(0, height * 0.35, 0)
		head.Parent = folder
	end
end

return MapBuilder
