local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local menuFolder = ReplicatedStorage:WaitForChild("Menu")
local MenuConfig = require(menuFolder:WaitForChild("MenuConfig"))
local MenuSignals = require(menuFolder:WaitForChild("MenuSignals"))

local signals = MenuSignals.getShared()
local camera = Workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = MenuConfig.Camera.FieldOfView

local transitionValue = Instance.new("CFrameValue")
local impactMagnitude = 0
local impactTimeLeft = 0
local renderStepName = "TribulationMenuCamera"

local function findPart(partName)
	if type(partName) ~= "string" or partName == "" then
		return nil
	end

	local found = Workspace:FindFirstChild(partName, true)
	if found and found:IsA("BasePart") then
		return found
	end
	return nil
end

local function resolveSceneCFrame(sceneId)
	local sceneConfig = MenuConfig.Camera.SceneAnchors[sceneId]
	if not sceneConfig then
		return camera.CFrame
	end

	local cameraPart = findPart(sceneConfig.CameraPart)
	local lookAtPart = findPart(sceneConfig.LookAtPart)
	if cameraPart and lookAtPart then
		return CFrame.lookAt(cameraPart.Position, lookAtPart.Position)
	end

	return CFrame.lookAt(sceneConfig.FallbackPosition, sceneConfig.FallbackLookAt)
end

local function applyScene(sceneId, duration)
	local target = resolveSceneCFrame(sceneId)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local tweenInstance = TweenService:Create(transitionValue, tweenInfo, { Value = target })
	tweenInstance:Play()
end

transitionValue.Value = resolveSceneCFrame(MenuConfig.Scenes.Default)
camera.CFrame = transitionValue.Value

local connections = {}
table.insert(connections, signals:Connect("MenuSceneRequest", function(payload)
	if type(payload) ~= "table" then
		return
	end

	local sceneId = payload.SceneId
	if type(sceneId) ~= "string" then
		return
	end

	local duration = MenuConfig.Camera.TransitionSeconds
	if sceneId == MenuConfig.Scenes.ContinueScene then
		duration = MenuConfig.Camera.BossTransitionSeconds
	end

	applyScene(sceneId, duration)
end))

table.insert(connections, signals:Connect("MenuCameraImpact", function(payload)
	if type(payload) ~= "table" then
		return
	end

	impactMagnitude = payload.Magnitude or 0
	impactTimeLeft = payload.Duration or 0
end))

RunService:BindToRenderStep(renderStepName, Enum.RenderPriority.Camera.Value + 1, function(dt)
	local baseCFrame = transitionValue.Value
	local viewportSize = camera.ViewportSize
	local mouse = UserInputService:GetMouseLocation()

	local normalizedX = ((mouse.X / math.max(viewportSize.X, 1)) - 0.5) * 2
	local normalizedY = ((mouse.Y / math.max(viewportSize.Y, 1)) - 0.5) * 2
	local swayPitch = -normalizedY * MenuConfig.Camera.SwayDegrees
	local swayYaw = -normalizedX * MenuConfig.Camera.SwayDegrees

	local impactPitch = 0
	local impactYaw = 0
	if impactTimeLeft > 0 then
		impactTimeLeft = math.max(impactTimeLeft - dt, 0)
		local decay = math.max(impactTimeLeft * MenuConfig.Camera.ImpactDecay, 0)
		impactPitch = (math.random() - 0.5) * impactMagnitude * decay
		impactYaw = (math.random() - 0.5) * impactMagnitude * decay
	end

	camera.CFrame = baseCFrame * CFrame.Angles(math.rad(swayPitch + impactPitch), math.rad(swayYaw + impactYaw), 0)
end)

script.Destroying:Connect(function()
	RunService:UnbindFromRenderStep(renderStepName)
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	transitionValue:Destroy()
end)
