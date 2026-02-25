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

local function getOrCreateEffect(className, name)
	local existing = Lighting:FindFirstChild(name)
	if existing and existing:IsA(className) then
		return existing, false
	end

	if existing then
		existing:Destroy()
	end

	local created = Instance.new(className)
	created.Name = name
	created.Parent = Lighting
	return created, true
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
	self._lightingState = nil
	self._createdEffects = {}

	self._parts = {
		FirePitCore = Workspace:FindFirstChild("FirePitCore"),
		FogSheet = Workspace:FindFirstChild("FogSheet"),
		DomeField = Workspace:FindFirstChild("DomeField"),
		DomePulseRing = Workspace:FindFirstChild("DomePulseRing"),
		BreachHorizon = Workspace:FindFirstChild("BreachHorizon"),
		BossSilhouette = Workspace:FindFirstChild("BossSilhouette"),
		TurretLine = Workspace:FindFirstChild("TurretLine"),
		ImpactMarker = Workspace:FindFirstChild("ImpactMarker"),
		CommsBeacon = Workspace:FindFirstChild("CommsBeacon"),
	}

	local impactRig = Workspace:FindFirstChild("DomeImpactRig")
	local impactAnchor = impactRig and impactRig:FindFirstChild("ImpactSparkAnchor")
	self._lights = {
		FireGlow = self._parts.FirePitCore and self._parts.FirePitCore:FindFirstChild("FireGlow"),
		DomeGlow = self._parts.DomeField and self._parts.DomeField:FindFirstChild("DomeGlow"),
		BreachGlow = self._parts.BreachHorizon and self._parts.BreachHorizon:FindFirstChild("BreachGlow"),
		BeaconPulse = self._parts.CommsBeacon and self._parts.CommsBeacon:FindFirstChild("BeaconPulse"),
		ImpactPulse = impactAnchor and impactAnchor:FindFirstChild("ImpactPulseLight"),
	}
	self._effectsParts = {
		Fire = self._parts.FirePitCore and self._parts.FirePitCore:FindFirstChild("CoreFire"),
		FireEmbers = self._parts.FirePitCore
			and self._parts.FirePitCore:FindFirstChild("FireAttachment")
			and self._parts.FirePitCore.FireAttachment:FindFirstChild("EmberEmitter"),
		BreachDust = self._parts.BreachHorizon
			and self._parts.BreachHorizon:FindFirstChild("BreachCoreAttachment")
			and self._parts.BreachHorizon.BreachCoreAttachment:FindFirstChild("BreachDustEmitter"),
		ImpactSparks = impactAnchor
			and impactAnchor:FindFirstChild("SparkAttachment")
			and impactAnchor.SparkAttachment:FindFirstChild("ImpactSparks"),
	}

	local atmosphere, createdAtmosphere = getOrCreateEffect("Atmosphere", "TribulationAtmosphere")
	local colorCorrection, createdColor = getOrCreateEffect("ColorCorrectionEffect", "TribulationColor")
	local bloom, createdBloom = getOrCreateEffect("BloomEffect", "TribulationBloom")
	local depthOfField, createdDof = getOrCreateEffect("DepthOfFieldEffect", "TribulationDepthOfField")
	local sunRays, createdSunRays = getOrCreateEffect("SunRaysEffect", "TribulationSunRays")
	local blur, createdBlur = getOrCreateEffect("BlurEffect", "TribulationBlur")

	self._effects = {
		Atmosphere = atmosphere,
		ColorCorrection = colorCorrection,
		Bloom = bloom,
		DepthOfField = depthOfField,
		SunRays = sunRays,
		Blur = blur,
	}

	self._createdEffects.TribulationAtmosphere = createdAtmosphere
	self._createdEffects.TribulationColor = createdColor
	self._createdEffects.TribulationBloom = createdBloom
	self._createdEffects.TribulationDepthOfField = createdDof
	self._createdEffects.TribulationSunRays = createdSunRays
	self._createdEffects.TribulationBlur = createdBlur

	self._baseSizes = {}
	for partName, part in pairs(self._parts) do
		if part and part:IsA("BasePart") then
			self._baseSizes[partName] = part.Size
		end
	end

	return self
