local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local RENDER_BIND_NAME = "TribulationMenuAmbienceControllerV2"

local AMBIENT_SOUNDS = {
	{
		Name = "WindBed",
		SoundId = "rbxassetid://9118747549",
		Volume = 0.09,
		PlaybackSpeed = 0.92,
	},
	{
		Name = "DistantRumble",
		SoundId = "rbxassetid://9125351901",
		Volume = 0.06,
		PlaybackSpeed = 0.82,
	},
	{
		Name = "CityHum",
		SoundId = "rbxassetid://9112758242",
		Volume = 0.05,
		PlaybackSpeed = 0.96,
	},
}

local AmbienceController = {}
AmbienceController.__index = AmbienceController

local function findPartByNames(names)
	for _, name in ipairs(names) do
		local found = Workspace:FindFirstChild(name, true)
		if found and found:IsA("BasePart") then
			return found
		end
	end
	return nil
end

local function randomRange(minValue, maxValue)
	return minValue + (math.random() * (maxValue - minValue))
end

local function create(className, properties, parent)
	local instance = Instance.new(className)
	for key, value in pairs(properties) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

function AmbienceController.new(options)
	options = options or {}

	local localPlayer = Players.LocalPlayer
	local self = setmetatable({}, AmbienceController)
	self._playerGui = options.PlayerGui or localPlayer:WaitForChild("PlayerGui")
	self._connections = {}
	self._capturedProperties = {}
	self._temporaryInstances = {}
	self._isRunning = false
	self._startTime = 0

	self._fogNear = nil
	self._fogFar = nil
	self._barrierField = nil
	self._barrierRing = nil
	self._silhouette = nil
	self._domeGlow = nil
	self._silhouetteRim = nil
	self._firePart = nil
	self._emberEmitter = nil
	self._grainLabel = nil
	self._postFxGui = nil
	self._audioFolder = nil
	self._audioLayers = {}

	self._nextEventAt = 0
	self._eventBusy = false
	self._lastEvent = nil

	return self
end

function AmbienceController:_capture(instance, properties)
	if not instance then
		return
	end

	local record = self._capturedProperties[instance]
	if not record then
		record = {}
		self._capturedProperties[instance] = record
	end

	for _, propertyName in ipairs(properties) do
		if record[propertyName] == nil then
			record[propertyName] = instance[propertyName]
		end
	end
end

function AmbienceController:_resolveSceneReferences()
	self._fogNear = findPartByNames({ "FogSheet" })
	self._fogFar = findPartByNames({ "BreachHorizon" })
	self._barrierField = findPartByNames({ "DomeField" })
	self._barrierRing = findPartByNames({ "DomePulseRing" })
	self._silhouette = findPartByNames({ "BossSilhouette" })
	self._firePart = findPartByNames({ "FirePitCore" })

	if self._barrierField then
		local domeGlow = self._barrierField:FindFirstChild("DomeGlow")
		if domeGlow and domeGlow:IsA("PointLight") then
			self._domeGlow = domeGlow
		end
	end

	if self._silhouette then
		local rim = self._silhouette:FindFirstChild("BackRimLight")
		if rim and rim:IsA("PointLight") then
			self._silhouetteRim = rim
		end
	end

	if self._firePart then
		local fireAttachment = self._firePart:FindFirstChild("FireAttachment")
		if fireAttachment and fireAttachment:IsA("Attachment") then
			local emitter = fireAttachment:FindFirstChild("EmberEmitter")
			if emitter and emitter:IsA("ParticleEmitter") then
				self._emberEmitter = emitter
			end
		end
	end

	if self._fogNear then
		self:_capture(self._fogNear, { "CFrame", "Size", "Transparency" })
	end

	if self._fogFar then
		self:_capture(self._fogFar, { "CFrame", "Size", "Transparency" })
	end

	if self._barrierField then
		self:_capture(self._barrierField, { "Transparency", "Color" })
	end

	if self._barrierRing then
		self:_capture(self._barrierRing, { "Transparency", "Size" })
	end

	if self._silhouette then
		self:_capture(self._silhouette, { "Transparency" })
	end

	if self._domeGlow then
		self:_capture(self._domeGlow, { "Brightness" })
	end

	if self._silhouetteRim then
		self:_capture(self._silhouetteRim, { "Brightness" })
	end

	if self._emberEmitter then
		self:_capture(self._emberEmitter, { "Rate", "Speed", "Acceleration", "SpreadAngle" })
	end
