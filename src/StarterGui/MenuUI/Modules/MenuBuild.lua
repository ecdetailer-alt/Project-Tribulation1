local MenuBuild = {}

local function create(className, properties, parent)
	local instance = Instance.new(className)
	for key, value in pairs(properties) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function addCorner(parent, radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius),
	}, parent)
end

local function createButton(navList, config, buttonConfig, index)
	local yOffset = (index - 1) * config.Layout.ButtonSpacing
	local basePosition = UDim2.new(0, 0, 0, yOffset)

	local button = create("TextButton", {
		Name = buttonConfig.Id,
		AutoButtonColor = false,
		BackgroundColor3 = config.Style.ButtonColor,
		BackgroundTransparency = config.Style.ButtonTransparency,
		BorderSizePixel = 0,
		Position = basePosition,
		Size = config.Layout.ButtonSize,
		Text = buttonConfig.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = config.Style.ButtonFont,
		TextSize = config.Style.ButtonSize,
		TextColor3 = config.Style.TextDimColor,
		TextTransparency = config.Style.TextDimTransparency,
		TextStrokeColor3 = config.Style.TextStrokeColor,
		TextStrokeTransparency = config.Style.TextStrokeTransparency,
		ZIndex = 24,
	}, navList)

	addCorner(button, 12)

	create("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 9),
	}, button)

	local stroke = create("UIStroke", {
		Thickness = 1,
		Color = config.Style.ButtonStrokeColor,
		Transparency = config.Style.ButtonStrokeTransparency,
	}, button)

	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 52, 78)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 18, 31)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(1, 0.2),
		}),
	}, button)

	local leftAccent = create("Frame", {
		Name = "LeftAccent",
		BackgroundColor3 = config.Style.AccentColor,
		BackgroundTransparency = 0.78,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 6, 0, 9),
		Size = UDim2.new(0, 3, 0, 38),
		ZIndex = 26,
	}, button)

	addCorner(leftAccent, 4)

	local detailLabel = create("TextLabel", {
		Name = "Detail",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 32),
		Size = UDim2.new(1, -26, 0, 18),
		Text = buttonConfig.Detail or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = config.Style.ButtonDetailFont,
		TextSize = config.Style.ButtonDetailSize,
		TextColor3 = config.Style.MutedTextColor,
		TextTransparency = 0.28,
		ZIndex = 26,
	}, button)

	local underline = create("Frame", {
		Name = "Underline",
		BackgroundColor3 = config.Style.AccentColor,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 16, 1, -3),
		Size = UDim2.new(0, 0, 0, 2),
		ZIndex = 26,
	}, button)

	local scale = create("UIScale", {
		Name = "Scale",
		Scale = 1,
	}, button)

	return {
		Id = buttonConfig.Id,
		Button = button,
		Stroke = stroke,
		DetailLabel = detailLabel,
		LeftAccent = leftAccent,
		Underline = underline,
		Scale = scale,
		BasePosition = basePosition,
		BaseBackgroundColor = config.Style.ButtonColor,
		HoverBackgroundColor = config.Style.ButtonHoverColor,
	}
end