end

function MenuSceneVisualController:_captureLightingState()
	if self._lightingState then
		return
	end

	self._lightingState = {
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
	}
end

function MenuSceneVisualController:_applyBaseLighting()
	self:_captureLightingState()
	Lighting.Brightness = 1.7
	Lighting.ClockTime = 0.1
	Lighting.Ambient = Color3.fromRGB(18, 22, 29)
	Lighting.OutdoorAmbient = Color3.fromRGB(8, 10, 14)
	Lighting.EnvironmentDiffuseScale = 0.27
	Lighting.EnvironmentSpecularScale = 0.44
end

function MenuSceneVisualController:_setPartTransparency(partName, value)
	local part = self._parts[partName]
	if part and part:IsA("BasePart") then
		part.Transparency = math.clamp(value, 0, 1)
	end
end

function MenuSceneVisualController:_applySceneShaders(sceneId)
	local atmosphere = self._effects.Atmosphere
	local color = self._effects.ColorCorrection
	local bloom = self._effects.Bloom
	local dof = self._effects.DepthOfField
	local sunRays = self._effects.SunRays
	local blur = self._effects.Blur

	if sceneId == "FirePit" then
		if atmosphere then
			atmosphere.Density = 0.42
			atmosphere.Haze = 1.1
			atmosphere.Glare = 0.08
			atmosphere.Color = Color3.fromRGB(103, 112, 124)
			atmosphere.Decay = Color3.fromRGB(66, 53, 44)
		end
		if color then
			color.Brightness = -0.05
			color.Contrast = 0.11
			color.Saturation = -0.14
			color.TintColor = Color3.fromRGB(220, 199, 178)
		end
		if bloom then
			bloom.Intensity = 0.24
			bloom.Threshold = 1.15
			bloom.Size = 26
		end
		if dof then
			dof.FocusDistance = 88
			dof.InFocusRadius = 42
			dof.NearIntensity = 0.06
			dof.FarIntensity = 0.16
		end
		if sunRays then
			sunRays.Intensity = 0.035
			sunRays.Spread = 0.24
		end
		if blur then
			blur.Size = 1.1
		end
		return
	end

	if sceneId == "BlackFogHorizon" then
		if atmosphere then
			atmosphere.Density = 0.55
			atmosphere.Haze = 1.65
			atmosphere.Glare = 0.04
			atmosphere.Color = Color3.fromRGB(86, 106, 126)
			atmosphere.Decay = Color3.fromRGB(48, 61, 77)
		end
		if color then
			color.Brightness = -0.08
			color.Contrast = 0.16
			color.Saturation = -0.28
			color.TintColor = Color3.fromRGB(166, 192, 224)
		end
		if bloom then
			bloom.Intensity = 0.14
			bloom.Threshold = 1.34
			bloom.Size = 20
		end
		if dof then
			dof.FocusDistance = 116
			dof.InFocusRadius = 30
			dof.NearIntensity = 0.1
			dof.FarIntensity = 0.25
		end
		if sunRays then
			sunRays.Intensity = 0.02
			sunRays.Spread = 0.18
		end
		if blur then
			blur.Size = 2.4
		end
		return
	end

	if sceneId == "BossClashFreezeFrame" then
		if atmosphere then
			atmosphere.Density = 0.46
			atmosphere.Haze = 1.02
			atmosphere.Glare = 0.11
			atmosphere.Color = Color3.fromRGB(122, 112, 110)
			atmosphere.Decay = Color3.fromRGB(82, 57, 48)
		end
		if color then
			color.Brightness = -0.03
			color.Contrast = 0.22
			color.Saturation = -0.1
			color.TintColor = Color3.fromRGB(238, 185, 146)
		end
		if bloom then
			bloom.Intensity = 0.39
			bloom.Threshold = 0.95
			bloom.Size = 34
		end
		if dof then
			dof.FocusDistance = 132
			dof.InFocusRadius = 24
			dof.NearIntensity = 0.12
			dof.FarIntensity = 0.29
		end
		if sunRays then
			sunRays.Intensity = 0.08
			sunRays.Spread = 0.34
		end
		if blur then
			blur.Size = 1.6
		end
	end
