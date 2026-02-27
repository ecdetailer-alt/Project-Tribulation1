local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CAMERA_BIND_NAME = "TribulationMenuCameraControllerV2"

local CameraController = {}
CameraController.__index = CameraController

local function findPartByNames(names)
	for _, name in ipairs(names) do
		local found = Workspace:FindFirstChild(name, true)
		if found and found:IsA("BasePart") then
			return found
		end
	end
	return nil
end

local function getFocusPosition(character)
	local head = character and character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head.Position + Vector3.new(0, 0.45, 0)
	end

	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position + Vector3.new(0, 2.5, 0)
	end

	return Vector3.new(0, 6, 0)
end

local function ensureAnchorPart(anchorName)
	local existing = Workspace:FindFirstChild(anchorName, true)
	if existing and existing:IsA("BasePart") then
		return existing, false
	end

	local anchor = Instance.new("Part")
	anchor.Name = anchorName
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(4, 1, 4)

	local deck = findPartByNames({ "BreachlineDeck", "Baseplate" })
	if deck then
		local deckTop = deck.Position.Y + (deck.Size.Y * 0.5)
		anchor.CFrame = CFrame.new(
			deck.Position.X,
			deckTop + 2.5,
			deck.Position.Z + math.min(deck.Size.Z * 0.26, 46)
		)
	else
		anchor.CFrame = CFrame.new(0, 6, 44)
	end

	anchor.Parent = Workspace
	return anchor, true
end

function CameraController.new(options)
	options = options or {}

	local self = setmetatable({}, CameraController)
	self._player = Players.LocalPlayer
	self._camera = Workspace.CurrentCamera
	self._connections = {}
	self._isRunning = false
	self._startTime = 0
	self._currentCFrame = nil

	self._anchorName = options.AnchorName or "MenuCharacterAnchor"
	self._lookPartNames = options.LookPartNames or { "DomeField", "BreachHorizon", "FogSheet" }
	self._fieldOfView = options.FieldOfView or 67

	self._anchorPart = nil
	self._createdAnchorPart = false
	self._character = nil
	self._characterRoot = nil

	self._savedCameraType = nil
	self._savedCameraSubject = nil
	self._savedFieldOfView = nil
	self._savedRootAnchored = nil
	self._savedAutoRotate = nil

	return self
end

function CameraController:_restoreCharacterLock()
	if self._characterRoot and self._characterRoot.Parent then
		if self._savedRootAnchored ~= nil then
			self._characterRoot.Anchored = self._savedRootAnchored
		else
			self._characterRoot.Anchored = false
		end
	end

	local humanoid = self._character and self._character:FindFirstChildOfClass("Humanoid")
	if humanoid and self._savedAutoRotate ~= nil then
		humanoid.AutoRotate = self._savedAutoRotate
	end

	self._characterRoot = nil
	self._savedRootAnchored = nil
	self._savedAutoRotate = nil
end

function CameraController:_bindCharacter(character)
	if not character then
		return
	end

	self:_restoreCharacterLock()
	self._character = character

	local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
	if not root or not root:IsA("BasePart") then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local anchorPart = self._anchorPart
	local lookAtPart = findPartByNames(self._lookPartNames)

	local anchorPosition = anchorPart and anchorPart.Position or root.Position
	local fallbackLook = anchorPosition + Vector3.new(0, 0, 120)
	local lookPosition = lookAtPart and lookAtPart.Position or fallbackLook
	root.CFrame = CFrame.lookAt(anchorPosition, Vector3.new(lookPosition.X, anchorPosition.Y + 1.5, lookPosition.Z))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	self._savedRootAnchored = root.Anchored
	root.Anchored = true
	self._characterRoot = root

	if humanoid then
		self._savedAutoRotate = humanoid.AutoRotate
		humanoid.AutoRotate = false
	end
end

function CameraController:_onRender(dt)
	if not self._isRunning then
		return
	end

	local camera = self._camera or Workspace.CurrentCamera
	if not camera then
		return
	end

	local root = self._characterRoot
	if not root or not root.Parent then
		return
	end

	local elapsed = os.clock() - self._startTime
	local rootCFrame = root.CFrame
	local rootPosition = root.Position

	local sideDolly = math.sin(elapsed * 0.11) * 1.1
	local dollyInOut = math.sin(elapsed * 0.07 + 1.3) * 0.9
	local rise = math.sin(elapsed * 0.19 + 0.6) * 0.35

	local cameraPosition = rootPosition
		- (rootCFrame.LookVector * (14.5 + dollyInOut))
		- (rootCFrame.RightVector * (3.2 - sideDolly))
		+ Vector3.new(0, 5.4 + rise, 0)

	local lookPosition = getFocusPosition(self._character) + (rootCFrame.LookVector * 8)
	local pitch = math.rad(math.sin(elapsed * 0.16 + 0.2) * 0.26)
	local yaw = math.rad(math.sin(elapsed * 0.2 + 0.9) * 0.35)

	local targetCFrame = CFrame.lookAt(cameraPosition, lookPosition) * CFrame.Angles(pitch, yaw, 0)
	local blendAlpha = math.clamp(dt * 1.8, 0, 1)

	if not self._currentCFrame then
		self._currentCFrame = targetCFrame
	else
		self._currentCFrame = self._currentCFrame:Lerp(targetCFrame, blendAlpha)
	end

	camera.CFrame = self._currentCFrame
	camera.Focus = CFrame.new(lookPosition)
end

function CameraController:Start()
	if self._isRunning then
		return
	end

	self._camera = Workspace.CurrentCamera
	if not self._camera then
		return
	end

	self._isRunning = true
	self._startTime = os.clock()
	self._currentCFrame = nil

	self._savedCameraType = self._camera.CameraType
	self._savedCameraSubject = self._camera.CameraSubject
	self._savedFieldOfView = self._camera.FieldOfView

	self._camera.CameraType = Enum.CameraType.Scriptable
	self._camera.FieldOfView = self._fieldOfView

	self._anchorPart, self._createdAnchorPart = ensureAnchorPart(self._anchorName)
	self:_bindCharacter(self._player.Character or self._player.CharacterAdded:Wait())

	table.insert(self._connections, self._player.CharacterAdded:Connect(function(character)
		self:_bindCharacter(character)
	end))

	RunService:UnbindFromRenderStep(CAMERA_BIND_NAME)
	RunService:BindToRenderStep(CAMERA_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt)
		self:_onRender(dt)
	end)
end

function CameraController:Destroy()
	if not self._isRunning then
		return
	end

	self._isRunning = false
	RunService:UnbindFromRenderStep(CAMERA_BIND_NAME)

	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	self:_restoreCharacterLock()

	if self._camera then
		if self._savedCameraType ~= nil then
			self._camera.CameraType = self._savedCameraType
		end

		if self._savedFieldOfView ~= nil then
			self._camera.FieldOfView = self._savedFieldOfView
		end

		if self._savedCameraSubject ~= nil then
			self._camera.CameraSubject = self._savedCameraSubject
		end
	end

	if self._createdAnchorPart and self._anchorPart and self._anchorPart.Parent then
		self._anchorPart:Destroy()
	end

	self._anchorPart = nil
	self._character = nil
	self._camera = nil
	self._currentCFrame = nil
end

return CameraController