function MenuBuild.Build(playerGui, config)
	for _, child in ipairs(playerGui:GetChildren()) do
		if child.Name == "MenuUI" and child:IsA("ScreenGui") then
			child:Destroy()
		end
	end

	local screenGui = create("ScreenGui", {
		Name = "MenuUI",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 40,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)

	local root = create("Frame", {
		Name = "Root",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, screenGui)

	local backdrop = create("Frame", {
		Name = "Backdrop",
		BackgroundColor3 = config.Style.OverlayColor,
		BackgroundTransparency = config.Style.OverlayTransparency,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
	}, root)

	create("UIGradient", {
		Rotation = 74,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 36, 61)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(7, 12, 24)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 7, 14)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.7, 0.2),
			NumberSequenceKeypoint.new(1, 0.05),
		}),
	}, backdrop)

	local sideGlow = create("Frame", {
		Name = "SideGlow",
		BackgroundColor3 = config.Style.AccentColor,
		BackgroundTransparency = 0.84,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.new(0.42, 0, 1, 0),
		ZIndex = 2,
	}, root)

	create("UIGradient", {
		Rotation = 0,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.5, 0.7),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, sideGlow)

	local safeArea = create("Frame", {
		Name = "SafeArea",
		BackgroundTransparency = 1,
		AnchorPoint = config.Layout.SafeAreaAnchorPoint,
		Position = config.Layout.SafeAreaPosition,
		Size = config.Layout.SafeAreaSize,
		ZIndex = 10,
	}, root)

	create("UISizeConstraint", {
		MinSize = config.Layout.SafeAreaMinSize,
	}, safeArea)

	local panel = create("Frame", {
		Name = "Panel",
		BackgroundColor3 = config.Style.PanelColor,
		BackgroundTransparency = config.Style.PanelTransparency,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 14,
	}, safeArea)

	addCorner(panel, 18)

	local panelStroke = create("UIStroke", {
		Thickness = 1,
		Color = config.Style.PanelStrokeColor,
		Transparency = config.Style.PanelStrokeTransparency,
	}, panel)

	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 34, 54)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 11, 20)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(1, 0.24),
		}),
	}, panel)

	create("Frame", {
		Name = "TopAccent",
		BackgroundColor3 = config.Style.AccentColor,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 2),
		ZIndex = 15,
	}, panel)

	local titleBlock = create("Frame", {
		Name = "TitleBlock",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, config.Layout.PanelPadding, 0, 20),
		Size = config.Layout.TitleBlockSize,
		ZIndex = 20,
	}, panel)

	local eyebrow = create("TextLabel", {
		Name = "Eyebrow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = config.EyebrowText or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = config.Style.EyebrowFont,
		TextSize = config.Style.EyebrowSize,
		TextColor3 = config.Style.AccentColor,
		TextTransparency = 0,
		ZIndex = 20,
	}, titleBlock)

	local title = create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 78),
		Text = config.TitleText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = config.Style.TitleFont,
		TextSize = config.Style.TitleSize,
		TextColor3 = config.Style.TextColor,
		TextStrokeColor3 = config.Style.TextStrokeColor,
		TextStrokeTransparency = 0.86,
		ZIndex = 20,
	}, titleBlock)

	local subtitle = create("TextLabel", {
		Name = "Subtitle",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 102),
		Size = UDim2.new(1, 0, 0, 22),
		Text = config.SubtitleText or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = config.Style.SubtitleFont,
		TextSize = config.Style.SubtitleSize,
		TextColor3 = config.Style.MutedTextColor,
		TextTransparency = 0.08,
		ZIndex = 20,
	}, titleBlock)

	local divider = create("Frame", {
		Name = "Divider",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -8),
		Size = config.Layout.DividerSize,
		BackgroundColor3 = config.Style.DividerColor,
		BackgroundTransparency = config.Style.DividerTransparency,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, titleBlock)

	local navList = create("Frame", {
		Name = "NavList",
		BackgroundTransparency = 1,
		Position = config.Layout.NavListPosition,
		Size = config.Layout.NavListSize,
		ZIndex = 22,
	}, panel)

	local buttonOrder = {}
	local buttonMap = {}

	for index, buttonConfig in ipairs(config.Buttons) do
		local buttonData = createButton(navList, config, buttonConfig, index)
		buttonMap[buttonConfig.Id] = buttonData
		table.insert(buttonOrder, buttonData)
	end

	local selectionIndicator = create("Frame", {
		Name = "SelectionIndicator",
		BackgroundColor3 = config.Style.IndicatorColor,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, config.Layout.IndicatorOffsetX, 0, config.Layout.IndicatorInsetY),
		Size = UDim2.new(0, 3, 0, config.Layout.IndicatorHeight),
		ZIndex = 27,
	}, navList)

	addCorner(selectionIndicator, 3)

	local footer = create("Frame", {
		Name = "Footer",
		BackgroundTransparency = 1,
		Position = config.Layout.FooterPosition,
		Size = config.Layout.FooterSize,
		ZIndex = 20,
	}, panel)

	local statusLeft = create("TextLabel", {
		Name = "StatusLeft",
		BackgroundTransparency = 1,
		Size = UDim2.new(0.68, 0, 1, 0),
		Text = config.Footer.Left,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = config.Style.FooterFont,
		TextSize = config.Style.FooterSize,
		TextColor3 = config.Style.TextColor,
		TextTransparency = 0.12,
		TextStrokeColor3 = config.Style.TextStrokeColor,
		TextStrokeTransparency = 0.95,
		ZIndex = 20,
	}, footer)

	local statusRight = create("TextLabel", {
		Name = "StatusRight",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0.32, 0, 1, 0),
		Text = config.Footer.Right,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
		Font = config.Style.FooterFont,
		TextSize = config.Style.FooterSize,
		TextColor3 = config.Style.TextColor,
		TextTransparency = 0.12,
		TextStrokeColor3 = config.Style.TextStrokeColor,
		TextStrokeTransparency = 0.95,
		ZIndex = 20,
	}, footer)

	local overlay = create("Frame", {
		Name = "Overlay",
		BackgroundColor3 = Color3.fromRGB(3, 8, 16),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
	}, root)

	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.18),
			NumberSequenceKeypoint.new(0.45, 0),
			NumberSequenceKeypoint.new(1, 0.22),
		}),
	}, overlay)

	local clickSound = create("Sound", {
		Name = "ClickSound",
		SoundId = "rbxassetid://9118823105",
		Volume = 0.25,
	}, screenGui)

	return {
		ScreenGui = screenGui,
		Root = root,
		SafeArea = safeArea,
		Panel = panel,
		PanelStroke = panelStroke,
		TitleBlock = titleBlock,
		Eyebrow = eyebrow,
		Title = title,
		Subtitle = subtitle,
		Divider = divider,
		NavList = navList,
		SelectionIndicator = selectionIndicator,
		Footer = footer,
		StatusLeft = statusLeft,
		StatusRight = statusRight,
		Overlay = overlay,
		ClickSound = clickSound,
		ButtonMap = buttonMap,
		ButtonOrder = buttonOrder,
	}
end

function MenuBuild.Destroy(view)
	if view and view.ScreenGui then
		view.ScreenGui:Destroy()
	end
end

return MenuBuild
