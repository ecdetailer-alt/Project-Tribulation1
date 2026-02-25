local TweenService = game:GetService("TweenService")

local MenuTheme = require(script.Parent:WaitForChild("MenuTheme"))

local MenuView = {}
MenuView.__index = MenuView

local function create(instanceClass, properties, parent)
	local instance = Instance.new(instanceClass)
	for key, value in pairs(properties) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function stylePanel(frame)
	frame.BackgroundColor3 = MenuTheme.Colors.Panel
	frame.BackgroundTransparency = 0.06
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, frame)
	create("UIStroke", {
		Color = MenuTheme.Colors.Outline,
		Thickness = 1,
		Transparency = 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, frame)
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
		BackgroundColor3 = MenuTheme.Colors.Panel,
	}, panel)
	stylePanel(card)

	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 12),
		Size = UDim2.new(1, -36, 0, 28),
		Font = MenuTheme.Typography.Subtitle,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = MenuTheme.Colors.PrimaryText,
		Text = titleText,
	}, card)

	return panel, card
end

local function createButton(parent, text)
	local button = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = MenuTheme.Colors.Button,
		AutoButtonColor = false,
		Font = MenuTheme.Typography.Button,
		Text = text,
		TextSize = 18,
		TextColor3 = MenuTheme.Colors.PrimaryText,
	}, parent)

	create("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
	create("UIStroke", {
		Color = MenuTheme.Colors.Outline,
		Thickness = 1,
		Transparency = 0.35,
	}, button)

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = MenuTheme.Colors.ButtonHover
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = MenuTheme.Colors.Button
	end)

	return button
end

function MenuView.new(playerGui, actions)
	local self = setmetatable({}, MenuView)
	self._connections = {}
	self._buttons = {}
	self._panels = {}
	self._animationTime = 0
	self._partyWidgets = nil
	self._characterViewport = nil

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
		BackgroundColor3 = MenuTheme.Colors.BackgroundBottom,
		BorderSizePixel = 0,
	}, gui)
	self.Root = root

	self._backgroundGradient = create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, MenuTheme.Colors.BackgroundTop),
			ColorSequenceKeypoint.new(1, MenuTheme.Colors.BackgroundBottom),
		}),
		Rotation = 235,
	}, root)

	self._fogFrame = create("Frame", {
		Name = "Fog",
		BackgroundColor3 = MenuTheme.Colors.Fog,
		BackgroundTransparency = 0.86,
		Size = UDim2.new(1.5, 0, 1.5, 0),
		Position = UDim2.fromScale(-0.2, -0.25),
		BorderSizePixel = 0,
	}, root)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, self._fogFrame)

	self._flashFrame = create("Frame", {
		Name = "FlashFrame",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 12,
	}, root)

	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(72, 42),
		Size = UDim2.fromOffset(460, 62),
		Font = MenuTheme.Typography.Title,
		Text = "TRIBULATION",
		TextColor3 = MenuTheme.Colors.PrimaryText,
		TextSize = 54,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, root)

	create("TextLabel", {
		Name = "Subtitle",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(76, 102),
		Size = UDim2.fromOffset(560, 28),
		Font = MenuTheme.Typography.Subtitle,
		Text = "Dark Sci-Fi RPG",
		TextColor3 = MenuTheme.Colors.SecondaryText,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, root)

	local actionPanel = create("Frame", {
		Name = "ActionPanel",
		Position = UDim2.fromOffset(72, 152),
		Size = UDim2.fromOffset(330, 420),
		BackgroundColor3 = MenuTheme.Colors.Panel,
	}, root)
	stylePanel(actionPanel)

	local actionLayout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, actionPanel)

	create("UIPadding", {
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	}, actionPanel)

	for index, action in ipairs(actions) do
		local button = createButton(actionPanel, action.Label)
		button.LayoutOrder = index
		self._buttons[action.Id] = button
	end

	local panelContainer = create("Frame", {
		Name = "PanelContainer",
		Position = UDim2.new(0, 430, 0, 152),
		Size = UDim2.new(1, -500, 0, 420),
		BackgroundTransparency = 1,
	}, root)

	local partyPanel, partyCard = createPanel(panelContainer, "Party", "Party")
	local partyDescription = create("TextLabel", {
		Name = "Description",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 48),
		Size = UDim2.new(1, -36, 0, 44),
		Font = MenuTheme.Typography.Body,
		Text = "Create and manage squads for menu-to-world transition.",
		TextColor3 = MenuTheme.Colors.SecondaryText,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
	}, partyCard)
	partyDescription.RichText = false

	local createPartyButton = createButton(partyCard, "Create Party")
	createPartyButton.Position = UDim2.fromOffset(18, 96)
	createPartyButton.Size = UDim2.fromOffset(182, 44)
	createPartyButton.AnchorPoint = Vector2.zero

	local refreshPartyButton = createButton(partyCard, "Refresh")
	refreshPartyButton.Position = UDim2.fromOffset(208, 96)
	refreshPartyButton.Size = UDim2.fromOffset(130, 44)
	refreshPartyButton.AnchorPoint = Vector2.zero

	local inviteBox = create("TextBox", {
		Name = "InviteUserIdBox",
		Position = UDim2.fromOffset(18, 150),
		Size = UDim2.new(1, -176, 0, 40),
		BackgroundColor3 = MenuTheme.Colors.Button,
		TextColor3 = MenuTheme.Colors.PrimaryText,
		Font = MenuTheme.Typography.Body,
		TextSize = 16,
		ClearTextOnFocus = false,
		PlaceholderText = "Invite UserId",
		PlaceholderColor3 = MenuTheme.Colors.SecondaryText,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, partyCard)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, inviteBox)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, inviteBox)

	local inviteButton = createButton(partyCard, "Send Invite")
	inviteButton.Position = UDim2.new(1, -148, 0, 150)
	inviteButton.Size = UDim2.fromOffset(130, 40)

	local stateLabel = create("TextLabel", {
		Name = "StateLabel",
		Position = UDim2.fromOffset(18, 202),
		Size = UDim2.new(1, -36, 1, -220),
		BackgroundTransparency = 1,
		Font = MenuTheme.Typography.Body,
		Text = "Party state loading...",
		TextColor3 = MenuTheme.Colors.PrimaryText,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
	}, partyCard)

	self._partyWidgets = {
		CreatePartyButton = createPartyButton,
		RefreshPartyButton = refreshPartyButton,
		InviteUserIdBox = inviteBox,
		InviteButton = inviteButton,
		StateLabel = stateLabel,
	}

	local characterPanel, characterCard = createPanel(panelContainer, "CharacterCustomization", "Character Customization")
	local viewport = create("ViewportFrame", {
		Name = "CharacterViewport",
		Position = UDim2.fromOffset(18, 48),
		Size = UDim2.new(1, -36, 1, -96),
		BackgroundColor3 = MenuTheme.Colors.Button,
		BorderSizePixel = 0,
		Ambient = Color3.fromRGB(120, 120, 120),
		LightColor = Color3.fromRGB(235, 235, 235),
	}, characterCard)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, viewport)
	self._characterViewport = viewport

	create("TextLabel", {
		Name = "RotateHint",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 22, 1, -42),
		Size = UDim2.new(1, -44, 0, 24),
		Font = MenuTheme.Typography.Body,
		Text = "Drag to rotate",
		TextColor3 = MenuTheme.Colors.SecondaryText,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, characterCard)

	local settingsPanel, settingsCard = createPanel(panelContainer, "Settings", "Settings")
	create("TextLabel", {
		Name = "SettingsHint",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 48),
		Size = UDim2.new(1, -36, 0, 60),
		Font = MenuTheme.Typography.Body,
		Text = "Settings scaffold ready for graphics, audio, and controls options.",
		TextColor3 = MenuTheme.Colors.SecondaryText,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, settingsCard)

	self._panels.Party = partyPanel
	self._panels.CharacterCustomization = characterPanel
	self._panels.Settings = settingsPanel

	self._statusLabel = create("TextLabel", {
		Name = "StatusLabel",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 72, 1, -34),
		Size = UDim2.new(1, -144, 0, 24),
		Font = MenuTheme.Typography.Body,
		Text = "Menu booted.",
		TextColor3 = MenuTheme.Colors.StatusGood,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, root)

	actionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		actionPanel.Size = UDim2.fromOffset(330, math.max(220, actionLayout.AbsoluteContentSize.Y + 28))
	end)

	return self