end

function MenuSceneVisualController:_setSceneVisualState(sceneId)
	self._sceneId = sceneId
	self:_applySceneShaders(sceneId)

	local fireObject = self._effectsParts.Fire
	local fireEmbers = self._effectsParts.FireEmbers
	local breachDust = self._effectsParts.BreachDust
	local impactSparks = self._effectsParts.ImpactSparks
	local fireGlow = self._lights.FireGlow
	local impactPulse = self._lights.ImpactPulse

	if sceneId == "FirePit" then
		self:_setPartTransparency("FirePitCore", 0.16)
		self:_setPartTransparency("FogSheet", 0.86)
		self:_setPartTransparency("BossSilhouette", 1)
		self:_setPartTransparency("TurretLine", 1)
		self:_setPartTransparency("ImpactMarker", 1)
		self:_setPartTransparency("DomeField", 0.82)
		self:_setPartTransparency("DomePulseRing", 1)
		if fireObject and fireObject:IsA("Fire") then
			fireObject.Enabled = true
		end
		if fireEmbers and fireEmbers:IsA("ParticleEmitter") then
			fireEmbers.Enabled = true
			fireEmbers.Rate = 14
		end
		if breachDust and breachDust:IsA("ParticleEmitter") then
			breachDust.Rate = 14
		end
		if fireGlow and fireGlow:IsA("PointLight") then
			fireGlow.Brightness = 3.1
		end
		if impactSparks and impactSparks:IsA("ParticleEmitter") then
			impactSparks.Rate = 4
		end
		if impactPulse and impactPulse:IsA("PointLight") then
			impactPulse.Brightness = 0.6
		end
		return
	end

	if sceneId == "BlackFogHorizon" then
		self:_setPartTransparency("FirePitCore", 0.96)
		self:_setPartTransparency("FogSheet", 0.64)
		self:_setPartTransparency("BossSilhouette", 1)
		self:_setPartTransparency("TurretLine", 1)
		self:_setPartTransparency("ImpactMarker", 1)
		self:_setPartTransparency("DomeField", 0.72)
		self:_setPartTransparency("DomePulseRing", 1)
		if fireObject and fireObject:IsA("Fire") then
			fireObject.Enabled = false
		end
		if fireEmbers and fireEmbers:IsA("ParticleEmitter") then
			fireEmbers.Enabled = false
		end
		if breachDust and breachDust:IsA("ParticleEmitter") then
			breachDust.Enabled = true
			breachDust.Rate = 28
		end
		if fireGlow and fireGlow:IsA("PointLight") then
			fireGlow.Brightness = 0.4
		end
		if impactSparks and impactSparks:IsA("ParticleEmitter") then
			impactSparks.Rate = 7
		end
		if impactPulse and impactPulse:IsA("PointLight") then
			impactPulse.Brightness = 1.2
		end
		return
	end

	if sceneId == "BossClashFreezeFrame" then
		self:_setPartTransparency("FirePitCore", 0.92)
		self:_setPartTransparency("FogSheet", 0.76)
		self:_setPartTransparency("BossSilhouette", 0.22)
		self:_setPartTransparency("TurretLine", 0.84)
		self:_setPartTransparency("ImpactMarker", 1)
		self:_setPartTransparency("DomeField", 0.63)
		self:_setPartTransparency("DomePulseRing", 1)
		if fireObject and fireObject:IsA("Fire") then
			fireObject.Enabled = false
		end
		if fireEmbers and fireEmbers:IsA("ParticleEmitter") then
			fireEmbers.Enabled = false
		end
		if breachDust and breachDust:IsA("ParticleEmitter") then
			breachDust.Enabled = true
			breachDust.Rate = 34
		end
		if fireGlow and fireGlow:IsA("PointLight") then
			fireGlow.Brightness = 0.3
		end
		if impactSparks and impactSparks:IsA("ParticleEmitter") then
			impactSparks.Rate = 12
		end
		if impactPulse and impactPulse:IsA("PointLight") then
			impactPulse.Brightness = 1.9
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
			turret.Transparency = 0.43
		end

		task.wait(0.9)
		self._signalBus:Fire("MenuLightningStrike", {
			Magnitude = 0.48,
			Duration = 0.33,
		})

		if impact and impact:IsA("BasePart") then
			impact.Transparency = 0.05
			local tweenOut = TweenService:Create(impact, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1,
				Size = self._baseSizes.ImpactMarker and scaleVector3(self._baseSizes.ImpactMarker, 1.35, 1.35, 1) or impact.Size,
			})
			tweenOut:Play()
		end

		task.wait(0.72)
		if turret and turret:IsA("BasePart") then
			turret.Transparency = 0.72
		end

		task.wait(1.6)
		if self._sceneId == "BossClashFreezeFrame" and turret and turret:IsA("BasePart") then
			turret.Transparency = 0.84
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

	local minTransparency = math.max(0.48, dome.Transparency - 0.18)
	local tweenIn = TweenService:Create(dome, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		Transparency = minTransparency,
	})
	local tweenOut = TweenService:Create(dome, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		Transparency = math.clamp(minTransparency + 0.18, 0, 1),
	})

	tweenIn:Play()
	tweenIn.Completed:Connect(function()
		tweenOut:Play()
	end)

	if ring and ring:IsA("BasePart") then
		ring.Transparency = 0.16
		local originalSize = self._baseSizes.DomePulseRing or ring.Size
		ring.Size = scaleVector3(originalSize, 0.94, 1, 0.94)
		local ringTween = TweenService:Create(ring, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1,
			Size = scaleVector3(originalSize, 1.1, 1, 1.1),
		})
		ringTween:Play()
	end
