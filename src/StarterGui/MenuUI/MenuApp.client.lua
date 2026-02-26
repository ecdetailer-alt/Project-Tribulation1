local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local menuFolder = ReplicatedStorage:WaitForChild("Menu")
local MenuController = require(menuFolder:WaitForChild("MenuController"))

local modules = script:WaitForChild("Modules")
local MenuBuild = require(modules:WaitForChild("MenuBuild"))
local MenuAnim = require(modules:WaitForChild("MenuAnim"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local controller = MenuController.new({
	PlayerGui = playerGui,
	MenuBuild = MenuBuild,
	MenuAnim = MenuAnim,
})

controller:Start()

script.Destroying:Connect(function()
	controller:Destroy()
end)
