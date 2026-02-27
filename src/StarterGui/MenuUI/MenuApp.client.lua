local Players = game:GetService("Players")

local controllers = script.Parent:WaitForChild("Controllers")
local CameraController = require(controllers:WaitForChild("CameraController"))
local AmbienceController = require(controllers:WaitForChild("AmbienceController"))
local UIController = require(controllers:WaitForChild("UIController"))
local ModeHandler = require(controllers:WaitForChild("ModeHandler"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local cameraController = CameraController.new({
	FieldOfView = 67,
	AnchorName = "MenuCharacterAnchor",
	LookPartNames = { "DomeField", "BreachHorizon", "FogSheet" },
})

local modeHandler = ModeHandler.new({
	Player = localPlayer,
	PlaceIds = {
		Campaign = 0,
		OpenWorld = 0,
	},
})

local uiController = UIController.new({
	PlayerGui = playerGui,
	OnCampaign = function()
		modeHandler:SelectMode("Campaign")
	end,
	OnOpenWorld = function()
		modeHandler:SelectMode("OpenWorld")
	end,
	OnParty = function()
		modeHandler:HandleMenuAction("Party")
	end,
	OnSettings = function()
		modeHandler:HandleMenuAction("Settings")
	end,
})

modeHandler:SetStatusCallback(function(text, isError)
	uiController:SetStatus(text, isError)
end)

local ambienceController = AmbienceController.new({
	PlayerGui = playerGui,
})

cameraController:Start()
ambienceController:Start()
uiController:Start()
uiController:SetStatus("Awaiting deployment input.", false)

script.Destroying:Connect(function()
	uiController:Destroy()
	ambienceController:Destroy()
	cameraController:Destroy()
end)
