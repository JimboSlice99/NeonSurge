--!strict
-- Neon conduit map: winding path, build plots, surge core.

local Workspace = game:GetService("Workspace")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local MapBuilder = {}

export type MapData = {
	folder: Folder,
	waypoints: { Vector3 },
	plots: { BasePart },
	core: BasePart,
}

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
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.Transparency = props.transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
	p.Parent = props.parent
	return p
end

function MapBuilder.build(): MapData
	local existing = Workspace:FindFirstChild("NeonMap")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "NeonMap"
	folder.Parent = Workspace

	-- Floor
	part({
		name = "Floor",
		size = Vector3.new(180, 2, 140),
		cframe = CFrame.new(0, -1, 0),
		color = Config.Palette.Floor,
		parent = folder,
	})

	-- Path waypoints (serpentine)
	local waypoints = {
		Vector3.new(-70, 1.5, -40),
		Vector3.new(-40, 1.5, -40),
		Vector3.new(-40, 1.5, 0),
		Vector3.new(-10, 1.5, 0),
		Vector3.new(-10, 1.5, 35),
		Vector3.new(25, 1.5, 35),
		Vector3.new(25, 1.5, -15),
		Vector3.new(55, 1.5, -15),
		Vector3.new(55, 1.5, 20),
		Vector3.new(70, 1.5, 20),
	}

	-- Draw path segments
	for i = 1, #waypoints - 1 do
		local a = waypoints[i]
		local b = waypoints[i + 1]
		local mid = (a + b) / 2
		local delta = b - a
		local length = delta.Magnitude
		local path = part({
			name = "Path",
			size = Vector3.new(math.max(length, 1), 0.4, 8),
			cframe = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0),
			color = Config.Palette.Path,
			parent = folder,
		})
		-- edge glow strips
		part({
			name = "PathEdge",
			size = Vector3.new(math.max(length, 1), 0.15, 0.25),
			cframe = path.CFrame * CFrame.new(0, 0.2, 3.6),
			color = Config.Palette.Cyan,
			material = Enum.Material.Neon,
			transparency = 0.55,
			canCollide = false,
			parent = folder,
		})
		part({
			name = "PathEdge",
			size = Vector3.new(math.max(length, 1), 0.15, 0.25),
			cframe = path.CFrame * CFrame.new(0, 0.2, -3.6),
			color = Config.Palette.Magenta,
			material = Enum.Material.Neon,
			transparency = 0.65,
			canCollide = false,
			parent = folder,
		})
	end

	-- Build plots beside path
	local plotOffsets = {
		{ i = 1, side = 12 },
		{ i = 1, side = -12 },
		{ i = 2, side = 12 },
		{ i = 2, side = -12 },
		{ i = 3, side = 12 },
		{ i = 3, side = -12 },
		{ i = 4, side = 12 },
		{ i = 4, side = -12 },
		{ i = 5, side = 12 },
		{ i = 5, side = -12 },
		{ i = 6, side = 12 },
		{ i = 6, side = -12 },
		{ i = 7, side = 12 },
		{ i = 7, side = -12 },
		{ i = 8, side = 12 },
		{ i = 8, side = -12 },
		{ i = 9, side = 12 },
		{ i = 9, side = -12 },
	}

	local plots: { BasePart } = {}
	for index, info in plotOffsets do
		local wp = waypoints[info.i]
		local nxt = waypoints[math.min(info.i + 1, #waypoints)]
		local dir = (nxt - wp)
		local flat = Vector3.new(dir.X, 0, dir.Z)
		if flat.Magnitude < 0.1 then
			flat = Vector3.new(1, 0, 0)
		end
		flat = flat.Unit
		local side = Vector3.new(-flat.Z, 0, flat.X) * info.side
		local pos = wp + (nxt - wp) * 0.5 + side
		local plot = part({
			name = "Plot",
			size = Vector3.new(7, 0.5, 7),
			cframe = CFrame.new(pos.X, 0.25, pos.Z),
			color = Config.Palette.Build,
			parent = folder,
		})
		plot:SetAttribute("PlotId", index)
		plot:SetAttribute("Occupied", false)
		local ring = part({
			name = "PlotRing",
			size = Vector3.new(0.15, 7.4, 7.4),
			cframe = CFrame.new(pos.X, 0.4, pos.Z) * CFrame.Angles(0, 0, math.rad(90)),
			color = Config.Palette.Cyan,
			material = Enum.Material.Neon,
			transparency = 0.7,
			canCollide = false,
			parent = folder,
		})
		ring.Shape = Enum.PartType.Cylinder
		table.insert(plots, plot)
	end

	-- Entrance gate
	part({
		name = "Gate",
		size = Vector3.new(12, 10, 2),
		cframe = CFrame.new(waypoints[1] + Vector3.new(-4, 4, 0)),
		color = Color3.fromRGB(20, 24, 36),
		parent = folder,
	})
	part({
		name = "GateLight",
		size = Vector3.new(10, 0.4, 0.4),
		cframe = CFrame.new(waypoints[1] + Vector3.new(-4, 8, 0)),
		color = Config.Palette.Orange,
		material = Enum.Material.Neon,
		transparency = 0.2,
		canCollide = false,
		parent = folder,
	})

	-- Surge Core
	local corePos = waypoints[#waypoints] + Vector3.new(8, 0, 0)
	local core = part({
		name = "SurgeCore",
		size = Vector3.new(8, 10, 8),
		cframe = CFrame.new(corePos.X, 5, corePos.Z),
		color = Color3.fromRGB(18, 22, 34),
		parent = folder,
	})
	local coreGlow = part({
		name = "CoreGlow",
		size = Vector3.new(6, 6, 6),
		cframe = CFrame.new(corePos.X, 5, corePos.Z),
		color = Config.Palette.Violet,
		material = Enum.Material.Neon,
		transparency = 0.35,
		canCollide = false,
		parent = folder,
	})
	coreGlow.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = Config.Palette.Violet
	light.Brightness = 0.7
	light.Range = 28
	light.Parent = coreGlow

	-- Spawn for players (viewing platform)
	for _, old in Workspace:GetChildren() do
		if old:IsA("SpawnLocation") then
			old:Destroy()
		end
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "ViewerSpawn"
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, 18, 70)
	spawn.Transparency = 0.3
	spawn.Color = Color3.fromRGB(30, 50, 58)
	spawn.Parent = folder

	-- Viewing deck
	part({
		name = "Deck",
		size = Vector3.new(40, 1, 20),
		cframe = CFrame.new(0, 17, 70),
		color = Color3.fromRGB(16, 20, 30),
		parent = folder,
	})
	part({
		name = "Rail",
		size = Vector3.new(40, 2, 0.4),
		cframe = CFrame.new(0, 18.5, 60),
		color = Config.Palette.Cyan,
		material = Enum.Material.Neon,
		transparency = 0.5,
		canCollide = false,
		parent = folder,
	})

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Transparency = 1
		baseplate.CanCollide = false
	end

	return {
		folder = folder,
		waypoints = waypoints,
		plots = plots,
		core = core,
	}
end

return MapBuilder
