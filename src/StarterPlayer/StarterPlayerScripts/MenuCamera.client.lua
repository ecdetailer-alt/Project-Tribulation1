local parent = script.Parent

local MenuCameraController = require(parent:WaitForChild("MenuCameraController"))
local MenuSceneVisualController = require(parent:WaitForChild("MenuSceneVisualController"))

local cameraController = MenuCameraController.new()
local visualController = MenuSceneVisualController.new()

cameraController:Start()
visualController:Start()

script.Destroying:Connect(function()
	visualController:Destroy()
	cameraController:Destroy()
end)
