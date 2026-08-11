--!strict

local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local ArenaBuilder = {}

local function neonPart(props: {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	parent: Instance,
	canCollide: boolean?,
}): Part
	local part = Instance.new("Part")
	part.Name = props.name
	part.Anchored = true
	part.CanCollide = if props.canCollide == nil then true else props.canCollide
	part.Size = props.size
	part.CFrame = props.cframe
	part.Color = props.color
	part.Material = props.material or Enum.Material.Neon
	part.Transparency = props.transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = props.parent
	return part
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

	-- Visible arena floor
	neonPart({
		name = "ArenaFloor",
		size = Vector3.new(radius * 2.2, 1, radius * 2.2),
		cframe = CFrame.new(0, floorY - 0.5, 0),
		color = Config.Palette.Floor,
		material = Enum.Material.SmoothPlastic,
		parent = arena,
	})

	-- Neon grid so the floor reads clearly
	local gridStep = 10
	local gridExtent = math.floor(radius)
	for x = -gridExtent, gridExtent, gridStep do
		neonPart({
			name = ("GridX_%d"):format(x),
			size = Vector3.new(0.35, 0.2, radius * 2),
			cframe = CFrame.new(x, floorY + 0.1, 0),
			color = Config.Palette.Cyan,
			transparency = 0.35,
			canCollide = false,
			parent = arena,
		})
	end
	for z = -gridExtent, gridExtent, gridStep do
		neonPart({
			name = ("GridZ_%d"):format(z),
			size = Vector3.new(radius * 2, 0.2, 0.35),
			cframe = CFrame.new(0, floorY + 0.1, z),
			color = Config.Palette.Magenta,
			transparency = 0.45,
			canCollide = false,
			parent = arena,
		})
	end

	-- Concentric neon lanes (cylinder laid flat on the arena floor)
	for i, color in ipairs({ Config.Palette.Cyan, Config.Palette.Magenta, Config.Palette.Violet }) do
		local r = radius * (0.35 + i * 0.18)
		local lane = neonPart({
			name = ("LaneRing_%d"):format(i),
			size = Vector3.new(0.35, r * 2, r * 2),
			cframe = CFrame.new(0, floorY + 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
			color = color,
			transparency = 0.25,
			canCollide = false,
			parent = arena,
		})
		lane.Shape = Enum.PartType.Cylinder
	end

	-- Outer wall segments
	local segments = Config.Arena.RingSegments
	for i = 1, segments do
		local angle = (i / segments) * math.pi * 2
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local part = neonPart({
			name = ("Wall_%d"):format(i),
			size = Vector3.new(radius * 2 * math.pi / segments + 0.4, Config.Arena.WallHeight, 1.4),
			cframe = CFrame.new(x, floorY + Config.Arena.WallHeight / 2, z) * CFrame.Angles(0, -angle, 0),
			color = if i % 2 == 0 then Config.Palette.Wall else Config.Palette.Violet,
			material = if i % 3 == 0 then Enum.Material.Neon else Enum.Material.SmoothPlastic,
			transparency = if i % 3 == 0 then 0.15 else 0.35,
			parent = arena,
		})
		if i % 3 == 0 then
			local light = Instance.new("PointLight")
			light.Color = Config.Palette.Cyan
			light.Brightness = 1.2
			light.Range = 18
			light.Parent = part
		end
	end

	-- Center pylon
	local pylon = neonPart({
		name = "CenterPylon",
		size = Vector3.new(2.5, 14, 2.5),
		cframe = CFrame.new(0, floorY + 7, 0),
		color = Config.Palette.Cyan,
		parent = arena,
		canCollide = false,
	})
	local pylonLight = Instance.new("PointLight")
	pylonLight.Color = Config.Palette.Cyan
	pylonLight.Brightness = 3
	pylonLight.Range = 40
	pylonLight.Parent = pylon

	-- Force a reliable spawn on the arena floor
	local oldSpawn = Workspace:FindFirstChildWhichIsA("SpawnLocation")
	if oldSpawn then
		oldSpawn:Destroy()
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "NeonSpawn"
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, floorY + 0.5, 0)
	spawn.Color = Config.Palette.Cyan
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.35
	spawn.Parent = arena

	-- Hide default baseplate under the neon floor if present
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
	local x = math.cos(angle) * dist
	local z = math.sin(angle) * dist
	return CFrame.new(x, Config.Arena.FloorY + 3, z)
end

return ArenaBuilder
