local RunService = game:GetService("RunService")

local MenuActions = require(script.Parent:WaitForChild("MenuActions"))
local MenuConfig = require(script.Parent:WaitForChild("MenuConfig"))
local MenuSignals = require(script.Parent:WaitForChild("MenuSignals"))

local MenuController = {}
MenuController.__index = MenuController

function MenuController.new(options)
	assert(type(options) == "table", "MenuController requires an options table")
	assert(options.PlayerGui, "MenuController requires PlayerGui")
	assert(options.MenuBuild, "MenuController requires MenuBuild module")
	assert(options.MenuAnim, "MenuController requires MenuAnim module")

	local self = setmetatable({}, MenuController)
	self._playerGui = options.PlayerGui
	self._menuBuild = options.MenuBuild
	self._menuAnim = options.MenuAnim
	self._signals = MenuSignals.getShared()
	self._connections = {}
	self._view = nil
	self._anim = nil
	self._hoverSceneSwitching = MenuConfig.Scenes.HoverSceneSwitchingDefault
	self._activeScene = nil
	self._lastInteractionTime = os.clock()
	self._idleSceneTriggered = false
	return self
end

function MenuController:Start()
	self._view = self._menuBuild.Build(self._playerGui, MenuConfig)
	self._anim = self._menuAnim.new(self._view, MenuConfig)

	self:SetStatus(MenuConfig.Footer.Left, false)
	self._view.StatusRight.Text = MenuConfig.Footer.Right

	local firstButton = self._view.ButtonOrder[1]
	if firstButton then
		self._anim:SetIndicator(firstButton, true)
	end

	self:RequestScene(MenuConfig.Scenes.Default, "boot")
	self:_bindButtons()
	self:_bindLoop()
	self._anim:PlayIntro()
end

function MenuController:_bindButtons()
	for _, buttonData in ipairs(self._view.ButtonOrder) do
		table.insert(self._connections, buttonData.Button.MouseEnter:Connect(function()
			self:_registerInteraction()
			self._anim:HoverIn(buttonData)

			if self._hoverSceneSwitching then
				local hoverScene = MenuConfig.Scenes.HoverSceneMap[buttonData.Id]
				if hoverScene then
					self:RequestScene(hoverScene, "hover")
				end
			end
		end))

		table.insert(self._connections, buttonData.Button.MouseLeave:Connect(function()
			self._anim:HoverOut(buttonData)
		end))

		table.insert(self._connections, buttonData.Button.Activated:Connect(function()
			self:_registerInteraction()
			self._anim:PlayClick(buttonData)
			MenuActions.Execute(buttonData.Id, self)
		end))
	end
end

function MenuController:_bindLoop()
	table.insert(self._connections, RunService.RenderStepped:Connect(function()
		self:_updateIdleShift()
	end))
end

function MenuController:_updateIdleShift()
	if self._idleSceneTriggered then
		return
	end

	if self._activeScene ~= MenuConfig.Scenes.Default then
		return
	end

	local idleSeconds = os.clock() - self._lastInteractionTime
	if idleSeconds < MenuConfig.Scenes.IdleAfterSeconds then
		return
	end

	self._idleSceneTriggered = true
	self:RequestScene(MenuConfig.Scenes.IdleShift, "idle")
end

function MenuController:_registerInteraction()
	self._lastInteractionTime = os.clock()
	self._idleSceneTriggered = false
end

function MenuController:SetStatus(text, isError)
	local label = self._view and self._view.StatusLeft
	if not label then
		return
	end

	label.Text = text
	label.TextColor3 = isError and Color3.fromRGB(255, 146, 146) or MenuConfig.Style.TextColor
end

function MenuController:RequestScene(sceneId, reason)
	if type(sceneId) ~= "string" or sceneId == "" then
		return
	end

	self._activeScene = sceneId
	self:Emit("MenuSceneRequest", {
		SceneId = sceneId,
		Reason = reason or "unknown",
	})
end

function MenuController:ToggleHoverSceneSwitching()
	self._hoverSceneSwitching = not self._hoverSceneSwitching
	self:Emit("HoverSceneSwitchingChanged", {
		Enabled = self._hoverSceneSwitching,
	})
	return self._hoverSceneSwitching
end

function MenuController:Emit(eventName, payload)
	self._signals:Fire(eventName, payload)
end

function MenuController:Destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	if self._anim then
		self._anim:Destroy()
		self._anim = nil
	end

	if self._menuBuild and self._view then
		self._menuBuild.Destroy(self._view)
		self._view = nil
	end
end

return MenuController
