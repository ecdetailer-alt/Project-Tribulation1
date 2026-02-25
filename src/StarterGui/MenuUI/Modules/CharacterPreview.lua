local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CharacterPreview = {}
CharacterPreview.__index = CharacterPreview

local localPlayer = Players.LocalPlayer

local function getIdleAnimationId(character)
	local animate = character:FindFirstChild("Animate")
	if not animate then
		return nil
	end

	local idleFolder = animate:FindFirstChild("idle")
	if not idleFolder then
		return nil
	end

	for _, child in ipairs(idleFolder:GetChildren()) do
		if child:IsA("Animation") and child.AnimationId ~= "" then
			return child.AnimationId
		end
	end

	return nil
end

local function prepareClone(character)
	local previousArchivable = character.Archivable
	character.Archivable = true
	local clone = character:Clone()
	character.Archivable = previousArchivable

	for _, descendant in ipairs(clone:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CastShadow = false
		end
	end

	return clone
end

function CharacterPreview.new(viewportFrame)
	local self = setmetatable({}, CharacterPreview)
	self._viewport = viewportFrame
	self._camera = Instance.new("Camera")
	self._camera.FieldOfView = 34
	self._camera.Parent = viewportFrame
	self._viewport.CurrentCamera = self._camera

	self._connections = {}
	self._renderConnection = nil
	self._characterClone = nil
	self._animationTrack = nil
	self._animation = nil
	self._rotationY = 0
	self._dragging = false
	self._lastDragX = 0
	self._boundPlayer = nil

	return self
end

function CharacterPreview:_clearClone()
	if self._animationTrack then
		self._animationTrack:Stop(0.2)
		self._animationTrack:Destroy()
		self._animationTrack = nil
	end

	if self._animation then
		self._animation:Destroy()
		self._animation = nil
	end

	if self._characterClone then
		self._characterClone:Destroy()
		self._characterClone = nil
	end
end

function CharacterPreview:_updateCamera()
	if not self._characterClone then
		return
	end

	local modelCFrame, modelSize = self._characterClone:GetBoundingBox()
	local focus = modelCFrame.Position + Vector3.new(0, modelSize.Y * 0.18, 0)
	local radius = math.max(modelSize.X, modelSize.Y, modelSize.Z) * 0.95 + 2
	local rotationFrame = CFrame.fromOrientation(0, self._rotationY, 0)
	local offset = rotationFrame:VectorToWorldSpace(Vector3.new(0, 0, radius))

	self._camera.CFrame = CFrame.lookAt(focus + offset, focus)
end

function CharacterPreview:_playIdle(sourceCharacter, cloneCharacter)
	local humanoid = cloneCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local animationId = getIdleAnimationId(sourceCharacter)
	if not animationId then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId

	local success, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if not success then
		animation:Destroy()
		return
	end

	track.Looped = true
	track:Play(0.25)

	self._animation = animation
	self._animationTrack = track
end

function CharacterPreview:SetCharacter(character)
	self:_clearClone()

	if not character then
		return
	end

	local clone = prepareClone(character)
	clone.Parent = self._viewport
	self._characterClone = clone

	self:_playIdle(character, clone)
	self:_updateCamera()
end

function CharacterPreview:BindPlayer(player)
	self._boundPlayer = player
	self:SetCharacter(player.Character)

	table.insert(self._connections, player.CharacterAdded:Connect(function(character)
		self:SetCharacter(character)
	end))

	table.insert(self._connections, self._viewport.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._dragging = true
			self._lastDragX = input.Position.X
		end
	end))

	table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._dragging = false
		end
	end))

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if not self._dragging then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local deltaX = input.Position.X - self._lastDragX
		self._lastDragX = input.Position.X
		self._rotationY -= deltaX * 0.01
		self:_updateCamera()
	end))

	self._renderConnection = RunService.RenderStepped:Connect(function(dt)
		if not self._dragging then
			self._rotationY += dt * 0.16
			self:_updateCamera()
		end
	end)
end

function CharacterPreview:Destroy()
	if self._renderConnection then
		self._renderConnection:Disconnect()
		self._renderConnection = nil
	end

	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	self:_clearClone()

	if self._camera then
		self._camera:Destroy()
		self._camera = nil
	end
end

function CharacterPreview.bindLocalPlayer(self)
	self:BindPlayer(localPlayer)
end

return CharacterPreview
