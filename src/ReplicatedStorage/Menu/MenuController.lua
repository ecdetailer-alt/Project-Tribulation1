local MenuActions = require(script.Parent:WaitForChild("MenuActions"))
local MenuConfig = require(script.Parent:WaitForChild("MenuConfig"))
local TeleportClient = require(script.Parent:WaitForChild("TeleportClient"))

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
	return self
end

function MenuController:Start()
	table.insert(self._connections, self._signalBus:Connect("MenuActionRequested", function(payload)
		self:_handleMenuAction(payload)
	end))

	self._signalBus:Fire("MenuSceneSelected", {
		SceneId = MenuConfig.Cinematics.DefaultScene,
	})

	self._signalBus:Fire("MenuStatus", {
		Text = "Tribulation menu online.",
		IsError = false,
	})
end

function MenuController:_handleMenuAction(payload)
	local actionId = payload and payload.ActionId
	if type(actionId) ~= "string" then
		return
	end

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

function MenuController:_handleTeleport(action)
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

	self._signalBus:Fire("MenuPanelChanged", {
		PanelId = self._activePanel,
	})

	if self._activePanel == "Party" then
		self._signalBus:Fire("PartyRefreshRequested")
	end
end

function MenuController:Destroy()
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
