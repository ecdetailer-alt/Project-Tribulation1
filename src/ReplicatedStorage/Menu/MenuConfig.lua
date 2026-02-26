local MenuConfig = {}

MenuConfig.EyebrowText = "OPERATIONS TERMINAL"
MenuConfig.TitleText = "PROJECT TRIBULATION"
MenuConfig.SubtitleText = "Containment Deck Theta"

MenuConfig.Footer = {
	Left = "Signal Locked",
	Right = "v0.2.0",
}

MenuConfig.Buttons = {
	{ Id = "Continue", Text = "Continue", Detail = "Rejoin active deployment" },
	{ Id = "OpenWorld", Text = "Open World", Detail = "Traverse breachline sector" },
	{ Id = "Party", Text = "Party", Detail = "Squad and matchmaking" },
	{ Id = "Character", Text = "Character", Detail = "Loadout and perks" },
	{ Id = "Settings", Text = "Settings", Detail = "Graphics and controls" },
}

MenuConfig.Layout = {
	SafeAreaAnchorPoint = Vector2.new(0, 0.5),
	SafeAreaPosition = UDim2.new(0.05, 0, 0.5, 0),
	SafeAreaSize = UDim2.new(0.36, 0, 0.76, 0),
	SafeAreaMinSize = Vector2.new(420, 560),
	PanelPadding = 24,
	TitleBlockSize = UDim2.new(1, -48, 0, 170),
	DividerSize = UDim2.new(0.84, 0, 0, 1),
	NavListPosition = UDim2.new(0, 24, 0, 192),
	NavListSize = UDim2.new(1, -48, 0, 360),
	FooterPosition = UDim2.new(0, 24, 1, -52),
	FooterSize = UDim2.new(1, -48, 0, 26),
	ButtonSize = UDim2.new(1, 0, 0, 58),
	ButtonSpacing = 70,
	HoverShiftPixels = 8,
	IndicatorOffsetX = -12,
	IndicatorHeight = 36,
	IndicatorInsetY = 11,
}

MenuConfig.Style = {
	TitleFont = Enum.Font.GothamBlack,
	TitleSize = 48,
	EyebrowFont = Enum.Font.GothamSemibold,
	EyebrowSize = 15,
	SubtitleFont = Enum.Font.Gotham,
	SubtitleSize = 16,
	ButtonFont = Enum.Font.GothamSemibold,
	ButtonSize = 28,
	ButtonDetailFont = Enum.Font.Gotham,
	ButtonDetailSize = 13,
	FooterFont = Enum.Font.Gotham,
	FooterSize = 15,
	TextColor = Color3.fromRGB(241, 248, 255),
	TextDimColor = Color3.fromRGB(188, 204, 222),
	MutedTextColor = Color3.fromRGB(151, 170, 189),
	AccentColor = Color3.fromRGB(95, 216, 255),
	AccentSoftColor = Color3.fromRGB(104, 141, 186),
	PanelColor = Color3.fromRGB(9, 14, 23),
	PanelTransparency = 0.2,
	PanelStrokeColor = Color3.fromRGB(123, 163, 210),
	PanelStrokeTransparency = 0.38,
	ButtonColor = Color3.fromRGB(15, 25, 40),
	ButtonTransparency = 0.22,
	ButtonHoverColor = Color3.fromRGB(24, 39, 61),
	ButtonHoverTransparency = 0.08,
	ButtonStrokeColor = Color3.fromRGB(110, 146, 188),
	ButtonStrokeTransparency = 0.46,
	ButtonStrokeHoverTransparency = 0.08,
	DividerColor = Color3.fromRGB(107, 141, 184),
	DividerTransparency = 0.44,
	IndicatorColor = Color3.fromRGB(95, 216, 255),
	IndicatorTransparency = 0.16,
	TextStrokeColor = Color3.fromRGB(3, 6, 10),
	TextStrokeTransparency = 0.82,
	TextDimTransparency = 0.07,
	OverlayColor = Color3.fromRGB(2, 4, 8),
	OverlayTransparency = 0.9,
}

MenuConfig.Animations = {
	PanelFadeSeconds = 0.32,
	TitleFadeSeconds = 0.28,
	DividerFadeSeconds = 0.22,
	ButtonIntroSeconds = 0.28,
	ButtonIntroOffsetX = -36,
	ButtonStaggerSeconds = 0.065,
	FooterFadeSeconds = 0.22,
	HoverSeconds = 0.12,
	IndicatorSeconds = 0.12,
	UnderlineSeconds = 0.12,
	ClickDownSeconds = 0.055,
	ClickUpSeconds = 0.11,
}

MenuConfig.Scenes = {
	Default = "A_FirePit",
	IdleShift = "B_Fog",
	ContinueScene = "C_Boss",
	IdleAfterSeconds = 10,
	HoverSceneSwitchingDefault = false,
	HoverSceneMap = {
		Continue = "A_FirePit",
		OpenWorld = "A_FirePit",
		Party = "B_Fog",
		Character = "A_FirePit",
		Settings = "B_Fog",
	},
}

MenuConfig.Camera = {
	FieldOfView = 70,
	TransitionSeconds = 1.05,
	BossTransitionSeconds = 1.35,
	SwayDegrees = 0.8,
	ImpactDecay = 6,
	SceneAnchors = {
		A_FirePit = {
			CameraPart = "MenuCam_A_FirePit",
			LookAtPart = "MenuLookAt_A_FirePit",
			FallbackPosition = Vector3.new(24, 14, 30),
			FallbackLookAt = Vector3.new(0, 6, 0),
		},
		B_Fog = {
			CameraPart = "MenuCam_B_Fog",
			LookAtPart = "MenuLookAt_B_Fog",
			FallbackPosition = Vector3.new(-28, 17, 14),
			FallbackLookAt = Vector3.new(0, 7, 0),
		},
		C_Boss = {
			CameraPart = "MenuCam_C_Boss",
			LookAtPart = "MenuLookAt_C_Boss",
			FallbackPosition = Vector3.new(8, 16, -26),
			FallbackLookAt = Vector3.new(0, 8, 0),
		},
	},
}

return MenuConfig
