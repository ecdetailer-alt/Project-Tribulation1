local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UIController = {}
UIController.__index = UIController

local function create(className, properties, parent)
	local instance = Instance.new(className)
	for key, value in pairs(properties) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function tween(instance, tweenInfo, properties)
	local animation = TweenService:Create(instance, tweenInfo, properties)
	animation:Play()
	return animation
end

local function addCorner(parent, radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius),
	}, parent)
end

function UIController.new(options)
	assert(type(options) == "table", "UIController requires an options table")
	assert(options.PlayerGui, "UIController requires PlayerGui")

	local self = setmetatable({}, UIController)
	self._playerGui = options.PlayerGui
	self._callbacks = {
		OnCampaign = options.OnCampaign,
		OnOpenWorld = options.OnOpenWorld,
		OnParty = options.OnParty,
		OnSettings = options.OnSettings,
	}
	self._connections = {}
	self._view = nil
	self._pickerOpen = false
	self._pickerAnimating = false
	self._pickerOpenPosition = UDim2.new(0, 412, 0.5, -130)
	self._pickerClosedPosition = self._pickerOpenPosition + UDim2.fromOffset(26, 0)
	return self
end

function UIController:_buildMainButton(parent, id, text, index)
	local yOffset = (index - 1) * 68
	local basePosition = UDim2.new(0, 0, 0, yOffset)

	local button = create("TextButton", {
		Name = id,
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(13, 16, 21),
		BackgroundTransparency = 0.16,
		BorderSizePixel = 0,
		Position = basePosition,
		Size = UDim2.new(1, 0, 0, 54),
		Font = Enum.Font.GothamSemibold,
		Text = text,
		TextColor3 = Color3.fromRGB(230, 236, 244),
		TextSize = 26,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 20,
	}, parent)

	create("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
	}, button)

	addCorner(button, 8)

	local stroke = create("UIStroke", {
		Color = Color3.fromRGB(96, 105, 121),
		Thickness = 1,
		Transparency = 0.56,
	}, button)

	local underline = create("Frame", {
		Name = "Underline",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -3),
		Size = UDim2.new(0, 0, 0, 2),
		BackgroundColor3 = Color3.fromRGB(190, 196, 206),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		ZIndex = 21,
	}, button)

	local function setHovered(isHovered)
		if isHovered then
			tween(
				button,
				TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = basePosition + UDim2.fromOffset(6, 0),
					BackgroundTransparency = 0.05,
					TextColor3 = Color3.fromRGB(250, 252, 255),
				}
			)
			tween(
				stroke,
				TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Transparency = 0.28,
				}
			)
			tween(
				underline,
				TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = UDim2.new(0, 120, 0, 2),
				}
			)
		else
			tween(
				button,
				TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = basePosition,
					BackgroundTransparency = 0.16,
					TextColor3 = Color3.fromRGB(230, 236, 244),
				}
			)
			tween(
				stroke,
				TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Transparency = 0.56,
				}
			)
			tween(
				underline,
				TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = UDim2.new(0, 0, 0, 2),
				}
			)
		end
	end

	table.insert(self._connections, button.MouseEnter:Connect(function()
		setHovered(true)
	end))

	table.insert(self._connections, button.MouseLeave:Connect(function()
		setHovered(false)
	end))

	return button
end

function UIController:_buildModeButton(parent, id, text, order)
	local button = create("TextButton", {
		Name = id,
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(17, 20, 26),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 18, 0, 58 + ((order - 1) * 48)),
		Size = UDim2.new(1, -36, 0, 40),
		Font = Enum.Font.Gotham,
		Text = text,
		TextColor3 = Color3.fromRGB(231, 236, 244),
		TextSize = 20,
		ZIndex = 43,
	}, parent)

	addCorner(button, 6)

	local stroke = create("UIStroke", {
		Color = Color3.fromRGB(89, 98, 114),
		Thickness = 1,
		Transparency = 0.54,
	}, button)

	table.insert(self._connections, button.MouseEnter:Connect(function()
		tween(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.05,
			TextColor3 = Color3.fromRGB(252, 252, 255),
		})
		tween(stroke, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 0.26,
		})
	end))

	table.insert(self._connections, button.MouseLeave:Connect(function()
		tween(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.18,
			TextColor3 = Color3.fromRGB(231, 236, 244),
		})
		tween(stroke, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 0.54,
		})
	end))

	return button, stroke
