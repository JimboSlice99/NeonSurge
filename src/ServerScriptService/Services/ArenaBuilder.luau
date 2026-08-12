--!strict
-- Multi-level neon district: streets, ramps, pads, cover — dark, readable.

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
	p.CastShadow = true
	if props.shape then
		p.Shape = props.shape
	end
	p.Parent = props.parent
	return p
end

local function neonStrip(parent: Instance, cframe: CFrame, size: Vector3, color: Color3)
	part({
		name = "Strip",
		size = size,
		cframe = cframe,
		color = color,
		material = Enum.Material.Neon,
		transparency = 0.55,
		canCollide = false,
		parent = parent,
	})
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
	local levels = Config.Arena.Levels
	local levelH = Config.Arena.LevelHeight

	-- Ground plaza
	part({
		name = "Plaza",
		size = Vector3.new(radius * 2.4, 3, radius * 2.4),
		cframe = CFrame.new(0, floorY - 1.5, 0),
		color = Config.Palette.Floor,
		parent = arena,
	})

	-- Street lanes
	for _, z in ipairs({ -18, 0, 18 }) do
		part({
			name = "Street",
			size = Vector3.new(radius * 1.8, 0.2, 10),
			cframe = CFrame.new(0, floorY + 0.05, z),
			color = Color3.fromRGB(16, 18, 26),
			parent = arena,
		})
		neonStrip(arena, CFrame.new(0, floorY + 0.12, z - 4.2), Vector3.new(radius * 1.7, 0.08, 0.25), Config.Palette.Cyan)
		neonStrip(arena, CFrame.new(0, floorY + 0.12, z + 4.2), Vector3.new(radius * 1.7, 0.08, 0.25), Config.Palette.Magenta)
	end

	-- Perimeter buildings (visual depth)
	for i = 1, 16 do
		local angle = (i / 16) * math.pi * 2
		local dist = radius + 8
		local h = 24 + (i % 4) * 10
		part({
			name = "Building",
			size = Vector3.new(10, h, 10),
			cframe = CFrame.new(math.cos(angle) * dist, floorY + h / 2, math.sin(angle) * dist),
			color = Color3.fromRGB(14 + (i % 3) * 4, 16, 24),
			parent = arena,
			canCollide = false,
		})
		if i % 2 == 0 then
			neonStrip(
				arena,
				CFrame.new(math.cos(angle) * (dist - 5.1), floorY + h * 0.6, math.sin(angle) * (dist - 5.1)),
				Vector3.new(0.2, h * 0.5, 2),
				if i % 4 == 0 then Config.Palette.Violet else Config.Palette.Cyan
			)
		end
	end

	-- Soft arena wall
	for i = 1, 40 do
		local angle = (i / 40) * math.pi * 2
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		part({
			name = "Barrier",
			size = Vector3.new(radius * 2 * math.pi / 40 + 0.4, 10, 1.2),
			cframe = CFrame.new(x, floorY + 5, z) * CFrame.Angles(0, -angle, 0),
			color = Config.Palette.Wall,
			material = Enum.Material.Glass,
			transparency = 0.55,
			parent = arena,
		})
	end

	-- Upper decks + ramps
	for level = 1, levels - 1 do
		local y = floorY + level * levelH
		local deckR = radius * (0.72 - level * 0.08)

		-- Four platform wedges
		for q = 0, 3 do
			local angle = q * (math.pi / 2) + level * 0.2
			local cx = math.cos(angle) * (deckR * 0.55)
			local cz = math.sin(angle) * (deckR * 0.55)
			part({
				name = "Deck",
				size = Vector3.new(26, 1.2, 16),
				cframe = CFrame.new(cx, y, cz) * CFrame.Angles(0, -angle, 0),
				color = Color3.fromRGB(14, 16, 24),
				parent = arena,
			})
			neonStrip(arena, CFrame.new(cx, y + 0.7, cz) * CFrame.Angles(0, -angle, 0), Vector3.new(24, 0.1, 0.2), Config.Palette.Cyan)

			-- Ramp from below
			local below = y - levelH
			local ramp = part({
				name = "Ramp",
				size = Vector3.new(8, 1, 18),
				cframe = CFrame.new(cx * 0.7, (y + below) / 2, cz * 0.7)
					* CFrame.Angles(0, -angle, 0)
					* CFrame.Angles(math.rad(-28), 0, 0),
				color = Color3.fromRGB(20, 24, 34),
				parent = arena,
			})
			local _ = ramp
		end

		-- Center catwalk ring
		for i = 1, 12 do
			local angle = (i / 12) * math.pi * 2
			part({
				name = "Catwalk",
				size = Vector3.new(7, 0.8, 4),
				cframe = CFrame.new(math.cos(angle) * 14, y + 0.2, math.sin(angle) * 14) * CFrame.Angles(0, -angle, 0),
				color = Color3.fromRGB(18, 22, 32),
				parent = arena,
			})
		end
	end

	-- Jump pads
	local pads = {
		Vector3.new(20, floorY + 0.4, 20),
		Vector3.new(-22, floorY + 0.4, 16),
		Vector3.new(18, floorY + 0.4, -24),
		Vector3.new(-16, floorY + levelH + 0.4, 10),
		Vector3.new(12, floorY + levelH + 0.4, -14),
	}
	for i, pos in pads do
		local pad = part({
			name = "JumpPad",
			size = Vector3.new(6, 0.6, 6),
			cframe = CFrame.new(pos),
			color = Config.Palette.Orange,
			material = Enum.Material.Neon,
			transparency = 0.35,
			parent = arena,
		})
		pad:SetAttribute("JumpPad", true)
		pad:SetAttribute("Boost", 85 + i * 5)
		local light = Instance.new("PointLight")
		light.Brightness = 0.45
		light.Range = 12
		light.Color = Config.Palette.Orange
		light.Parent = pad
	end

	-- Cover pillars
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2 + 0.4
		local dist = 22
		part({
			name = "Cover",
			size = Vector3.new(4, 7, 4),
			cframe = CFrame.new(math.cos(angle) * dist, floorY + 3.5, math.sin(angle) * dist),
			color = Color3.fromRGB(22, 26, 38),
			parent = arena,
		})
	end

	-- Center monolith
	part({
		name = "Monolith",
		size = Vector3.new(3, 20, 3),
		cframe = CFrame.new(0, floorY + 10, 0),
		color = Color3.fromRGB(16, 18, 28),
		canCollide = false,
		parent = arena,
	})
	neonStrip(arena, CFrame.new(0, floorY + 12, 0), Vector3.new(3.2, 0.4, 3.2), Config.Palette.Violet)
	local monoLight = Instance.new("PointLight")
	monoLight.Color = Config.Palette.Violet
	monoLight.Brightness = 0.7
	monoLight.Range = 26
	monoLight.Parent = arena:FindFirstChild("Monolith") :: Instance

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
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, floorY + 1, 20)
	spawn.Color = Color3.fromRGB(30, 50, 58)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Transparency = 0.2
	spawn.Parent = arena

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Transparency = 1
		baseplate.CanCollide = false
	end

	return arena
end

function ArenaBuilder.spawnPoint(preferElevated: boolean?): CFrame
	local floorY = Config.Arena.FloorY
	local level = if preferElevated then math.random(0, Config.Arena.Levels - 1) else 0
	if math.random() < 0.45 then
		level = math.random(0, Config.Arena.Levels - 1)
	end
	local y = floorY + level * Config.Arena.LevelHeight + 4
	local angle = math.random() * math.pi * 2
	local dist = 18 + math.random() * 28
	return CFrame.new(math.cos(angle) * dist, y, math.sin(angle) * dist)
end

return ArenaBuilder
