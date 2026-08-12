--!strict

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CameraController = {}

local baseFov = 70
local punch = 0

function CameraController.punch(amount: number)
	punch = math.max(punch, amount)
end

function CameraController.start()
	RunService.RenderStepped:Connect(function(dt)
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end
		punch = math.max(0, punch - dt * 18)
		cam.FieldOfView = baseFov + punch
	end)
end

return CameraController
