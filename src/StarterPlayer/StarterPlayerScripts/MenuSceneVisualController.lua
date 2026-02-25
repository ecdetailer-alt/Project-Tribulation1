local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local MenuFolder = ReplicatedStorage:WaitForChild("Menu")
local SignalBus = require(MenuFolder:WaitForChild("SignalBus"))

local MenuSceneVisualController = {}
MenuSceneVisualController.__index = MenuSceneVisualController

local function scaleVector3(v, sx, sy, sz)
	return Vector3.new(v.X * sx, v.Y * sy, v.Z * sz)
end

function MenuSceneVisualController.new()
	local self = setmetatable({}, MenuSceneVisualController)
	self._signalBus = SignalBus.getShared()
	self._connections = {}
	self._started = false
	self._time = 0
	self._sceneId = "FirePit"
	self._bossSequenceRunning = false
	self._heartbeatTimer = 0
	self._nextHeartbeat = math.random(32, 38)

	self._parts = {
		FirePitCore = Workspace:FindFirstChild("FirePitCore"),
		FogSheet = Workspace:FindFirstChild("FogSheet"),
		DomeField = Workspace:FindFirstChild("DomeField"),
		DomePulseRing = Workspace:FindFirstChild("DomePulseRing"),
		BossSilhouette = Workspace:FindFirstChild("BossSilhouette"),
		TurretLine = Workspace:FindFirstChild("TurretLine"),
		ImpactMarker = Workspace:FindFirstChild("ImpactMarker"),
		CommsBeacon = Workspace:FindFirstChild("CommsBeacon"),
	}
	self._atmosphere = nil
	self._colorCorrection = nil
	self._bloom = nil
	self._createdAtmosphere = false
	self._createdColorCorrection = false
	self._createdBloom = false
	self._lightingState = nil

	self._baseSizes = {}
	for partName, part in pairs(self._parts) do
		if part and part:IsA("BasePart") then
			self._baseSizes[partName] = part.Size
		end
	end

	return self
end