end

function MenuView:BindActions(handler)
	for actionId, button in pairs(self._buttons) do
		table.insert(self._connections, button.Activated:Connect(function()
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

function MenuView:SetPanel(panelId)
	for id, panel in pairs(self._panels) do
		panel.Visible = (panelId ~= nil and id == panelId)
	end
end

function MenuView:GetCharacterViewport()
	return self._characterViewport
end

function MenuView:SetStatus(text, isError)
	self._statusLabel.Text = text or ""
	self._statusLabel.TextColor3 = isError and MenuTheme.Colors.StatusError or MenuTheme.Colors.StatusGood
end

function MenuView:SetPartyState(state)
	if not self._partyWidgets then
		return
	end

	local lines = {}
	table.insert(lines, string.format("Max party size: %d", state.MaxPartySize or 4))
	table.insert(lines, "")

	if state.OwnParty then
		table.insert(lines, string.format("Your party (%s)", state.OwnParty.Id))
		table.insert(lines, string.format("Leader: %s", state.OwnParty.LeaderName))
		for _, member in ipairs(state.OwnParty.Members) do
			table.insert(lines, string.format("- %s (%d)", member.Name, member.UserId))
		end
	else
		table.insert(lines, "You are not currently in a party.")
	end

	table.insert(lines, "")
	table.insert(lines, "Public parties:")
	for _, party in ipairs(state.PublicParties or {}) do
		table.insert(lines, string.format("- %s | %s (%d/%d)", party.Id, party.LeaderName, party.MemberCount, party.MaxSize))
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
	self._flashFrame.Visible = true
	self._flashFrame.BackgroundTransparency = 0.9

	local tween = TweenService:Create(self._flashFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		self._flashFrame.Visible = false
	end)
end

function MenuView:Step(dt)
	self._animationTime += dt
	self._backgroundGradient.Rotation = (235 + self._animationTime * 2.5) % 360
	self._fogFrame.Position = UDim2.new(
		-0.22 + math.sin(self._animationTime * 0.09) * 0.06,
		0,
		-0.25 + math.cos(self._animationTime * 0.07) * 0.05,
		0
	)
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
