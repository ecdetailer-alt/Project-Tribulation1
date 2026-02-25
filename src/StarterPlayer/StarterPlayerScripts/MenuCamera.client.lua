local MenuCameraController = require(script:WaitForChild("MenuCameraController"))

local controller = MenuCameraController.new()
controller:Start()

script.Destroying:Connect(function()
	controller:Destroy()
end)
