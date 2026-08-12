--!strict
-- Dark cyber arena: readable silhouette, sparse accent neon — not a light show.

local Workspace = game:GetService("Workspace")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local ArenaBuilder = {}

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
	reflectance: number?,
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
	p.Reflectance = props.reflectance or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
	if props.shape then
		p.Shape = props.shape
	end
	p.Parent = props.parent
	return p
end

function ArenaBuilder.build()
	local existing = Workspace:FindFirstChild("NeonArena")
	if existing then
		existing:Destroy()
	end

	local arena = Instance.new("Folder")
	arena.Name = "NeonArena"
	arena.Parent = Workspace

	local radius = Config.Arena.Radius
	local floorY = Config.Arena.FloorY

	-- Matte dark floor (main readable plane)
	part({
		name = "ArenaFloor",
		size = Vector3.new(radius * 2.5, 2.2, radius * 2.5),
		cframe = CFrame.new(0, floorY - 1.1, 0),
		color = Config.Palette.Floor,
		material = Enum.Material.SmoothPlastic,
		parent = arena,
	})

	-- Soft rim plate
	part({
		name = "FloorRim",
		size = Vector3.new(radius * 2.15, 0.15, radius * 2.15),
		cframe = CFrame.new(0, floorY + 0.02, 0) * CFrame.Angles(0, 0, math.rad(90)),
		color = Config.Palette.Accent,
		material = Enum.Material.Neon,
		transparency = 0.72,
		canCollide = false,
		shape = Enum.PartType.Cylinder,
		parent = arena,
	})

	-- Sparse lane rings (thin, dim)
	for i, color in ipairs({ Config.Palette.Cyan, Config.Palette.Violet }) do
		local r = radius * (0.42 + i * 0.22)
		part({
			name = "Lane",
			size = Vector3.new(0.12, r * 2, r * 2),
			cframe = CFrame.new(0, floorY + 0.08, 0) * CFrame.Angles(0, 0, math.rad(90)),
			color = color,
			material = Enum.Material.Neon,
			transparency = 0.78,
			canCollide = false,
			shape = Enum.PartType.Cylinder,
			parent = arena,
		})
	end

	-- Thin etched grid (plastic, not neon flood)
	local step = 12
	for x = -radius + 6, radius - 6, step do
		part({
			name = "EtchX",
			size = Vector3.new(0.08, 0.05, radius * 1.7),
			cframe = CFrame.new(x, floorY + 0.06, 0),
			color = Color3.fromRGB(30, 40, 60),
			material = Enum.Material.SmoothPlastic,
			transparency = 0.35,
			canCollide = false,
			parent = arena,
		})
	end
	for z = -radius + 6, radius - 6, step do
		part({
			name = "EtchZ",
			size = Vector3.new(radius * 1.7, 0.05, 0.08),
			cframe = CFrame.new(0, floorY + 0.06, z),
			color = Color3.fromRGB(30, 40, 60),
			material = Enum.Material.SmoothPlastic,
			transparency = 0.45,
			canCollide = false,
			parent = arena,
		})
	end

	-- Perimeter walls: mostly dark glass, rare neon seams
	for i = 1, Config.Arena.RingSegments do
		local angle = (i / Config.Arena.RingSegments) * math.pi * 2
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local isSeam = i % 5 == 0
		local wall = part({
			name = "Wall",
			size = Vector3.new(radius * 2 * math.pi / Config.Arena.RingSegments + 0.35, Config.Arena.WallHeight, 1.2),
			cframe = CFrame.new(x, floorY + Config.Arena.WallHeight / 2, z) * CFrame.Angles(0, -angle, 0),
			color = if isSeam then Config.Palette.Cyan else Config.Palette.Wall,
			material = if isSeam then Enum.Material.Neon else Enum.Material.Glass,
			transparency = if isSeam then 0.55 else 0.45,
			reflectance = if isSeam then 0 else 0.1,
			parent = arena,
		})
		-- Only a few soft lights on the whole arena
		if i % 10 == 0 then
			local light = Instance.new("PointLight")
			light.Color = Config.Palette.Cyan
			light.Brightness = 0.55
			light.Range = 22
			light.Shadows = false
			light.Parent = wall
		end
	end

	-- Center monolith (accent, one light)
	local pylon = part({
		name = "Monolith",
		size = Vector3.new(2.2, 11, 2.2),
		cframe = CFrame.new(0, floorY + 5.5, 0),
		color = Color3.fromRGB(18, 22, 34),
		material = Enum.Material.SmoothPlastic,
		canCollide = false,
		parent = arena,
	})
	local stripe = part({
		name = "MonolithStripe",
		size = Vector3.new(2.35, 0.35, 2.35),
		cframe = CFrame.new(0, floorY + 7, 0),
		color = Config.Palette.Cyan,
		material = Enum.Material.Neon,
		transparency = 0.25,
		canCollide = false,
		parent = arena,
	})
	local pylonLight = Instance.new("PointLight")
	pylonLight.Color = Config.Palette.Cyan
	pylonLight.Brightness = 0.8
	pylonLight.Range = 28
	pylonLight.Parent = stripe

	-- Outer haze pillars for depth
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		local dist = radius + 10
		part({
			name = "HazePillar",
			size = Vector3.new(3, 28, 3),
			cframe = CFrame.new(math.cos(angle) * dist, floorY + 14, math.sin(angle) * dist),
			color = Color3.fromRGB(16, 18, 28),
			material = Enum.Material.SmoothPlastic,
			transparency = 0.2,
			canCollide = false,
			parent = arena,
		})
	end

	for _, old in Workspace:GetChildren() do
		if old:IsA("SpawnLocation") then
			old:Destroy()
		end
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "NeonSpawn"
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Size = Vector3.new(7, 0.6, 7)
	spawn.CFrame = CFrame.new(0, floorY + 0.35, 14)
	spawn.Color = Color3.fromRGB(28, 50, 60)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Transparency = 0.15
	spawn.Parent = arena

	local spawnRing = part({
		name = "SpawnRing",
		size = Vector3.new(0.15, 9, 9),
		cframe = CFrame.new(0, floorY + 0.4, 14) * CFrame.Angles(0, 0, math.rad(90)),
		color = Config.Palette.Cyan,
		material = Enum.Material.Neon,
		transparency = 0.65,
		canCollide = false,
		shape = Enum.PartType.Cylinder,
		parent = arena,
	})
	local _ = spawnRing
	local _ = pylon

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Transparency = 1
		baseplate.CanCollide = false
	end

	return arena
end

function ArenaBuilder.randomSpawnCFrame(): CFrame
	local radius = Config.Arena.Radius - Config.Arena.SpawnClearance
	local angle = math.random() * math.pi * 2
	local dist = radius * (0.55 + math.random() * 0.4)
	return CFrame.new(math.cos(angle) * dist, Config.Arena.FloorY + 3, math.sin(angle) * dist)
end

return ArenaBuilder
