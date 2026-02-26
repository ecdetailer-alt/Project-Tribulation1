local MenuUI = {}
MenuUI.__index = MenuUI

local BUTTONS = {
	{ Id = "Continue", Label = "Continue" },
	{ Id = "OpenWorld", Label = "Open World" },
	{ Id = "Party", Label = "Party" },
	{ Id = "Character", Label = "Character" },
	{ Id = "Settings", Label = "Settings" },
}

local BASE_TEXT_COLOR = Color3.fromRGB(226, 226, 226)

local function create(className, properties, parent)
	local instance = Instance.new(className)
	for key, value in pairs(properties) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

function MenuUI.new(playerGui)
	local existingGui = playerGui:FindFirstChild("TribulationMenu")
	if existingGui then
		existingGui:Destroy()
	end

	local self = setmetatable({}, MenuUI)
	self._connections = {}
	self.ButtonEntries = {}

	self.ScreenGui = create("ScreenGui", {
		Name = "TribulationMenu",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 25,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)

	self.Root = create("Frame", {
		Name = "Root",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, self.ScreenGui)

	self.Title = create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.new(0.06, 0, 0.18, 0),
		Size = UDim2.new(0, 620, 0, 74),
		Text = "Project Tribulation",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextSize = 52,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(242, 242, 242),
		TextStrokeColor3 = Color3.new(0, 0, 0),
		TextStrokeTransparency = 0.82,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, self.Root)

	local buttonStartY = 0.38
	local buttonSpacing = 64

	for index, buttonDefinition in ipairs(BUTTONS) do
		local yOffset = (index - 1) * buttonSpacing
		local position = UDim2.new(0.06, 0, buttonStartY, yOffset)

		local button = create("TextButton", {
			Name = buttonDefinition.Id,
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = position,
			Size = UDim2.new(0, 460, 0, 48),
			Text = buttonDefinition.Label,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextSize = 40,
			Font = Enum.Font.GothamMedium,
			TextColor3 = BASE_TEXT_COLOR,
			TextStrokeColor3 = Color3.new(0, 0, 0),
			TextStrokeTransparency = 0.84,
			ZIndex = 20,
		}, self.Root)

		local scale = create("UIScale", {
			Name = "ButtonScale",
			Scale = 1,
		}, button)

		local underline = create("Frame", {
			Name = "Underline",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, -2),
			Size = UDim2.new(0, 0, 0, 1),
			BackgroundColor3 = Color3.fromRGB(246, 246, 246),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 21,
		}, button)

		table.insert(self.ButtonEntries, {
			Id = buttonDefinition.Id,
			Label = buttonDefinition.Label,
			Button = button,
			Scale = scale,
			Underline = underline,
			BasePosition = position,
		})
	end

	self.ClickSound = create("Sound", {
		Name = "ClickSound",
		SoundId = "rbxassetid://9118823105",
		Volume = 0.3,
		RollOffMaxDistance = 30,
	}, self.ScreenGui)

	return self
end

function MenuUI:SetActionHandler(handler)
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	if type(handler) ~= "function" then
		return
	end

	for _, entry in ipairs(self.ButtonEntries) do
		table.insert(self._connections, entry.Button.Activated:Connect(function()
			handler(entry.Id, entry.Label)
		end))
	end
end

function MenuUI:Destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end
end

return MenuUI