function MenuSceneVisualController:_applyLightingProfile()
	if not self._lightingState then
		self._lightingState = {
			Brightness = Lighting.Brightness,
			ClockTime = Lighting.ClockTime,
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
			EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
		}
	end

	Lighting.Brightness = 1.6
	Lighting.ClockTime = 0
	Lighting.Ambient = Color3.fromRGB(20, 26, 31)
	Lighting.OutdoorAmbient = Color3.fromRGB(8, 10, 14)
	Lighting.EnvironmentDiffuseScale = 0.32
	Lighting.EnvironmentSpecularScale = 0.42

	local atmosphere = Lighting:FindFirstChild("TribulationMenuAtmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "TribulationMenuAtmosphere"
		atmosphere.Parent = Lighting
		self._createdAtmosphere = true
	end
	atmosphere.Color = Color3.fromRGB(88, 102, 116)
	atmosphere.Decay = Color3.fromRGB(53, 62, 74)
	atmosphere.Density = 0.39
	atmosphere.Glare = 0.08
	atmosphere.Haze = 1.15
	self._atmosphere = atmosphere

	local colorCorrection = Lighting:FindFirstChild("TribulationMenuColor")
	if not colorCorrection then
		colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "TribulationMenuColor"
		colorCorrection.Parent = Lighting
		self._createdColorCorrection = true
	end
	colorCorrection.Brightness = -0.03
	colorCorrection.Contrast = 0.07
	colorCorrection.Saturation = -0.22
	colorCorrection.TintColor = Color3.fromRGB(189, 206, 220)
	self._colorCorrection = colorCorrection

	local bloom = Lighting:FindFirstChild("TribulationMenuBloom")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "TribulationMenuBloom"
		bloom.Parent = Lighting
		self._createdBloom = true
	end
	bloom.Intensity = 0.18
	bloom.Threshold = 1.35
	bloom.Size = 22
	self._bloom = bloom
end

function MenuSceneVisualController:_applyStaticStyle()
	local function style(partName, properties)
		local part = self._parts[partName]
		if not part or not part:IsA("BasePart") then
			return
		end

		for propertyName, value in pairs(properties) do
			part[propertyName] = value
		end
	end

	style("FirePitCore", {
		Color = Color3.fromRGB(255, 133, 62),
		Material = Enum.Material.Neon,
	})

	style("FogSheet", {
		Color = Color3.fromRGB(63, 75, 86),
		Material = Enum.Material.ForceField,
	})

	style("DomeField", {
		Color = Color3.fromRGB(84, 147, 162),
		Material = Enum.Material.ForceField,
	})

	style("DomePulseRing", {
		Color = Color3.fromRGB(118, 206, 223),
		Material = Enum.Material.Neon,
	})

	style("BossSilhouette", {
		Color = Color3.fromRGB(10, 14, 17),
		Material = Enum.Material.SmoothPlastic,
	})

	style("TurretLine", {
		Color = Color3.fromRGB(255, 187, 95),
		Material = Enum.Material.Neon,
	})

	style("ImpactMarker", {
		Color = Color3.fromRGB(167, 228, 255),
		Material = Enum.Material.Neon,
	})

	style("CommsBeacon", {
		Color = Color3.fromRGB(224, 79, 64),
		Material = Enum.Material.Neon,
	})

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Color = Color3.fromRGB(21, 26, 30)
		baseplate.Material = Enum.Material.Concrete
	end

	local deck = Workspace:FindFirstChild("BreachlineDeck")
	if deck and deck:IsA("BasePart") then
		deck.Color = Color3.fromRGB(35, 42, 49)
		deck.Material = Enum.Material.Metal
	end

	for _, partName in ipairs({
		"DeckRail_North",
		"DeckRail_East",
		"DeckRail_West",
		"CommsTower",
		"Floodlight_A",
		"Floodlight_B",
		"Floodlight_C",
		"Crate_A",
		"Crate_B",
		"ToppledAntenna",
	}) do
		local part = Workspace:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			part.Color = Color3.fromRGB(48, 57, 66)
			part.Material = Enum.Material.Metal
		end
	end

	for _, partName in ipairs({ "CityBlock_A", "CityBlock_B", "CityBlock_C" }) do
		local part = Workspace:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			part.Color = Color3.fromRGB(28, 34, 41)
			part.Material = Enum.Material.SmoothPlastic
		end
	end

	local breach = Workspace:FindFirstChild("BreachHorizon")
	if breach and breach:IsA("BasePart") then
		breach.Color = Color3.fromRGB(73, 42, 28)
		breach.Material = Enum.Material.ForceField
	end
end

function MenuSceneVisualController:_setPartTransparency(partName, value)
	local part = self._parts[partName]
	if part and part:IsA("BasePart") then
		part.Transparency = math.clamp(value, 0, 1)
	end
end

function MenuSceneVisualController:_setSceneVisualState(sceneId)
	self._sceneId = sceneId

	if sceneId == "FirePit" then
		self:_setPartTransparency("FirePitCore", 0.18)
		self:_setPartTransparency("FogSheet", 0.86)
		self:_setPartTransparency("BossSilhouette", 1)
		self:_setPartTransparency("TurretLine", 1)
		self:_setPartTransparency("ImpactMarker", 1)
		self:_setPartTransparency("DomeField", 0.86)
		self:_setPartTransparency("DomePulseRing", 1)
		if self._colorCorrection then
			self._colorCorrection.TintColor = Color3.fromRGB(201, 195, 182)
			self._colorCorrection.Contrast = 0.08
		end
		return
	end

	if sceneId == "BlackFogHorizon" then
		self:_setPartTransparency("FirePitCore", 0.96)
		self:_setPartTransparency("FogSheet", 0.7)
		self:_setPartTransparency("BossSilhouette", 1)
		self:_setPartTransparency("TurretLine", 1)
		self:_setPartTransparency("ImpactMarker", 1)
		self:_setPartTransparency("DomeField", 0.78)
		self:_setPartTransparency("DomePulseRing", 1)
		if self._colorCorrection then
			self._colorCorrection.TintColor = Color3.fromRGB(170, 196, 218)
			self._colorCorrection.Contrast = 0.13
		end
		return
	end

	if sceneId == "BossClashFreezeFrame" then
		self:_setPartTransparency("FirePitCore", 0.9)
		self:_setPartTransparency("FogSheet", 0.76)
		self:_setPartTransparency("BossSilhouette", 0.37)
		self:_setPartTransparency("DomeField", 0.72)
		if self._colorCorrection then
			self._colorCorrection.TintColor = Color3.fromRGB(228, 183, 151)
			self._colorCorrection.Contrast = 0.17
		end
		self:_playBossSequence()
	end
end

function MenuSceneVisualController:_playBossSequence()
	if self._bossSequenceRunning then
		return
	end

	self._bossSequenceRunning = true

	task.spawn(function()
		local turret = self._parts.TurretLine
		local impact = self._parts.ImpactMarker
		if turret and turret:IsA("BasePart") then
			turret.Transparency = 0.5
		end

		task.wait(0.9)
		self._signalBus:Fire("MenuLightningStrike", {
			Magnitude = 0.45,
			Duration = 0.33,
		})
		if impact and impact:IsA("BasePart") then
			impact.Transparency = 0.06
			local tweenOut = TweenService:Create(impact, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1,
				Size = self._baseSizes.ImpactMarker and (self._baseSizes.ImpactMarker * 1.35) or impact.Size,
			})
			tweenOut:Play()
		end

		task.wait(0.7)
		if turret and turret:IsA("BasePart") then
			turret.Transparency = 0.74
		end

		task.wait(1.8)
		if self._sceneId ~= "BossClashFreezeFrame" then
			self._bossSequenceRunning = false
			return
		end

		if turret and turret:IsA("BasePart") then
			turret.Transparency = 1
		end
		self._bossSequenceRunning = false
	end)