end

function AmbienceController:_createVignetteEdge(parent, name, position, size, rotation)
	local edge = create("Frame", {
		Name = name,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.48,
		BorderSizePixel = 0,
		Position = position,
		Size = size,
		ZIndex = 6,
	}, parent)

	create("UIGradient", {
		Rotation = rotation,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, edge)
end

function AmbienceController:_createPostFx()
	local existing = self._playerGui:FindFirstChild("TribulationMenuPostFX")
	if existing and existing:IsA("ScreenGui") then
		existing:Destroy()
	end

	local screenGui = create("ScreenGui", {
		Name = "TribulationMenuPostFX",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 70,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, self._playerGui)

	self._postFxGui = screenGui

	local root = create("Frame", {
		Name = "Root",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
	}, screenGui)

	self._grainLabel = create("ImageLabel", {
		Name = "FilmGrain",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 8, 1, 8),
		Position = UDim2.fromOffset(-4, -4),
		Image = "rbxasset://textures/particles/smoke_main.dds",
		ImageColor3 = Color3.fromRGB(226, 231, 238),
		ImageTransparency = 0.94,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(200, 200),
		ZIndex = 5,
	}, root)

	self:_createVignetteEdge(root, "TopVignette", UDim2.fromScale(0, 0), UDim2.new(1, 0, 0.18, 0), 90)
	self:_createVignetteEdge(root, "BottomVignette", UDim2.new(0, 0, 0.82, 0), UDim2.new(1, 0, 0.18, 0), -90)
	self:_createVignetteEdge(root, "LeftVignette", UDim2.fromScale(0, 0), UDim2.new(0.16, 0, 1, 0), 0)
	self:_createVignetteEdge(root, "RightVignette", UDim2.new(0.84, 0, 0, 0), UDim2.new(0.16, 0, 1, 0), 180)
end

function AmbienceController:_createAudioBed()
	local existing = SoundService:FindFirstChild("TribulationMenuAmbience")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "TribulationMenuAmbience"
	folder.Parent = SoundService
	self._audioFolder = folder

	for index, layer in ipairs(AMBIENT_SOUNDS) do
		local sound = Instance.new("Sound")
		sound.Name = layer.Name
		sound.SoundId = layer.SoundId
		sound.Looped = true
		sound.Volume = 0
		sound.PlaybackSpeed = layer.PlaybackSpeed
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.Parent = folder

		sound:Play()
		TweenService:Create(
			sound,
			TweenInfo.new(2.6 + (index * 0.4), Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Volume = layer.Volume }
		):Play()

		table.insert(self._audioLayers, {
			Sound = sound,
			BaseVolume = layer.Volume,
			Phase = index * 1.1,
		})
	end
end

function AmbienceController:_updateFogMotion(elapsed)
	if self._fogNear then
		local base = self._capturedProperties[self._fogNear]
		if base then
			local breathe = math.sin(elapsed * 0.18)
			local lateral = math.sin(elapsed * 0.05) * 0.7
			local depth = math.cos(elapsed * 0.04) * 1.4

			self._fogNear.CFrame = base.CFrame * CFrame.new(lateral, 0.18 * breathe, depth)
			self._fogNear.Transparency = math.clamp(base.Transparency + (breathe * 0.04), 0.68, 0.93)
			self._fogNear.Size = Vector3.new(base.Size.X, base.Size.Y, base.Size.Z + (breathe * 1.6))
		end
	end

	if self._fogFar then
		local base = self._capturedProperties[self._fogFar]
		if base then
			local breathe = math.sin((elapsed * 0.14) + 1.2)
			local lateral = math.sin(elapsed * 0.03) * 1.2
			local driftForward = math.sin(elapsed * 0.02 + 0.4) * 2.2

			self._fogFar.CFrame = base.CFrame * CFrame.new(lateral, 0.24 * breathe, driftForward)
			self._fogFar.Transparency = math.clamp(base.Transparency + (breathe * 0.05), 0.19, 0.45)
			self._fogFar.Size = Vector3.new(base.Size.X, base.Size.Y, base.Size.Z + (breathe * 4.8))
		end
	end
end

function AmbienceController:_updateBarrierMotion(elapsed)
	if self._barrierField then
		local base = self._capturedProperties[self._barrierField]
		if base then
			local wave = math.sin(elapsed * 0.38 + 0.7)
			self._barrierField.Transparency = math.clamp(base.Transparency + (wave * 0.02), 0.75, 0.92)
		end
	end

	if self._barrierRing then
		local base = self._capturedProperties[self._barrierRing]
		if base then
			local wave = math.sin(elapsed * 0.45)
			self._barrierRing.Transparency = math.clamp(base.Transparency + (wave * 0.03), 0.9, 1)
		end
	end

	if self._domeGlow then
		local base = self._capturedProperties[self._domeGlow]
		if base then
			local brightnessWave = math.sin(elapsed * 0.42 + 0.3) * 0.14
			self._domeGlow.Brightness = math.max(base.Brightness + brightnessWave, 0.2)
		end
	end
end

function AmbienceController:_updatePostFx(elapsed)
	if self._grainLabel then
		local xShift = math.sin(elapsed * 17.4) * 2
		local yShift = math.cos(elapsed * 13.9) * 2
		self._grainLabel.Position = UDim2.fromOffset(-4 + xShift, -4 + yShift)
		self._grainLabel.ImageTransparency = math.clamp(0.94 + (math.sin(elapsed * 9.2) * 0.018), 0.9, 0.98)
	end
end

function AmbienceController:_pickEventName()
	local candidates = { "Lightning", "BarrierSurge", "SilhouetteFlicker", "EmberGust" }

	if self._lastEvent then
		for index, eventName in ipairs(candidates) do
			if eventName == self._lastEvent then
				table.remove(candidates, index)
				break
			end
		end
	end

	return candidates[math.random(1, #candidates)]
end

function AmbienceController:_eventLightning()
	local fogPart = self._fogFar or self._fogNear
	if not fogPart then
		return 0.55
	end

	local lightning = fogPart:FindFirstChild("MenuLightningFlash")
	if not lightning or not lightning:IsA("PointLight") then
		lightning = Instance.new("PointLight")
		lightning.Name = "MenuLightningFlash"
		lightning.Color = Color3.fromRGB(173, 194, 224)
		lightning.Range = 320
		lightning.Brightness = 0
		lightning.Shadows = false
		lightning.Parent = fogPart
		table.insert(self._temporaryInstances, lightning)
	end

	local fogBase = self._capturedProperties[fogPart]
	local silhouetteBase = self._silhouette and self._capturedProperties[self._silhouette]

	task.spawn(function()
		for _ = 1, 2 do
			if not lightning.Parent then
				break
			end

			lightning.Brightness = 2.6 + (math.random() * 2.1)
			if fogBase then
				fogPart.Transparency = math.max(fogBase.Transparency - 0.18, 0.05)
			end

			if self._silhouette and silhouetteBase then
				self._silhouette.Transparency = math.max(silhouetteBase.Transparency - 0.17, 0.56)
			end

			task.wait(0.05 + (math.random() * 0.04))
			lightning.Brightness = 0

			if fogBase then
				fogPart.Transparency = fogBase.Transparency
			end

			if self._silhouette and silhouetteBase then
				self._silhouette.Transparency = silhouetteBase.Transparency
			end

			task.wait(0.08 + (math.random() * 0.08))
		end
	end)

	return 0.55
end

function AmbienceController:_eventBarrierSurge()
	local duration = 1.15

	if self._barrierRing then
		local ringBase = self._capturedProperties[self._barrierRing]
		if ringBase then
			local ringExpand = TweenService:Create(
				self._barrierRing,
				TweenInfo.new(0.24, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{
					Transparency = math.max(ringBase.Transparency - 0.72, 0.17),
					Size = ringBase.Size + Vector3.new(0, 0, 8),
				}
			)
			ringExpand:Play()

			task.delay(0.24, function()
				if self._barrierRing and self._barrierRing.Parent then
					TweenService:Create(
						self._barrierRing,
						TweenInfo.new(0.78, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
						{
							Transparency = ringBase.Transparency,
							Size = ringBase.Size,
						}
					):Play()
				end
			end)
		end
	end

	if self._barrierField then
		local fieldBase = self._capturedProperties[self._barrierField]
		if fieldBase then
			TweenService:Create(
				self._barrierField,
				TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ Transparency = math.max(fieldBase.Transparency - 0.2, 0.5) }
			):Play()

			task.delay(0.18, function()
				if self._barrierField and self._barrierField.Parent then
					TweenService:Create(
						self._barrierField,
						TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
						{ Transparency = fieldBase.Transparency }
					):Play()
				end
			end)
		end
	end

	if self._domeGlow then
		local glowBase = self._capturedProperties[self._domeGlow]
		if glowBase then
			self._domeGlow.Brightness = glowBase.Brightness + 1.8
			task.delay(0.32, function()
				if self._domeGlow and self._domeGlow.Parent then
					TweenService:Create(
						self._domeGlow,
						TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
						{ Brightness = glowBase.Brightness }
					):Play()
				end
			end)
		end
	end

	return duration
end

function AmbienceController:_eventSilhouetteFlicker()
	local flickerSeconds = randomRange(0.2, 0.4)

	if self._silhouette then
		local base = self._capturedProperties[self._silhouette]
		if base then
			self._silhouette.Transparency = math.max(base.Transparency - 0.22, 0.58)
		end
	end

	if self._silhouetteRim then
		local rimBase = self._capturedProperties[self._silhouetteRim]
		if rimBase then
			self._silhouetteRim.Brightness = rimBase.Brightness + 0.9
		end
	end

	task.delay(flickerSeconds, function()
		if self._silhouette then
			local base = self._capturedProperties[self._silhouette]
			if base then
				self._silhouette.Transparency = base.Transparency
			end
		end

		if self._silhouetteRim then
			local rimBase = self._capturedProperties[self._silhouetteRim]
			if rimBase then
				self._silhouetteRim.Brightness = rimBase.Brightness
			end
		end
	end)

	return flickerSeconds
end

function AmbienceController:_eventEmberGust()
	local duration = 0.9
	if not self._emberEmitter then
		return duration
	end

	local emitterBase = self._capturedProperties[self._emberEmitter]
	if not emitterBase then
		return duration
	end

	local attachment = self._emberEmitter.Parent
	local emitPosition = (attachment and attachment:IsA("Attachment")) and attachment.WorldPosition or Vector3.zero
	local currentCamera = Workspace.CurrentCamera
	local towardCamera = currentCamera and (currentCamera.CFrame.Position - emitPosition) or Vector3.new(0, 0, -1)

	if towardCamera.Magnitude < 1e-3 then
		towardCamera = Vector3.new(0, 0, -1)
	else
		towardCamera = towardCamera.Unit
	end

	self._emberEmitter.Rate = emitterBase.Rate + 24
	self._emberEmitter.Speed = NumberRange.new(16, 24)
	self._emberEmitter.SpreadAngle = Vector2.new(20, 20)
	self._emberEmitter.Acceleration = (towardCamera * 30) + Vector3.new(0, 5, 0)
	self._emberEmitter:Emit(34)

	task.delay(duration, function()
		if self._emberEmitter and self._emberEmitter.Parent then
			self._emberEmitter.Rate = emitterBase.Rate
			self._emberEmitter.Speed = emitterBase.Speed
			self._emberEmitter.Acceleration = emitterBase.Acceleration
			self._emberEmitter.SpreadAngle = emitterBase.SpreadAngle
		end
	end)

	return duration
end

function AmbienceController:_runEvent(eventName)
	if eventName == "Lightning" then
		return self:_eventLightning()
	end

	if eventName == "BarrierSurge" then
		return self:_eventBarrierSurge()
	end

	if eventName == "SilhouetteFlicker" then
		return self:_eventSilhouetteFlicker()
	end

	return self:_eventEmberGust()
end

function AmbienceController:_updateMicroEvents()
	if self._eventBusy then
		return
	end

	if os.clock() < self._nextEventAt then
		return
	end

	local eventName = self:_pickEventName()
	if not eventName then
		self._nextEventAt = os.clock() + randomRange(20, 45)
		return
	end

	self._eventBusy = true
	self._lastEvent = eventName

	local duration = self:_runEvent(eventName)
	self._nextEventAt = os.clock() + duration + randomRange(20, 45)

	task.delay(duration, function()
		self._eventBusy = false
	end)
end

function AmbienceController:_onRender()
	if not self._isRunning then
		return
	end

	local elapsed = os.clock() - self._startTime
	self:_updateFogMotion(elapsed)
	self:_updateBarrierMotion(elapsed)
	self:_updatePostFx(elapsed)
	self:_updateMicroEvents()
end

function AmbienceController:Start()
	if self._isRunning then
		return
	end

	self._isRunning = true
	self._startTime = os.clock()

	self:_resolveSceneReferences()
	self:_createPostFx()
	self:_createAudioBed()

	local existingGrain = Lighting:FindFirstChild("TribulationFilmGrain")
	if existingGrain and existingGrain:IsA("BlurEffect") then
		existingGrain.Size = math.min(existingGrain.Size, 1)
	end

	math.randomseed(math.floor(os.clock() * 100000))
	self._nextEventAt = os.clock() + randomRange(20, 45)

	RunService:UnbindFromRenderStep(RENDER_BIND_NAME)
	RunService:BindToRenderStep(RENDER_BIND_NAME, Enum.RenderPriority.Last.Value, function()
		self:_onRender()
	end)
end

function AmbienceController:_restoreCapturedProperties()
	for instance, properties in pairs(self._capturedProperties) do
		if instance and instance.Parent then
			for propertyName, originalValue in pairs(properties) do
				pcall(function()
					instance[propertyName] = originalValue
				end)
			end
		end
	end
	table.clear(self._capturedProperties)
end

function AmbienceController:Destroy()
	if not self._isRunning then
		return
	end

	self._isRunning = false
	RunService:UnbindFromRenderStep(RENDER_BIND_NAME)

	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	self:_restoreCapturedProperties()

	for _, temporary in ipairs(self._temporaryInstances) do
		if temporary and temporary.Parent then
			temporary:Destroy()
		end
	end
	table.clear(self._temporaryInstances)

	if self._audioFolder then
		self._audioFolder:Destroy()
		self._audioFolder = nil
	end
	table.clear(self._audioLayers)

	if self._postFxGui then
		self._postFxGui:Destroy()
		self._postFxGui = nil
	end

	self._grainLabel = nil
	self._fogNear = nil
	self._fogFar = nil
	self._barrierField = nil
	self._barrierRing = nil
	self._silhouette = nil
	self._domeGlow = nil
	self._silhouetteRim = nil
	self._firePart = nil
	self._emberEmitter = nil
end

return AmbienceController
