local TweenService = game:GetService("TweenService")

local MenuAnim = {}
MenuAnim.__index = MenuAnim

local function tween(instance, tweenInfo, properties)
	local animation = TweenService:Create(instance, tweenInfo, properties)
	animation:Play()
	return animation
end

local function shiftedPosition(base, xShift)
	return UDim2.new(base.X.Scale, base.X.Offset + xShift, base.Y.Scale, base.Y.Offset)
end

function MenuAnim.new(view, config)
	local self = setmetatable({}, MenuAnim)
	self._view = view
	self._config = config
	return self
end

function MenuAnim:SetIndicator(buttonData, instant)
	local indicator = self._view.SelectionIndicator
	local indicatorInsetY = self._config.Layout.IndicatorInsetY or 8
	local indicatorOffsetX = self._config.Layout.IndicatorOffsetX or -10
	local yOffset = buttonData.BasePosition.Y.Offset + indicatorInsetY
	local targetPosition = UDim2.new(0, indicatorOffsetX, 0, yOffset)
	local targetTransparency = self._config.Style.IndicatorTransparency

	if instant then
		indicator.Position = targetPosition
		indicator.BackgroundTransparency = targetTransparency
		return
	end

	local tweenInfo = TweenInfo.new(
		self._config.Animations.IndicatorSeconds,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	tween(indicator, tweenInfo, {
		Position = targetPosition,
		BackgroundTransparency = targetTransparency,
	})
end

function MenuAnim:HoverIn(buttonData)
	self:SetIndicator(buttonData, false)

	local hoverTween = TweenInfo.new(
		self._config.Animations.HoverSeconds,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	tween(buttonData.Button, hoverTween, {
		Position = shiftedPosition(buttonData.BasePosition, self._config.Layout.HoverShiftPixels),
		TextColor3 = self._config.Style.TextColor,
		TextTransparency = 0,
		BackgroundColor3 = buttonData.HoverBackgroundColor,
		BackgroundTransparency = self._config.Style.ButtonHoverTransparency,
	})

	if buttonData.DetailLabel then
		tween(buttonData.DetailLabel, hoverTween, {
			TextColor3 = self._config.Style.TextDimColor,
			TextTransparency = 0.05,
		})
	end

	if buttonData.Stroke then
		tween(buttonData.Stroke, hoverTween, {
			Transparency = self._config.Style.ButtonStrokeHoverTransparency,
			Color = self._config.Style.AccentColor,
		})
	end

	if buttonData.LeftAccent then
		tween(buttonData.LeftAccent, hoverTween, {
			BackgroundTransparency = 0.22,
			Size = UDim2.new(0, 5, 0, 38),
		})
	end

	local underlineWidth = math.max(buttonData.Button.TextBounds.X + 18, 110)
	local underlineTween = TweenInfo.new(
		self._config.Animations.UnderlineSeconds,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	tween(buttonData.Underline, underlineTween, {
		Size = UDim2.new(0, underlineWidth, 0, 2),
		BackgroundTransparency = 0.08,
	})
end

function MenuAnim:HoverOut(buttonData)
	local hoverTween = TweenInfo.new(
		self._config.Animations.HoverSeconds,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	tween(buttonData.Button, hoverTween, {
		Position = buttonData.BasePosition,
		TextColor3 = self._config.Style.TextDimColor,
		TextTransparency = self._config.Style.TextDimTransparency,
		BackgroundColor3 = buttonData.BaseBackgroundColor,
		BackgroundTransparency = self._config.Style.ButtonTransparency,
	})

	if buttonData.DetailLabel then
		tween(buttonData.DetailLabel, hoverTween, {
			TextColor3 = self._config.Style.MutedTextColor,
			TextTransparency = 0.28,
		})
	end

	if buttonData.Stroke then
		tween(buttonData.Stroke, hoverTween, {
			Transparency = self._config.Style.ButtonStrokeTransparency,
			Color = self._config.Style.ButtonStrokeColor,
		})
	end

	if buttonData.LeftAccent then
		tween(buttonData.LeftAccent, hoverTween, {
			BackgroundTransparency = 0.78,
			Size = UDim2.new(0, 3, 0, 38),
		})
	end

	local underlineTween = TweenInfo.new(
		self._config.Animations.UnderlineSeconds,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	tween(buttonData.Underline, underlineTween, {
		Size = UDim2.new(0, 0, 0, 2),
		BackgroundTransparency = 1,
	})
end

function MenuAnim:PlayClick(buttonData)
	local downTween = TweenInfo.new(
		self._config.Animations.ClickDownSeconds,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	local upTween = TweenInfo.new(
		self._config.Animations.ClickUpSeconds,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	)

	tween(buttonData.Scale, downTween, { Scale = 0.965 })
	task.delay(self._config.Animations.ClickDownSeconds, function()
		if buttonData.Scale and buttonData.Scale.Parent then
			tween(buttonData.Scale, upTween, { Scale = 1 })
		end
	end)

	if buttonData.LeftAccent then
		tween(buttonData.LeftAccent, downTween, {
			BackgroundTransparency = 0,
			Size = UDim2.new(0, 6, 0, 38),
		})
		task.delay(self._config.Animations.ClickDownSeconds + 0.04, function()
			if buttonData.LeftAccent and buttonData.LeftAccent.Parent then
				tween(buttonData.LeftAccent, upTween, {
					BackgroundTransparency = 0.22,
					Size = UDim2.new(0, 5, 0, 38),
				})
			end
		end)
	end

	if self._view.ClickSound then
		self._view.ClickSound:Play()
	end
end

function MenuAnim:PlayIntro()
	local config = self._config
	local view = self._view
	local title = view.Title
	local divider = view.Divider
	local statusLeft = view.StatusLeft
	local statusRight = view.StatusRight
	local panel = view.Panel
	local panelStroke = view.PanelStroke
	local eyebrow = view.Eyebrow
	local subtitle = view.Subtitle

	if panel then
		panel.BackgroundTransparency = 1
	end

	if panelStroke then
		panelStroke.Transparency = 1
	end

	if view.Overlay then
		view.Overlay.BackgroundTransparency = 1
	end

	title.TextTransparency = 1
	divider.BackgroundTransparency = 1
	statusLeft.TextTransparency = 1
	statusRight.TextTransparency = 1
	view.SelectionIndicator.BackgroundTransparency = 1

	if eyebrow then
		eyebrow.TextTransparency = 1
	end

	if subtitle then
		subtitle.TextTransparency = 1
	end

	for _, buttonData in ipairs(view.ButtonOrder) do
		buttonData.Button.Position = shiftedPosition(buttonData.BasePosition, config.Animations.ButtonIntroOffsetX)
		buttonData.Button.TextTransparency = 1
		buttonData.Button.TextStrokeTransparency = 1
		buttonData.Button.TextColor3 = config.Style.TextDimColor
		buttonData.Button.BackgroundTransparency = 1
		buttonData.Underline.Size = UDim2.new(0, 0, 0, 2)
		buttonData.Underline.BackgroundTransparency = 1

		if buttonData.DetailLabel then
			buttonData.DetailLabel.TextTransparency = 1
		end

		if buttonData.Stroke then
			buttonData.Stroke.Transparency = 1
			buttonData.Stroke.Color = config.Style.ButtonStrokeColor
		end

		if buttonData.LeftAccent then
			buttonData.LeftAccent.BackgroundTransparency = 1
			buttonData.LeftAccent.Size = UDim2.new(0, 3, 0, 38)
		end
	end

	if panel then
		tween(panel, TweenInfo.new(config.Animations.PanelFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = config.Style.PanelTransparency,
		})
	end

	if panelStroke then
		tween(panelStroke, TweenInfo.new(config.Animations.PanelFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = config.Style.PanelStrokeTransparency,
		})
	end

	if view.Overlay then
		tween(view.Overlay, TweenInfo.new(config.Animations.PanelFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = config.Style.OverlayTransparency,
		})
	end

	if eyebrow then
		tween(eyebrow, TweenInfo.new(config.Animations.TitleFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0,
		})
	end

	tween(title, TweenInfo.new(config.Animations.TitleFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	})

	if subtitle then
		tween(subtitle, TweenInfo.new(config.Animations.TitleFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0.08,
		})
	end

	tween(divider, TweenInfo.new(config.Animations.DividerFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = config.Style.DividerTransparency,
	})

	for index, buttonData in ipairs(view.ButtonOrder) do
		task.delay((index - 1) * config.Animations.ButtonStaggerSeconds, function()
			if not buttonData.Button.Parent then
				return
			end

			tween(buttonData.Button, TweenInfo.new(config.Animations.ButtonIntroSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = buttonData.BasePosition,
				TextTransparency = config.Style.TextDimTransparency,
				TextStrokeTransparency = config.Style.TextStrokeTransparency,
				BackgroundTransparency = config.Style.ButtonTransparency,
			})

			if buttonData.DetailLabel then
				tween(buttonData.DetailLabel, TweenInfo.new(config.Animations.ButtonIntroSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					TextTransparency = 0.28,
				})
			end

			if buttonData.Stroke then
				tween(buttonData.Stroke, TweenInfo.new(config.Animations.ButtonIntroSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Transparency = config.Style.ButtonStrokeTransparency,
				})
			end

			if buttonData.LeftAccent then
				tween(buttonData.LeftAccent, TweenInfo.new(config.Animations.ButtonIntroSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = 0.78,
				})
			end
		end)
	end

	local footerDelay = (#view.ButtonOrder - 1) * config.Animations.ButtonStaggerSeconds + config.Animations.ButtonIntroSeconds
	task.delay(footerDelay, function()
		if not statusLeft.Parent then
			return
		end

		tween(statusLeft, TweenInfo.new(config.Animations.FooterFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0.12,
		})
		tween(statusRight, TweenInfo.new(config.Animations.FooterFadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0.12,
		})
	end)
end

function MenuAnim:Destroy()
end

return MenuAnim
