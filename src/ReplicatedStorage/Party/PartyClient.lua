local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Party")
local createPartyRemote = remotesFolder:WaitForChild("CreatePartyRequest")
local inviteRemote = remotesFolder:WaitForChild("InvitePartyRequest")
local requestStateRemote = remotesFolder:WaitForChild("RequestPartyState")
local stateChangedRemote = remotesFolder:WaitForChild("PartyStateChanged")
local inviteReceivedRemote = remotesFolder:WaitForChild("PartyInviteReceived")

local PartyClient = {}
PartyClient.__index = PartyClient

function PartyClient.new(signalBus)
	local self = setmetatable({}, PartyClient)
	self._signalBus = signalBus
	self._connections = {}

	table.insert(self._connections, stateChangedRemote.OnClientEvent:Connect(function(state)
		self._signalBus:Fire("PartyStateUpdated", state)
	end))

	table.insert(self._connections, inviteReceivedRemote.OnClientEvent:Connect(function(payload)
		self._signalBus:Fire("PartyInviteReceived", payload)
	end))

	return self
end

function PartyClient:CreateParty()
	local success, errorMessage = pcall(function()
		createPartyRemote:FireServer()
	end)

	if not success then
		self._signalBus:Fire("MenuStatus", {
			Text = string.format("Create party failed: %s", tostring(errorMessage)),
			IsError = true,
		})
	end
end

function PartyClient:InviteUserId(userId)
	if type(userId) ~= "number" then
		self._signalBus:Fire("MenuStatus", {
			Text = "Invite requires a numeric UserId.",
			IsError = true,
		})
		return
	end

	local success, errorMessage = pcall(function()
		inviteRemote:FireServer(userId)
	end)

	if not success then
		self._signalBus:Fire("MenuStatus", {
			Text = string.format("Invite failed: %s", tostring(errorMessage)),
			IsError = true,
		})
	end
end

function PartyClient:RequestState()
	local success, response = pcall(function()
		return requestStateRemote:InvokeServer()
	end)

	if not success then
		self._signalBus:Fire("MenuStatus", {
			Text = string.format("Party refresh failed: %s", tostring(response)),
			IsError = true,
		})
		return nil
	end

	self._signalBus:Fire("PartyStateUpdated", response)
	return response
end

function PartyClient:Destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

return PartyClient
