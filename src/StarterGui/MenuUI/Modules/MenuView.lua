local TweenService = game:GetService("TweenService")

local MenuTheme = require(script.Parent:WaitForChild("MenuTheme"))

local MenuView = {}
MenuView.__index = MenuView

local function create(className, properties, parent)
	local instance = Instance.new(className)
	for key, value in pairs(properties) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function styleGlass(frame)
	frame.BackgroundColor3 = MenuTheme.Colors.Glass
	frame.BackgroundTransparency = 0.2
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, frame)
	create("UIStroke", {
		Color = MenuTheme.Colors.Outline,
		Thickness = 1,
		Transparency = 0.25,
	}, frame)
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, MenuTheme.Colors.GlassTop),
			ColorSequenceKeypoint.new(1, MenuTheme.Colors.GlassBottom),
		}),
		Rotation = 90,
	}, frame)
end

local function createButton(parent, text)
	local button = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = MenuTheme.Colors.Button,
		AutoButtonColor = false,
		Font = MenuTheme.Typography.Button,
		Text = text,
		TextColor3 = MenuTheme.Colors.PrimaryText,
		TextSize = 17,
	}, parent)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
	create("UIStroke", {
		Color = MenuTheme.Colors.Outline,
		Thickness = 1,
		Transparency = 0.45,
	}, button)
	return button
end

local function createPanel(parent, name, titleText)
	local panel = create("Frame", {
		Name = name .. "Panel",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
	}, parent)

	local card = create("Frame", {
		Name = "Card",
		Size = UDim2.new(1, 0, 1, 0),
	}, panel)
	styleGlass(card)

	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 24),
		Font = MenuTheme.Typography.Subtitle,
		TextSize = 18,
		Text = titleText,
		TextColor3 = MenuTheme.Colors.PrimaryText,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	return panel, card
end

