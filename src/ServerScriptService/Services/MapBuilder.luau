--!strict
-- Industrial facility map — concrete, steel, no neon materials.

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
	p.Material = props.material or Enum.Material.Concrete
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

	-- Ground slab
	part({
		name = "Floor",
		size = Vector3.new(200, 3, 160),
		cframe = CFrame.new(0, -1.5, 0),
		color = Config.Palette.Floor,
		material = Enum.Material.Concrete,
		parent = folder,
	})

	-- Hangar walls
	part({
		name = "WallN",
		size = Vector3.new(200, 24, 3),
		cframe = CFrame.new(0, 10, -78),
		color = Color3.fromRGB(48, 46, 44),
		material = Enum.Material.Concrete,
		parent = folder,
	})
	part({
		name = "WallS",
		size = Vector3.new(200, 24, 3),
		cframe = CFrame.new(0, 10, 78),
		color = Color3.fromRGB(48, 46, 44),
		material = Enum.Material.Concrete,
		parent = folder,
	})
	part({
		name = "WallW",
		size = Vector3.new(3, 24, 160),
		cframe = CFrame.new(-98, 10, 0),
		color = Color3.fromRGB(48, 46, 44),
		material = Enum.Material.Concrete,
		parent = folder,
	})
	part({
		name = "WallE",
		size = Vector3.new(3, 24, 160),
		cframe = CFrame.new(98, 10, 0),
		color = Color3.fromRGB(48, 46, 44),
		material = Enum.Material.Concrete,
		parent = folder,
	})

	-- Ceiling beams (readable space, not void)
	for x = -80, 80, 20 do
		part({
			name = "Beam",
			size = Vector3.new(2, 2, 150),
			cframe = CFrame.new(x, 22, 0),
			color = Color3.fromRGB(60, 58, 54),
			material = Enum.Material.Metal,
			canCollide = false,
			parent = folder,
		})
	end

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

	for i = 1, #waypoints - 1 do
		local a = waypoints[i]
		local b = waypoints[i + 1]
		local mid = (a + b) / 2
		local delta = b - a
		local length = delta.Magnitude
		part({
			name = "Path",
			size = Vector3.new(math.max(length, 1), 0.5, 9),
			cframe = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0),
			color = Config.Palette.Path,
			material = Enum.Material.Slate,
			parent = folder,
		})
		-- Matte curb lines (not glowing)
		part({
			name = "Curb",
			size = Vector3.new(math.max(length, 1), 0.2, 0.35),
			cframe = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, 0.25, 4.2),
			color = Color3.fromRGB(90, 85, 75),
			material = Enum.Material.SmoothPlastic,
			canCollide = false,
			parent = folder,
		})
		part({
			name = "Curb",
			size = Vector3.new(math.max(length, 1), 0.2, 0.35),
			cframe = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(0, 0.25, -4.2),
			color = Color3.fromRGB(90, 85, 75),
			material = Enum.Material.SmoothPlastic,
			canCollide = false,
			parent = folder,
		})
	end

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
			material = Enum.Material.Metal,
			parent = folder,
		})
		plot:SetAttribute("PlotId", index)
		plot:SetAttribute("Occupied", false)
		-- etched square marker
		part({
			name = "PlotMark",
			size = Vector3.new(6.2, 0.08, 0.15),
			cframe = CFrame.new(pos.X, 0.55, pos.Z + 3),
			color = Config.Palette.Gold,
			material = Enum.Material.SmoothPlastic,
			canCollide = false,
			parent = folder,
		})
		part({
			name = "PlotMark",
			size = Vector3.new(6.2, 0.08, 0.15),
			cframe = CFrame.new(pos.X, 0.55, pos.Z - 3),
			color = Config.Palette.Gold,
			material = Enum.Material.SmoothPlastic,
			canCollide = false,
			parent = folder,
		})
		table.insert(plots, plot)
	end

	part({
		name = "Gate",
		size = Vector3.new(14, 12, 3),
		cframe = CFrame.new(waypoints[1] + Vector3.new(-5, 5, 0)),
		color = Color3.fromRGB(58, 56, 52),
		material = Enum.Material.Metal,
		parent = folder,
	})

	local corePos = waypoints[#waypoints] + Vector3.new(8, 0, 0)
	local core = part({
		name = "SurgeCore",
		size = Vector3.new(10, 12, 10),
		cframe = CFrame.new(corePos.X, 6, corePos.Z),
		color = Color3.fromRGB(52, 50, 48),
		material = Enum.Material.Metal,
		parent = folder,
	})
	part({
		name = "CoreBand",
		size = Vector3.new(10.4, 1.2, 10.4),
		cframe = CFrame.new(corePos.X, 8, corePos.Z),
		color = Config.Palette.Gold,
		material = Enum.Material.SmoothPlastic,
		canCollide = false,
		parent = folder,
	})
	-- Soft practical light only
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 180)
	light.Brightness = 0.55
	light.Range = 30
	light.Parent = core

	-- Sparse warm hangar lights
	for _, pos in ipairs({
		Vector3.new(-40, 18, -20),
		Vector3.new(0, 18, 10),
		Vector3.new(40, 18, -10),
		Vector3.new(20, 18, 40),
	}) do
		local lamp = part({
			name = "Lamp",
			size = Vector3.new(4, 0.6, 4),
			cframe = CFrame.new(pos),
			color = Color3.fromRGB(200, 190, 160),
			material = Enum.Material.SmoothPlastic,
			canCollide = false,
			parent = folder,
		})
		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromRGB(255, 230, 190)
		pl.Brightness = 0.4
		pl.Range = 40
		pl.Parent = lamp
	end

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
	spawn.CFrame = CFrame.new(0, 14, 62)
	spawn.Transparency = 0.2
	spawn.Color = Color3.fromRGB(70, 68, 62)
	spawn.Material = Enum.Material.Concrete
	spawn.Parent = folder

	part({
		name = "Deck",
		size = Vector3.new(44, 1.2, 22),
		cframe = CFrame.new(0, 13, 62),
		color = Color3.fromRGB(50, 48, 44),
		material = Enum.Material.Concrete,
		parent = folder,
	})
	part({
		name = "Rail",
		size = Vector3.new(44, 1.5, 0.5),
		cframe = CFrame.new(0, 14.5, 52),
		color = Color3.fromRGB(90, 85, 75),
		material = Enum.Material.Metal,
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
