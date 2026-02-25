local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local menuFolder = ReplicatedStorage:WaitForChild("Menu")
local partyFolder = ReplicatedStorage:WaitForChild("Party")

local MenuActions = require(menuFolder:WaitForChild("MenuActions"))
local MenuController = require(menuFolder:WaitForChild("MenuController"))
local SignalBus = require(menuFolder:WaitForChild("SignalBus"))
local PartyClient = require(partyFolder:WaitForChild("PartyClient"))
local MenuView = require(script.Parent:WaitForChild("Modules"):WaitForChild("MenuView"))
local CharacterPreview = require(script.Parent:WaitForChild("Modules"):WaitForChild("CharacterPreview"))

local signalBus = SignalBus.getShared()
local menuView = MenuView.new(playerGui, MenuActions)
local menuController = MenuController.new(signalBus)
local partyClient = PartyClient.new(signalBus)
local characterPreview = CharacterPreview.new(menuView:GetCharacterViewport())

characterPreview:bindLocalPlayer()

local connections = {}
local isRunning = true

menuView:BindActions(function(actionId)
	signalBus:Fire("MenuActionRequested", { ActionId = actionId })
end)

menuView:BindPartyActions({
	OnCreateParty = function()
		partyClient:CreateParty()
	end,
	OnRefreshParty = function()
		partyClient:RequestState()
	end,
	OnInviteUserId = function(userId)
		partyClient:InviteUserId(userId)
	end,
})

table.insert(connections, signalBus:Connect("MenuPanelChanged", function(payload)
	menuView:SetPanel(payload and payload.PanelId)
end))

table.insert(connections, signalBus:Connect("MenuStatus", function(payload)
	menuView:SetStatus(payload and payload.Text or "", payload and payload.IsError == true)
end))

table.insert(connections, signalBus:Connect("PartyStateUpdated", function(state)
	menuView:SetPartyState(state or {})
end))

table.insert(connections, signalBus:Connect("PartyRefreshRequested", function()
	partyClient:RequestState()
end))

table.insert(connections, signalBus:Connect("PartyInviteReceived", function(payload)
	local fromName = payload and payload.FromName or "Unknown"
	menuView:SetStatus(string.format("Invite received from %s.", fromName), false)
end))

table.insert(connections, RunService.RenderStepped:Connect(function(dt)
	menuView:Step(dt)
end))

menuController:Start()
partyClient:RequestState()

task.spawn(function()
	while isRunning do
		task.wait(math.random(16, 28))
		if not isRunning then
			return
		end

		signalBus:Fire("MenuLightningStrike", {
			Magnitude = 0.2,
			Duration = 0.33,
		})
		menuView:TriggerLightningFlash()
	end
end)

local function cleanup()
	if not isRunning then
		return
	end

	isRunning = false

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)

	characterPreview:Destroy()
	partyClient:Destroy()
	menuController:Destroy()
	menuView:Destroy()
end

script.Destroying:Connect(cleanup)