end

function MenuSceneVisualController:_heartbeatPulse()
	local dome = self._parts.DomeField
	local ring = self._parts.DomePulseRing
	if not dome or not dome:IsA("BasePart") then
		return
	end

	local minTransparency = math.max(0.55, dome.Transparency - 0.14)
	local tweenIn = TweenService:Create(dome, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		Transparency = minTransparency,
	})
	local tweenOut = TweenService:Create(dome, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		Transparency = math.clamp(minTransparency + 0.14, 0, 1),
	})

	tweenIn:Play()
	tweenIn.Completed:Connect(function()
		tweenOut:Play()
	end)

	if ring and ring:IsA("BasePart") then
		ring.Transparency = 0.2
		local originalSize = self._baseSizes.DomePulseRing or ring.Size
		ring.Size = scaleVector3(originalSize, 0.94, 1, 0.94)
		local ringTween = TweenService:Create(ring, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1,
			Size = scaleVector3(originalSize, 1.08, 1, 1.08),
		})
		ringTween:Play()
	end
end

function MenuSceneVisualController:_update(dt)
	self._time += dt

	local comms = self._parts.CommsBeacon
	if comms and comms:IsA("BasePart") then
		local blink = (math.sin(self._time * 3.4) + 1) * 0.5
		comms.Transparency = 0.35 + blink * 0.5
	end

	local fog = self._parts.FogSheet
	if fog and fog:IsA("BasePart") then
		local offset = math.sin(self._time * 0.08) * 3.5
		fog.Position = Vector3.new(0, 4, 84 + offset)
	end

	local fire = self._parts.FirePitCore
	if fire and fire:IsA("BasePart") and self._sceneId == "FirePit" then
		local flicker = 0.12 + (math.sin(self._time * 7.2) + 1) * 0.08
		fire.Transparency = flicker
	end

	self._heartbeatTimer += dt
	if self._heartbeatTimer >= self._nextHeartbeat then
		self._heartbeatTimer = 0
		self._nextHeartbeat = math.random(32, 38)
		self:_heartbeatPulse()
	end
end

function MenuSceneVisualController:Start()
	if self._started then
		return
	end

	self._started = true
	self:_applyLightingProfile()
	self:_applyStaticStyle()
	self:_setSceneVisualState("FirePit")

	table.insert(self._connections, self._signalBus:Connect("MenuSceneSelected", function(payload)
		local sceneId = payload and payload.SceneId
		if type(sceneId) == "string" then
			self:_setSceneVisualState(sceneId)
		end
	end))

	table.insert(self._connections, RunService.RenderStepped:Connect(function(dt)
		self:_update(dt)
	end))
end

function MenuSceneVisualController:Destroy()
	if not self._started then
		return
	end

	self._started = false
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	if self._lightingState then
		Lighting.Brightness = self._lightingState.Brightness
		Lighting.ClockTime = self._lightingState.ClockTime
		Lighting.Ambient = self._lightingState.Ambient
		Lighting.OutdoorAmbient = self._lightingState.OutdoorAmbient
		Lighting.EnvironmentDiffuseScale = self._lightingState.EnvironmentDiffuseScale
		Lighting.EnvironmentSpecularScale = self._lightingState.EnvironmentSpecularScale
	end

	if self._createdAtmosphere and self._atmosphere then
		self._atmosphere:Destroy()
	end
	if self._createdColorCorrection and self._colorCorrection then
		self._colorCorrection:Destroy()
	end
	if self._createdBloom and self._bloom then
		self._bloom:Destroy()
	end
end

return MenuSceneVisualController