end

function MenuSceneVisualController:_update(dt)
	self._time += dt

	local comms = self._parts.CommsBeacon
	if comms and comms:IsA("BasePart") then
		local blink = (math.sin(self._time * 3.4) + 1) * 0.5
		comms.Transparency = 0.26 + blink * 0.62
	end
	local beaconPulse = self._lights.BeaconPulse
	if beaconPulse and beaconPulse:IsA("PointLight") then
		beaconPulse.Brightness = 1.2 + (math.sin(self._time * 3.4) + 1) * 1.2
	end

	local fog = self._parts.FogSheet
	if fog and fog:IsA("BasePart") then
		local offset = math.sin(self._time * 0.08) * 3.5
		fog.Position = Vector3.new(0, 4, 84 + offset)
	end

	local fire = self._parts.FirePitCore
	if fire and fire:IsA("BasePart") and self._sceneId == "FirePit" then
		local flicker = 0.08 + (math.sin(self._time * 7.2) + 1) * 0.08
		fire.Transparency = flicker
	end
	local fireGlow = self._lights.FireGlow
	if fireGlow and fireGlow:IsA("PointLight") and self._sceneId == "FirePit" then
		fireGlow.Brightness = 2.5 + (math.sin(self._time * 9.1) + 1) * 0.8
	end
	local domeGlow = self._lights.DomeGlow
	if domeGlow and domeGlow:IsA("PointLight") then
		domeGlow.Brightness = 1 + (math.sin(self._time * 0.7) + 1) * 0.22
	end
	local breachGlow = self._lights.BreachGlow
	if breachGlow and breachGlow:IsA("PointLight") then
		breachGlow.Brightness = 1.2 + (math.sin(self._time * 1.3) + 1) * 0.35
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
	self:_applyBaseLighting()
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

	for effectName, created in pairs(self._createdEffects) do
		if created then
			local effect = Lighting:FindFirstChild(effectName)
			if effect then
				effect:Destroy()
			end
		end
	end
end

return MenuSceneVisualController
