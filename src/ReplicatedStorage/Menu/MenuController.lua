local MenuActions = require(script.Parent:WaitForChild("MenuActions"))
local MenuConfig = require(script.Parent:WaitForChild("MenuConfig"))
local TeleportClient = require(script.Parent:WaitForChild("TeleportClient"))
local RunService = game:GetService("RunService")

local MenuController = {}
MenuController.__index = MenuController

local actionById = {}
for _, action in ipairs(MenuActions) do
	actionById[action.Id] = action
end

function MenuController.new(signalBus)
	local self = setmetatable({}, MenuController)
	self._signalBus = signalBus
	self._teleportClient = TeleportClient.new(signalBus)
	self._activePanel = nil
	self._connections = {}
	self._currentScene = MenuConfig.Cinematics.DefaultScene
	self._idleSeconds = 0
	self._hasShiftedToIdleScene = false
	self._isTransitioningPlay = false
	return self
end

function MenuController:Start()
	table.insert(self._connections, self._signalBus:Connect("MenuActionRequested", function(payload)
		self:_handleMenuAction(payload)
	end))

	table.insert(self._connections, self._signalBus:Connect("MenuActionHovered", function(payload)
		self:_handleMenuHover(payload)
	end))

	table.insert(self._connections, RunService.Heartbeat:Connect(function(dt)
		self:_updateIdle(dt)
	end))

	self:_setScene(MenuConfig.Cinematics.DefaultScene)

	self._signalBus:Fire("MenuStatus", {
		Text = "Tribulation menu online.",
		IsError = false,
	})
end

function MenuController:_setScene(sceneId)
	if type(sceneId) ~= "string" then
		return
	end

	self._currentScene = sceneId
	self._signalBus:Fire("MenuSceneSelected", {
		SceneId = sceneId,
	})
end

function MenuController:_registerInteraction()
	self._idleSeconds = 0
	self._hasShiftedToIdleScene = false
end

function MenuController:_updateIdle(dt)
	if self._isTransitioningPlay then
		return
	end

	self._idleSeconds += dt

	if self._hasShiftedToIdleScene then
		return
	end

	if self._idleSeconds < MenuConfig.Cinematics.IdleShiftSeconds then
		return
	end

	self._hasShiftedToIdleScene = true
	self:_setScene(MenuConfig.Cinematics.IdleShiftScene)
end

function MenuController:_handleMenuAction(payload)
	local actionId = payload and payload.ActionId
	if type(actionId) ~= "string" then
		return
	end

	self:_registerInteraction()

	local action = actionById[actionId]
	if not action then
		self._signalBus:Fire("MenuStatus", {
			Text = string.format("Unknown menu action: %s", actionId),
			IsError = true,
		})
		return
	end

	if action.Kind == "Teleport" then
		self:_handleTeleport(action)
		return
	end

	if action.Kind == "Panel" then
		self:_togglePanel(action.PanelId)
		return
	end
end

function MenuController:_handleMenuHover(payload)
	local actionId = payload and payload.ActionId
	if type(actionId) ~= "string" then
		return
	end

	self:_registerInteraction()

	if actionId == "ContinueCampaign" or actionId == "Party" then
		self:_setScene("BlackFogHorizon")
		return
	end

	if actionId == "OpenWorld" or actionId == "Character" then
		self:_setScene("FirePit")
		return
	end
end

function MenuController:_handleTeleport(action)
	if action.Id == "ContinueCampaign" then
		self._isTransitioningPlay = true
		self:_setScene(MenuConfig.Cinematics.PlayClickScene)
		self._signalBus:Fire("MenuLightningStrike", {
			Magnitude = 0.35,
			Duration = 0.45,
		})
		self._signalBus:Fire("MenuStatus", {
			Text = "Brace for breach impact...",
			IsError = false,
		})

		task.delay(MenuConfig.Cinematics.SceneCPreTeleportDelay, function()
			if not self._teleportClient then
				self._isTransitioningPlay = false
				return
			end

			local ok, errorMessage = self._teleportClient:Request(action.Destination)
			if ok then
				self._signalBus:Fire("MenuStatus", {
					Text = string.format("Preparing %s...", action.Label),
					IsError = false,
				})
				task.delay(3, function()
					self._isTransitioningPlay = false
				end)
				return
			end

			self._isTransitioningPlay = false
			self._signalBus:Fire("MenuStatus", {
				Text = errorMessage or "Teleport request could not be sent.",
				IsError = true,
			})
		end)
		return
	end

	local ok, errorMessage = self._teleportClient:Request(action.Destination)
	if ok then
		self._signalBus:Fire("MenuStatus", {
			Text = string.format("Preparing %s...", action.Label),
			IsError = false,
		})
		return
	end

	self._signalBus:Fire("MenuStatus", {
		Text = errorMessage or "Teleport request could not be sent.",
		IsError = true,
	})
end

function MenuController:_togglePanel(panelId)
	if self._activePanel == panelId then
		self._activePanel = nil
	else
		self._activePanel = panelId
	end

	if self._activePanel == "Party" then
		self:_setScene("BlackFogHorizon")
	end

	self._signalBus:Fire("MenuPanelChanged", {
		PanelId = self._activePanel,
	})

	if self._activePanel == "Party" then
		self._signalBus:Fire("PartyRefreshRequested")
	end
end

function MenuController:Destroy()
	self._isTransitioningPlay = false

	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	if self._teleportClient then
		self._teleportClient:Destroy()
		self._teleportClient = nil
	end
end

return MenuController
