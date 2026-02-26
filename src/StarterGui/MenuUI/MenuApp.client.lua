local Players = game:GetService("Players")

local modules = script:WaitForChild("Modules")
local MenuUI = require(modules:WaitForChild("MenuUI"))
local MenuAnimations = require(modules:WaitForChild("MenuAnimations"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local menuUI = MenuUI.new(playerGui)
local menuAnimations = MenuAnimations.new(menuUI)

menuUI:SetActionHandler(function()
	-- Action handling is intentionally left for gameplay wiring.
end)

menuAnimations:PlayIntro()

script.Destroying:Connect(function()
	menuAnimations:Destroy()
	menuUI:Destroy()
end)