end

function UIController:_buildView()
	local existing = self._playerGui:FindFirstChild("TribulationMenuUI")
	if existing and existing:IsA("ScreenGui") then
		existing:Destroy()
	end

	local screenGui = create("ScreenGui", {
		Name = "TribulationMenuUI",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 95,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, self._playerGui)

	local root = create("Frame", {
		Name = "Root",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, screenGui)

	local leftShade = create("Frame", {
		Name = "LeftShade",
		BackgroundColor3 = Color3.fromRGB(3, 4, 7),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Size = UDim2.new(0.44, 0, 1, 0),
		ZIndex = 10,
	}, root)

	create("UIGradient", {
		Rotation = 0,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.22),
			NumberSequenceKeypoint.new(0.8, 0.7),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, leftShade)

	local title = create("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 42),
		Size = UDim2.new(0, 760, 0, 54),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "PROJECT TRIBULATION",
		TextColor3 = Color3.fromRGB(245, 248, 252),
		TextSize = 46,
		ZIndex = 30,
	}, root)

	title.TextTransparency = 1
	tween(title, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	})

	local menuColumn = create("Frame", {
		Name = "MenuColumn",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 68, 0.5, -106),
		Size = UDim2.new(0, 292, 0, 222),
		ZIndex = 20,
	}, root)

	local playButton = self:_buildMainButton(menuColumn, "Play", "Play", 1)
	local partyButton = self:_buildMainButton(menuColumn, "Party", "Party", 2)
	local settingsButton = self:_buildMainButton(menuColumn, "Settings", "Settings", 3)

	local statusLabel = create("TextLabel", {
		Name = "Status",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 68, 1, -42),
		Size = UDim2.new(0, 440, 0, 24),
		Font = Enum.Font.Gotham,
		Text = "",
		TextColor3 = Color3.fromRGB(201, 208, 218),
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 0.06,
		ZIndex = 30,
	}, root)

	local modePanel = create("Frame", {
		Name = "ModePanel",
		BackgroundColor3 = Color3.fromRGB(9, 11, 15),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = self._pickerClosedPosition,
		Size = UDim2.new(0, 268, 0, 260),
		Visible = false,
		ZIndex = 40,
	}, root)

	addCorner(modePanel, 10)

	local modePanelStroke = create("UIStroke", {
		Color = Color3.fromRGB(96, 102, 112),
		Thickness = 1,
		Transparency = 1,
	}, modePanel)

	local modeTitle = create("TextLabel", {
		Name = "ModeTitle",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 14),
		Size = UDim2.new(1, -36, 0, 28),
		Font = Enum.Font.GothamSemibold,
		Text = "Select Mode",
		TextColor3 = Color3.fromRGB(236, 241, 248),
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 1,
		ZIndex = 43,
	}, modePanel)

	local campaignButton, campaignStroke = self:_buildModeButton(modePanel, "Campaign", "Campaign", 1)
	local openWorldButton, openWorldStroke = self:_buildModeButton(modePanel, "OpenWorld", "Open World", 2)
	local closeButton, closeStroke = self:_buildModeButton(modePanel, "Close", "Back", 3)

	self._view = {
		ScreenGui = screenGui,
		StatusLabel = statusLabel,
		PlayButton = playButton,
		PartyButton = partyButton,
		SettingsButton = settingsButton,
		ModePanel = modePanel,
		ModePanelStroke = modePanelStroke,
		ModeTitle = modeTitle,
		CampaignButton = campaignButton,
		OpenWorldButton = openWorldButton,
		CloseButton = closeButton,
		CampaignStroke = campaignStroke,
		OpenWorldStroke = openWorldStroke,
		CloseStroke = closeStroke,
	}
end

