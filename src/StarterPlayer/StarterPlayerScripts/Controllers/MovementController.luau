--!strict
-- Client movement tech: double jump + jump-pad feel + FOV punch hooks.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local MovementController = {}

local player = Players.LocalPlayer
local armed = false
local doubleReady = false
local onFov: ((number) -> ())? = nil

local function humanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function root(): BasePart?
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	if r and r:IsA("BasePart") then
		return r
	end
	return nil
end

function MovementController.setArmed(value: boolean)
	armed = value
end

function MovementController.onFovPunch(cb: (number) -> ())
	onFov = cb
end

function MovementController.start()
	local function bindCharacter(character: Model)
		local hum = character:WaitForChild("Humanoid") :: Humanoid
		doubleReady = false

		hum.StateChanged:Connect(function(_, new)
			if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
				doubleReady = true
			end
		end)

		hum.Jumping:Connect(function(active)
			if active then
				doubleReady = true
			end
		end)
	end

	if player.Character then
		bindCharacter(player.Character)
	end
	player.CharacterAdded:Connect(bindCharacter)

	UserInputService.JumpRequest:Connect(function()
		if not armed then
			return
		end
		local hum = humanoid()
		local r = root()
		if not hum or not r then
			return
		end
		if hum:GetState() == Enum.HumanoidStateType.Freefall and doubleReady then
			doubleReady = false
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, Config.Movement.DoubleJumpPower, r.AssemblyLinearVelocity.Z)
			if onFov then
				onFov(4)
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not armed then
			return
		end
		if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonR2 then
			Remotes.get("RequestSlam"):FireServer()
			if onFov then
				onFov(6)
			end
		end
	end)

	-- Jump pads also give local FOV
	task.spawn(function()
		local arena = Workspace:WaitForChild("NeonArena", 30)
		if not arena then
			return
		end
		for _, inst in arena:GetDescendants() do
			if inst:IsA("BasePart") and inst:GetAttribute("JumpPad") then
				inst.Touched:Connect(function(hit)
					if hit:IsDescendantOf(player.Character or Instance.new("Folder")) and onFov then
						onFov(5)
					end
				end)
			end
		end
	end)
end

return MovementController
