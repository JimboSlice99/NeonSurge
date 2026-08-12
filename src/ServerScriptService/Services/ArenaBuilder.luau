--!strict

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

	part({
		name = "ArenaFloor",
		size = Vector3.new(radius * 2.4, 2, radius * 2.4),
		cframe = CFrame.new(0, floorY - 1, 0),
		color = Config.Palette.Floor,
		parent = arena,
	})

	-- Bright under-glow so the floor never reads as void
	local glow = part({
		name = "FloorGlow",
		size = Vector3.new(radius * 2.2, 0.4, radius * 2.2),
		cframe = CFrame.new(0, floorY + 0.05, 0),
		color = Config.Palette.Cyan,
		material = Enum.Material.Neon,
		transparency = 0.82,
		canCollide = false,
		parent = arena,
	})
	local floorLight = Instance.new("PointLight")
	floorLight.Color = Config.Palette.Cyan
	floorLight.Brightness = 2
	floorLight.Range = 60
	floorLight.Parent = glow

	local step = 8
	for x = -radius, radius, step do
		part({
			name = "GridX",
			size = Vector3.new(0.4, 0.25, radius * 2),
			cframe = CFrame.new(x, floorY + 0.15, 0),
			color = Config.Palette.Cyan,
			material = Enum.Material.Neon,
			transparency = 0.25,
			canCollide = false,
			parent = arena,
		})
	end
	for z = -radius, radius, step do
		part({
			name = "GridZ",
			size = Vector3.new(radius * 2, 0.25, 0.4),
			cframe = CFrame.new(0, floorY + 0.15, z),
			color = Config.Palette.Magenta,
			material = Enum.Material.Neon,
			transparency = 0.4,
			canCollide = false,
			parent = arena,
		})
	end

	for i = 1, Config.Arena.RingSegments do
		local angle = (i / Config.Arena.RingSegments) * math.pi * 2
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local wall = part({
			name = "Wall",
			size = Vector3.new(radius * 2 * math.pi / Config.Arena.RingSegments + 0.5, Config.Arena.WallHeight, 1.6),
			cframe = CFrame.new(x, floorY + Config.Arena.WallHeight / 2, z) * CFrame.Angles(0, -angle, 0),
			color = if i % 2 == 0 then Config.Palette.Wall else Config.Palette.Violet,
			material = if i % 2 == 0 then Enum.Material.SmoothPlastic else Enum.Material.Neon,
			transparency = if i % 2 == 0 then 0.2 else 0.05,
			parent = arena,
		})
		if i % 3 == 0 then
			local light = Instance.new("PointLight")
			light.Color = Config.Palette.Violet
			light.Brightness = 1.5
			light.Range = 20
			light.Parent = wall
		end
	end

	local pylon = part({
		name = "CenterPylon",
		size = Vector3.new(3, 16, 3),
		cframe = CFrame.new(0, floorY + 8, 0),
		color = Config.Palette.Cyan,
		material = Enum.Material.Neon,
		canCollide = false,
		parent = arena,
	})
	local pylonLight = Instance.new("PointLight")
	pylonLight.Color = Config.Palette.Cyan
	pylonLight.Brightness = 4
	pylonLight.Range = 50
	pylonLight.Parent = pylon

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
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, floorY + 0.5, 12)
	spawn.Color = Config.Palette.Gold
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.2
	spawn.Parent = arena

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
	local dist = radius * (0.6 + math.random() * 0.35)
	return CFrame.new(math.cos(angle) * dist, Config.Arena.FloorY + 3, math.sin(angle) * dist)
end

return ArenaBuilder