function UIController:_setPickerState(alpha, position, visible)
	local view = self._view
	if not view then
		return
	end

	view.ModePanel.Visible = visible
	view.ModePanel.Position = position
	view.ModePanel.BackgroundTransparency = 0.14 + (0.86 * alpha)
	view.ModePanelStroke.Transparency = 0.48 + (0.52 * alpha)
	view.ModeTitle.TextTransparency = alpha

	local pickerButtons = {
		{ Button = view.CampaignButton, Stroke = view.CampaignStroke },
		{ Button = view.OpenWorldButton, Stroke = view.OpenWorldStroke },
		{ Button = view.CloseButton, Stroke = view.CloseStroke },
	}

	for _, entry in ipairs(pickerButtons) do
		entry.Button.BackgroundTransparency = 0.18 + (0.82 * alpha)
		entry.Button.TextTransparency = alpha
		entry.Stroke.Transparency = 0.54 + (0.46 * alpha)
	end
end

function UIController:OpenModePicker()
	if not self._view or self._pickerOpen or self._pickerAnimating then
		return
	end

	self._pickerAnimating = true
	self._pickerOpen = true
	self:_setPickerState(1, self._pickerClosedPosition, true)

	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local proxy = Instance.new("NumberValue")
	proxy.Value = 1

	local connection
	connection = proxy:GetPropertyChangedSignal("Value"):Connect(function()
		local alpha = math.clamp(proxy.Value, 0, 1)
		local xOffset = 26 * alpha
		local position = self._pickerOpenPosition + UDim2.fromOffset(xOffset, 0)
		self:_setPickerState(alpha, position, true)
	end)

	local animation = tween(proxy, tweenInfo, { Value = 0 })
	animation.Completed:Connect(function()
		if connection then
			connection:Disconnect()
		end
		proxy:Destroy()
		self._pickerAnimating = false
	end)
end

function UIController:CloseModePicker()
	if not self._view or not self._pickerOpen or self._pickerAnimating then
		return
	end

	self._pickerAnimating = true
	self._pickerOpen = false

	local tweenInfo = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local proxy = Instance.new("NumberValue")
	proxy.Value = 0

	local connection
	connection = proxy:GetPropertyChangedSignal("Value"):Connect(function()
		local alpha = math.clamp(proxy.Value, 0, 1)
		local xOffset = 26 * alpha
		local position = self._pickerOpenPosition + UDim2.fromOffset(xOffset, 0)
		self:_setPickerState(alpha, position, true)
	end)

	local animation = tween(proxy, tweenInfo, { Value = 1 })
	animation.Completed:Connect(function()
		if connection then
			connection:Disconnect()
		end
		proxy:Destroy()
		self._pickerAnimating = false
		if self._view then
			self._view.ModePanel.Visible = false
		end
	end)
end

function UIController:SetStatus(text, isError)
	local label = self._view and self._view.StatusLabel
	if not label then
		return
	end

	label.Text = text or ""
	label.TextColor3 = isError and Color3.fromRGB(255, 148, 148) or Color3.fromRGB(201, 208, 218)
end

function UIController:Start()
	self:_buildView()
	local view = self._view

	table.insert(self._connections, view.PlayButton.Activated:Connect(function()
		self:OpenModePicker()
		self:SetStatus("Select a deployment mode.", false)
	end))

	table.insert(self._connections, view.PartyButton.Activated:Connect(function()
		if self._callbacks.OnParty then
			self._callbacks.OnParty()
		else
			self:SetStatus("Party menu is not wired yet.", false)
		end
	end))

	table.insert(self._connections, view.SettingsButton.Activated:Connect(function()
		if self._callbacks.OnSettings then
			self._callbacks.OnSettings()
		else
			self:SetStatus("Settings menu is not wired yet.", false)
		end
	end))

	table.insert(self._connections, view.CampaignButton.Activated:Connect(function()
		if self._callbacks.OnCampaign then
			self._callbacks.OnCampaign()
		end
		self:CloseModePicker()
	end))

	table.insert(self._connections, view.OpenWorldButton.Activated:Connect(function()
		if self._callbacks.OnOpenWorld then
			self._callbacks.OnOpenWorld()
		end
		self:CloseModePicker()
	end))

	table.insert(self._connections, view.CloseButton.Activated:Connect(function()
		self:CloseModePicker()
	end))

	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end

		if input.KeyCode == Enum.KeyCode.Escape and self._pickerOpen then
			self:CloseModePicker()
		end
	end))
end

function UIController:Destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	self._pickerOpen = false
	self._pickerAnimating = false

	if self._view and self._view.ScreenGui then
		self._view.ScreenGui:Destroy()
	end

	self._view = nil
end

return UIController
