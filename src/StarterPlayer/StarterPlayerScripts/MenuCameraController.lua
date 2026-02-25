local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MenuFolder = ReplicatedStorage:WaitForChild("Menu")
local CameraScenes = require(MenuFolder:WaitForChild("CameraScenes"))
local MenuConfig = require(MenuFolder:WaitForChild("MenuConfig"))
local SignalBus = require(MenuFolder:WaitForChild("SignalBus"))

local localPlayer = Players.LocalPlayer

local MenuCameraController = {}
MenuCameraController.__index = MenuCameraController

local function easeInOutSine(alpha)
	return -(math.cos(math.pi * alpha) - 1) / 2
end

local function resolveScene(sceneId)
	return CameraScenes[sceneId] or CameraScenes[MenuConfig.Cinematics.DefaultScene]
end

function MenuCameraController.new()
	local self = setmetatable({}, MenuCameraController)
	self._signalBus = SignalBus.getShared()
	self._connections = {}
	self._scene = nil
	self._sceneTime = 0
	self._shakeStrength = 0
	self._shakeFadePerSecond = 0
	self._controls = nil
	self._started = false
	self._camera = Workspace.CurrentCamera
	self._previousCameraType = nil
	self._previousFieldOfView = nil
	return self
end

function MenuCameraController:_setMovementLocked(locked)
	local playerScripts = localPlayer:FindFirstChild("PlayerScripts")
	if not playerScripts then
		return
	end

	local playerModule = playerScripts:FindFirstChild("PlayerModule")
	if not playerModule then
		return
	end

	local ok, playerModuleResult = pcall(require, playerModule)
	if not ok then
		return
	end

	local controls = playerModuleResult:GetControls()
	self._controls = controls

	if locked then
		controls:Disable()
	else
		controls:Enable()
	end
end

function MenuCameraController:_applyScene(sceneId)
	self._scene = resolveScene(sceneId)
	self._sceneTime = 0
	self._camera.FieldOfView = self._scene.Fov
end

function MenuCameraController:TriggerShake(magnitude, duration)
	local safeMagnitude = math.max(0, tonumber(magnitude) or 0.3)
	local safeDuration = math.max(0.05, tonumber(duration) or 0.45)
	self._shakeStrength = math.max(self._shakeStrength, safeMagnitude)
	self._shakeFadePerSecond = self._shakeStrength / safeDuration
end

function MenuCameraController:_update(dt)
	if not self._scene then
		return
	end

	self._sceneTime += dt
	local scene = self._scene

	local panAlpha = math.clamp(self._sceneTime / scene.PanDuration, 0, 1)
	local panT = easeInOutSine(panAlpha)
	local basePosition = scene.StartPosition:Lerp(scene.EndPosition, panT)
	local lookAtPosition = scene.LookAtStart:Lerp(scene.LookAtEnd, panT)

	local swayPhase = self._sceneTime * scene.SwayFrequency * math.pi * 2
	local swayOffset = Vector3.new(
		math.sin(swayPhase) * scene.SwayAmplitude.X,
		math.sin(swayPhase * 0.5) * scene.SwayAmplitude.Y,
		math.sin(swayPhase * 0.25) * scene.SwayAmplitude.Z
	)

	self._shakeStrength = math.max(0, self._shakeStrength - self._shakeFadePerSecond * dt)
	local shakeOffset = Vector3.zero
	if self._shakeStrength > 0 then
		shakeOffset = Vector3.new(
			(math.noise(self._sceneTime * 11, 0, 0) - 0.5) * 2,
			(math.noise(0, self._sceneTime * 13, 0) - 0.5) * 2,
			(math.noise(0, 0, self._sceneTime * 17) - 0.5) * 2
		) * self._shakeStrength * scene.ShakeScale
	end

	self._camera.CFrame = CFrame.lookAt(basePosition + swayOffset + shakeOffset, lookAtPosition)
	self._camera.FieldOfView = scene.Fov
end

function MenuCameraController:Start()
	if self._started then
		return
	end

	self._started = true
	self._camera = Workspace.CurrentCamera
	self._previousCameraType = self._camera.CameraType
	self._previousFieldOfView = self._camera.FieldOfView

	self:_setMovementLocked(true)
	self._camera.CameraType = Enum.CameraType.Scriptable
	self:_applyScene(MenuConfig.Cinematics.DefaultScene)

	table.insert(self._connections, self._signalBus:Connect("MenuSceneSelected", function(payload)
		local sceneId = payload and payload.SceneId
		if type(sceneId) == "string" then
			self:_applyScene(sceneId)
		end
	end))

	table.insert(self._connections, self._signalBus:Connect("MenuLightningStrike", function(payload)
		local magnitude = payload and payload.Magnitude or 0.3
		local duration = payload and payload.Duration or 0.45
		self:TriggerShake(magnitude, duration)
	end))

	table.insert(self._connections, RunService.RenderStepped:Connect(function(dt)
		self:_update(dt)
	end))
end

function MenuCameraController:Destroy()
	if not self._started then
		return
	end

	self._started = false

	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	self:_setMovementLocked(false)

	if self._camera then
		self._camera.CameraType = self._previousCameraType or Enum.CameraType.Custom
		self._camera.FieldOfView = self._previousFieldOfView or 70
	end
end

return MenuCameraController
