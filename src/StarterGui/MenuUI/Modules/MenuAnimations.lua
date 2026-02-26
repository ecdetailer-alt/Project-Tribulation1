local TweenService = game:GetService("TweenService")

local MenuAnimations = {}
MenuAnimations.__index = MenuAnimations

local BASE_TEXT_COLOR = Color3.fromRGB(226, 226, 226)
local HOVER_TEXT_COLOR = Color3.fromRGB(245, 245, 245)

local TITLE_INTRO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BUTTON_INTRO = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HOVER_TWEEN = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLICK_DOWN_TWEEN = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLICK_UP_TWEEN = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function offsetPosition(position, xOffset, yOffset)
	return UDim2.new(
		position.X.Scale,
		position.X.Offset + xOffset,
		position.Y.Scale,
		position.Y.Offset + yOffset
	)
end

local function tween(instance, tweenInfo, properties)
	local animation = TweenService:Create(instance, tweenInfo, properties)
	animation:Play()
	return animation
end

function MenuAnimations.new(menuUI)
	local self = setmetatable({}, MenuAnimations)
	self._menuUI = menuUI
	self._connections = {}
	self._introPlayed = false
	self:_bindInteractions()
	return self
end

function MenuAnimations:_bindInteractions()
	for _, entry in ipairs(self._menuUI.ButtonEntries) do
		table.insert(self._connections, entry.Button.MouseEnter:Connect(function()
			self:_setHover(entry, true)
		end))

		table.insert(self._connections, entry.Button.MouseLeave:Connect(function()
			self:_setHover(entry, false)
		end))

		table.insert(self._connections, entry.Button.Activated:Connect(function()
			self:_playClick(entry)
		end))
	end
end

function MenuAnimations:_setHover(entry, isHovered)
	if not entry.Button.Parent then
		return
	end

	local targetX = isHovered and 8 or 0
	local underlineWidth = math.max(entry.Button.TextBounds.X, 90)
	local underlineTargetSize = isHovered and UDim2.new(0, underlineWidth, 0, 1) or UDim2.new(0, 0, 0, 1)
	local underlineTargetTransparency = isHovered and 0.2 or 1
	local targetColor = isHovered and HOVER_TEXT_COLOR or BASE_TEXT_COLOR

	tween(entry.Button, HOVER_TWEEN, {
		Position = offsetPosition(entry.BasePosition, targetX, 0),
		TextColor3 = targetColor,
	})

	tween(entry.Underline, HOVER_TWEEN, {
		Size = underlineTargetSize,
		BackgroundTransparency = underlineTargetTransparency,
	})
end

function MenuAnimations:_playClick(entry)
	if entry.Scale then
		tween(entry.Scale, CLICK_DOWN_TWEEN, { Scale = 0.98 })
		task.delay(CLICK_DOWN_TWEEN.Time, function()
			if entry.Scale and entry.Scale.Parent then
				tween(entry.Scale, CLICK_UP_TWEEN, { Scale = 1 })
			end
		end)
	end

	local clickSound = self._menuUI.ClickSound
	if clickSound then
		clickSound:Play()
	end
end

function MenuAnimations:PlayIntro()
	if self._introPlayed then
		return
	end
	self._introPlayed = true

	local title = self._menuUI.Title
	title.TextTransparency = 1
	title.TextStrokeTransparency = 1
	tween(title, TITLE_INTRO, {
		TextTransparency = 0,
		TextStrokeTransparency = 0.82,
	})

	for index, entry in ipairs(self._menuUI.ButtonEntries) do
		entry.Button.Position = offsetPosition(entry.BasePosition, -40, 0)
		entry.Button.TextTransparency = 1
		entry.Button.TextStrokeTransparency = 1
		entry.Button.TextColor3 = BASE_TEXT_COLOR
		entry.Underline.Size = UDim2.new(0, 0, 0, 1)
		entry.Underline.BackgroundTransparency = 1

		task.delay((index - 1) * 0.06, function()
			if not entry.Button.Parent then
				return
			end

			tween(entry.Button, BUTTON_INTRO, {
				Position = entry.BasePosition,
				TextTransparency = 0,
				TextStrokeTransparency = 0.84,
			})
		end)
	end
end

function MenuAnimations:Destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

return MenuAnimations
