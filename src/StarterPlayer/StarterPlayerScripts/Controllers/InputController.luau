--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))

local InputController = {}

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local armed = false

local function plotFromTarget(target: Instance?): BasePart?
	if not target then
		return nil
	end
	if target:IsA("BasePart") and target.Name == "Plot" then
		return target
	end
	local model = target:FindFirstAncestorOfClass("Model")
	if model and model.PrimaryPart then
		-- clicked a tower; find its plot via nearby plots
		local map = Workspace:FindFirstChild("NeonMap")
		if map then
			for _, inst in map:GetChildren() do
				if inst:IsA("BasePart") and inst.Name == "Plot" then
					if (inst.Position - model.PrimaryPart.Position).Magnitude < 6 then
						return inst
					end
				end
			end
		end
	end
	return nil
end

function InputController.setArmed(value: boolean)
	armed = value
end

function InputController.start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not armed then
			return
		end
		if input.KeyCode == Enum.KeyCode.One then
			Remotes.get("RequestSelectBuild"):FireServer("Pulse")
		elseif input.KeyCode == Enum.KeyCode.Two then
			Remotes.get("RequestSelectBuild"):FireServer("Beam")
		elseif input.KeyCode == Enum.KeyCode.Three then
			Remotes.get("RequestSelectBuild"):FireServer("Frost")
		elseif input.KeyCode == Enum.KeyCode.Four then
			Remotes.get("RequestSelectBuild"):FireServer("Nova")
		elseif input.KeyCode == Enum.KeyCode.R then
			Remotes.get("RequestRestart"):FireServer()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			local plot = plotFromTarget(mouse.Target)
			if plot then
				local occupied = plot:GetAttribute("Occupied") == true
				if occupied then
					Remotes.get("RequestUpgradeTower"):FireServer(plot:GetAttribute("PlotId"))
				else
					Remotes.get("RequestPlaceTower"):FireServer(plot:GetAttribute("PlotId"))
				end
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			local plot = plotFromTarget(mouse.Target)
			if plot and plot:GetAttribute("Occupied") == true then
				Remotes.get("RequestSellTower"):FireServer(plot:GetAttribute("PlotId"))
			end
		end
	end)

	ContextActionService:BindAction("NeonRestart", function(_n, state)
		if state == Enum.UserInputState.Begin then
			Remotes.get("RequestRestart"):FireServer()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonB)
end

return InputController
