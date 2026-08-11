--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))

local InputController = {}

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local firing = true
local camera = Workspace.CurrentCamera

local function aimDirection(): Vector3
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or not camera then
		return Vector3.new(0, 0, -1)
	end

	local hit = mouse.Hit
	if hit then
		local flat = Vector3.new(hit.Position.X - root.Position.X, 0, hit.Position.Z - root.Position.Z)
		if flat.Magnitude > 0.2 then
			return flat.Unit
		end
	end

	return Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
end

local function moveDirection(): Vector3
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
		return Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z).Unit
	end
	return aimDirection()
end

local function onDash(_name: string, state: Enum.UserInputState)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	Remotes.get("RequestDash"):FireServer(moveDirection())
	return Enum.ContextActionResult.Sink
end

local function onRestart(_name: string, state: Enum.UserInputState)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	Remotes.get("RequestRestart"):FireServer()
	return Enum.ContextActionResult.Sink
end

function InputController.start()
	ContextActionService:BindAction("NeonDash", onDash, true, Enum.KeyCode.Q, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL2)
	ContextActionService:SetTitle("NeonDash", "Dash")
	ContextActionService:SetPosition("NeonDash", UDim2.fromScale(0.7, 0.35))

	ContextActionService:BindAction("NeonRestart", onRestart, false, Enum.KeyCode.R, Enum.KeyCode.ButtonY)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			firing = true
		end
	end)

	-- Auto-fire loop; hold LMB optional, always surging by default
	RunService.RenderStepped:Connect(function()
		if not firing then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end
		Remotes.get("RequestFire"):FireServer(aimDirection())
	end)
end

return InputController