function MenuView.new(playerGui, actions)
	local self = setmetatable({}, MenuView)
	self._connections = {}
	self._buttons = {}
	self._panels = {}
	self._scanlines = {}
	self._animationTime = 0
	self._partyWidgets = nil
	self._settingsWidgets = nil
	self._characterViewport = nil
	self._statusLabel = nil
	self._sceneLabel = nil
	self._flashFrame = nil
	self._glassPanel = nil

	local gui = create("ScreenGui", {
		Name = "TribulationMenu",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)
	self.Gui = gui

	local root = create("Frame", {
		Name = "Root",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, gui)
	self.Root = root

	local vignette = create("Frame", {
		Name = "Vignette",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = MenuTheme.Colors.Vignette,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
	}, root)

	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, MenuTheme.Colors.Vignette),
			ColorSequenceKeypoint.new(0.5, MenuTheme.Colors.Vignette),
			ColorSequenceKeypoint.new(1, MenuTheme.Colors.Vignette),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.4, 0.7),
			NumberSequenceKeypoint.new(1, 0.15),
		}),
		Rotation = 90,
	}, vignette)

	local glassPanel = create("Frame", {
		Name = "GlassPanel",
		Position = UDim2.fromScale(0.04, 0.1),
		Size = UDim2.fromScale(0.32, 0.8),
	}, root)
	self._glassPanel = glassPanel
	styleGlass(glassPanel)
	create("UISizeConstraint", {
		MinSize = Vector2.new(280, 560),
		MaxSize = Vector2.new(560, 920),
	}, glassPanel)

	local scanlineOverlay = create("Frame", {
		Name = "ScanlineOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 5,
	}, glassPanel)

	for index = 1, 56 do
		local line = create("Frame", {
			Name = string.format("Line_%d", index),
			Position = UDim2.new(0, 0, 0, index * 9),
			Size = UDim2.new(1, 0, 0, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = MenuTheme.Colors.Scanline,
			BackgroundTransparency = 0.94,
			ZIndex = 5,
		}, scanlineOverlay)
		table.insert(self._scanlines, line)
	end

	local titleShadowBlue = create("TextLabel", {
		Name = "TitleShadowBlue",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(25, 17),
		Size = UDim2.new(1, -50, 0, 46),
		Font = MenuTheme.Typography.Title,
		Text = "TRIBULATION",
		TextColor3 = Color3.fromRGB(93, 133, 255),
		TextTransparency = 0.9,
		TextSize = 41,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, glassPanel)

	local titleShadowRed = create("TextLabel", {
		Name = "TitleShadowRed",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(23, 15),
		Size = UDim2.new(1, -50, 0, 46),
		Font = MenuTheme.Typography.Title,
		Text = "TRIBULATION",
		TextColor3 = Color3.fromRGB(255, 106, 106),
		TextTransparency = 0.91,
		TextSize = 41,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, glassPanel)

	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(24, 16),
		Size = UDim2.new(1, -50, 0, 46),
		Font = MenuTheme.Typography.Title,
		Text = "TRIBULATION",
		TextColor3 = MenuTheme.Colors.PrimaryText,
		TextSize = 41,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	}, glassPanel)

	create("TextLabel", {
		Name = "Subtitle",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(24, 56),
		Size = UDim2.new(1, -50, 0, 20),
		Font = MenuTheme.Typography.Subtitle,
		Text = "The Breachline",
		TextColor3 = MenuTheme.Colors.SecondaryText,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, glassPanel)

	self._sceneLabel = create("TextLabel", {
		Name = "SceneLabel",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(24, 78),
		Size = UDim2.new(1, -50, 0, 18),
		Font = MenuTheme.Typography.Body,
		Text = "Scene: Fire Pit",
		TextColor3 = MenuTheme.Colors.ButtonAccent,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, glassPanel)

	local buttonContainer = create("Frame", {
		Name = "ButtonContainer",
		Position = UDim2.fromOffset(20, 106),
		Size = UDim2.new(1, -40, 0, 252),
		BackgroundTransparency = 1,
	}, glassPanel)

	local buttonLayout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 7),
	}, buttonContainer)

	for index, action in ipairs(actions) do
		local button = createButton(buttonContainer, action.Label)
		button.LayoutOrder = index
		self._buttons[action.Id] = button
	end

	local detailHost = create("Frame", {
		Name = "DetailHost",
		Position = UDim2.fromOffset(20, 336),
		Size = UDim2.new(1, -40, 1, -348),
		BackgroundTransparency = 1,
	}, glassPanel)

	local partyPanel, partyCard = createPanel(detailHost, "Party", "Party")

	local partyDescription = create("TextLabel", {
		Name = "Description",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 32),
		Size = UDim2.new(1, -28, 0, 30),
		Font = MenuTheme.Typography.Body,
		Text = "Squad up before crossing the breachline.",
		TextColor3 = MenuTheme.Colors.SecondaryText,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, partyCard)
	partyDescription.RichText = false

	local createPartyButton = createButton(partyCard, "Create Party")
	createPartyButton.Position = UDim2.fromOffset(14, 64)
	createPartyButton.Size = UDim2.fromOffset(150, 32)

	local refreshPartyButton = createButton(partyCard, "Refresh")
	refreshPartyButton.Position = UDim2.new(1, -114, 0, 64)
	refreshPartyButton.Size = UDim2.fromOffset(100, 32)

	local inviteBox = create("TextBox", {
		Name = "InviteUserIdBox",
		Position = UDim2.fromOffset(14, 100),
		Size = UDim2.new(1, -126, 0, 30),
		BackgroundColor3 = MenuTheme.Colors.Button,
		TextColor3 = MenuTheme.Colors.PrimaryText,
		PlaceholderText = "Invite UserId",
		PlaceholderColor3 = MenuTheme.Colors.SecondaryText,
		TextSize = 14,
		Font = MenuTheme.Typography.Body,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, partyCard)
	create("UICorner", { CornerRadius = UDim.new(0, 7) }, inviteBox)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	}, inviteBox)

	local inviteButton = createButton(partyCard, "Invite")
	inviteButton.Position = UDim2.new(1, -106, 0, 100)
	inviteButton.Size = UDim2.fromOffset(92, 30)

	local stateLabel = create("TextLabel", {
		Name = "StateLabel",
		Position = UDim2.fromOffset(14, 136),
		Size = UDim2.new(1, -28, 1, -148),
		BackgroundTransparency = 1,
		Font = MenuTheme.Typography.Body,
		Text = "Party state loading...",
		TextColor3 = MenuTheme.Colors.PrimaryText,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, partyCard)

	self._partyWidgets = {
		CreatePartyButton = createPartyButton,
		RefreshPartyButton = refreshPartyButton,
		InviteUserIdBox = inviteBox,
		InviteButton = inviteButton,
		StateLabel = stateLabel,
	}

	local characterPanel, characterCard = createPanel(detailHost, "Character", "Character")
	local viewport = create("ViewportFrame", {
		Name = "CharacterViewport",
		Position = UDim2.fromOffset(14, 34),
		Size = UDim2.new(1, -28, 1, -64),
		BackgroundColor3 = MenuTheme.Colors.Button,
		BorderSizePixel = 0,
		Ambient = Color3.fromRGB(116, 120, 122),
		LightColor = Color3.fromRGB(229, 233, 236),
		Active = true,
	}, characterCard)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, viewport)
	self._characterViewport = viewport

	create("TextLabel", {
		Name = "RotateHint",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 1, -24),
		Size = UDim2.new(1, -32, 0, 18),
		Font = MenuTheme.Typography.Body,
		Text = "Drag to rotate preview",
		TextColor3 = MenuTheme.Colors.SecondaryText,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, characterCard)

	local settingsPanel, settingsCard = createPanel(detailHost, "Settings", "Settings")
	local settingsInfo = create("TextLabel", {
		Name = "SettingsInfo",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 36),
		Size = UDim2.new(1, -28, 0, 46),
		Font = MenuTheme.Typography.Body,
		Text = "Control how menu interactions affect scene switching.",
		TextColor3 = MenuTheme.Colors.SecondaryText,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, settingsCard)
	settingsInfo.RichText = false

	create("TextLabel", {
		Name = "HoverSceneSwitchingLabel",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 82),
		Size = UDim2.new(1, -150, 0, 22),
		Font = MenuTheme.Typography.Body,
		Text = "Hover Scene Switching",
		TextColor3 = MenuTheme.Colors.PrimaryText,
		TextSize = 14,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, settingsCard)

	local hoverToggleButton = createButton(settingsCard, "ON")
	hoverToggleButton.Name = "HoverSceneSwitchingToggle"
	hoverToggleButton.Position = UDim2.new(1, -116, 0, 78)
	hoverToggleButton.Size = UDim2.fromOffset(102, 28)
	hoverToggleButton.TextSize = 13

	local settingsHint = create("TextLabel", {
		Name = "SettingsHint",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 112),
		Size = UDim2.new(1, -28, 0, 46),
		Font = MenuTheme.Typography.Body,
		Text = "When enabled, hovering main buttons previews scene mood.",
		TextColor3 = MenuTheme.Colors.SecondaryText,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, settingsCard)

	self._settingsWidgets = {
		HoverSceneSwitchingToggle = hoverToggleButton,
		HintLabel = settingsHint,
	}

	self._panels.Party = partyPanel
	self._panels.Character = characterPanel
	self._panels.Settings = settingsPanel

	self._statusLabel = create("TextLabel", {
		Name = "Status",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(24, 1),
		Size = UDim2.new(1, -50, 0, 20),
		AnchorPoint = Vector2.new(0, 1),
		Font = MenuTheme.Typography.Body,
		Text = "Menu ready.",
		TextColor3 = MenuTheme.Colors.StatusGood,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, glassPanel)
	self._statusLabel.Position = UDim2.new(0, 24, 1, -10)

	self._flashFrame = create("Frame", {
		Name = "FlashFrame",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, root)

	buttonLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		buttonContainer.Size = UDim2.new(1, -40, 0, buttonLayout.AbsoluteContentSize.Y + 2)
	end)

	local function buttonHover(button, hovering)
		local targetColor = hovering and MenuTheme.Colors.ButtonHover or MenuTheme.Colors.Button
		button.BackgroundColor3 = targetColor
		button.TextColor3 = hovering and MenuTheme.Colors.ButtonAccent or MenuTheme.Colors.PrimaryText
	end

	for _, button in pairs(self._buttons) do
		table.insert(self._connections, button.MouseEnter:Connect(function()
			buttonHover(button, true)
		end))
		table.insert(self._connections, button.MouseLeave:Connect(function()
			buttonHover(button, false)
		end))
	end

	return self
end

function MenuView:BindActions(handler)
	for actionId, button in pairs(self._buttons) do
		table.insert(self._connections, button.Activated:Connect(function()
			handler(actionId)
		end))
	end
end

function MenuView:BindActionHover(handler)
	for actionId, button in pairs(self._buttons) do
		table.insert(self._connections, button.MouseEnter:Connect(function()
			handler(actionId)
		end))
	end
end

function MenuView:BindPartyActions(handlers)
	local widgets = self._partyWidgets
	if not widgets then
		return
	end

	table.insert(self._connections, widgets.CreatePartyButton.Activated:Connect(function()
		if handlers.OnCreateParty then
			handlers.OnCreateParty()
		end
	end))

	table.insert(self._connections, widgets.RefreshPartyButton.Activated:Connect(function()
		if handlers.OnRefreshParty then
			handlers.OnRefreshParty()
		end
	end))

	table.insert(self._connections, widgets.InviteButton.Activated:Connect(function()
		local userId = tonumber(widgets.InviteUserIdBox.Text)
		if handlers.OnInviteUserId then
			handlers.OnInviteUserId(userId)
		end
	end))
end

function MenuView:BindSettingsActions(handlers)
	local widgets = self._settingsWidgets
	if not widgets then
		return
	end

	table.insert(self._connections, widgets.HoverSceneSwitchingToggle.Activated:Connect(function()
		if handlers.OnToggleHoverSceneSwitching then
			handlers.OnToggleHoverSceneSwitching()
		end
	end))
end

function MenuView:SetPanel(panelId)
	for id, panel in pairs(self._panels) do
		panel.Visible = panelId == id
	end
end

function MenuView:GetCharacterViewport()
	return self._characterViewport
end

function MenuView:SetSceneName(sceneDisplayName)
	if self._sceneLabel then
		self._sceneLabel.Text = string.format("Scene: %s", sceneDisplayName or "Unknown")
	end
end

function MenuView:SetStatus(text, isError)
	if not self._statusLabel then
		return
	end

	self._statusLabel.Text = text or ""
	self._statusLabel.TextColor3 = isError and MenuTheme.Colors.Warning or MenuTheme.Colors.StatusGood
end

function MenuView:SetSettings(settings)
	local widgets = self._settingsWidgets
	if not widgets then
		return
	end

	local hoverEnabled = settings and settings.HoverSceneSwitching == true
	widgets.HoverSceneSwitchingToggle.Text = hoverEnabled and "ON" or "OFF"
	widgets.HoverSceneSwitchingToggle.BackgroundColor3 = hoverEnabled and MenuTheme.Colors.ButtonAccent or MenuTheme.Colors.Button
	widgets.HoverSceneSwitchingToggle.TextColor3 = hoverEnabled and Color3.fromRGB(13, 18, 23) or MenuTheme.Colors.PrimaryText
	widgets.HintLabel.Text = hoverEnabled
		and "When enabled, hovering main buttons previews scene mood."
		or "Hover scene changes are disabled. Scene changes only on idle/click actions."
end

function MenuView:SetPartyState(state)
	if not self._partyWidgets then
		return
	end

	local lines = {}
	table.insert(lines, string.format("Max party size: %d", state.MaxPartySize or 4))
	table.insert(lines, "")

	if state.OwnParty then
		table.insert(lines, string.format("Party: %s", state.OwnParty.Id))
		table.insert(lines, string.format("Leader: %s", state.OwnParty.LeaderName))
		for _, member in ipairs(state.OwnParty.Members) do
			table.insert(lines, string.format("- %s (%d)", member.Name, member.UserId))
		end
	else
		table.insert(lines, "You are not in a party.")
	end

	table.insert(lines, "")
	table.insert(lines, "Open parties:")
	for _, party in ipairs(state.PublicParties or {}) do
		table.insert(lines, string.format("- %s (%d/%d)", party.LeaderName, party.MemberCount, party.MaxSize))
	end

	if state.Info then
		table.insert(lines, "")
		table.insert(lines, string.format("Info: %s", state.Info))
	end

	if state.Error then
		table.insert(lines, string.format("Error: %s", state.Error))
	end

	self._partyWidgets.StateLabel.Text = table.concat(lines, "\n")
end

function MenuView:TriggerLightningFlash()
	if not self._flashFrame then
		return
	end

	self._flashFrame.Visible = true
	self._flashFrame.BackgroundTransparency = 0.92

	local tween = TweenService:Create(self._flashFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		if self._flashFrame then
			self._flashFrame.Visible = false
		end
	end)
end

function MenuView:Step(dt)
	self._animationTime += dt

	if self._glassPanel then
		self._glassPanel.BackgroundTransparency = 0.18 + math.sin(self._animationTime * 0.2) * 0.02
	end

	for index, line in ipairs(self._scanlines) do
		line.BackgroundTransparency = 0.93 + math.abs(math.sin(self._animationTime * 0.7 + index * 0.12)) * 0.05
	end
end

function MenuView:Destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	if self.Gui then
		self.Gui:Destroy()
		self.Gui = nil
	end
end

return MenuView
