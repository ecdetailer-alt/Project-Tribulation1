local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Menu")
local requestRemote = remotesFolder:WaitForChild("TeleportRequest")
local feedbackRemote = remotesFolder:WaitForChild("TeleportFeedback")

local TeleportClient = {}
TeleportClient.__index = TeleportClient

function TeleportClient.new(signalBus)
	local self = setmetatable({}, TeleportClient)
	self._signalBus = signalBus
	self._feedbackConnection = feedbackRemote.OnClientEvent:Connect(function(payload)
		if self._signalBus then
			self._signalBus:Fire("MenuStatus", payload)
		end
	end)
	return self
end

function TeleportClient:Request(destinationKey)
	if type(destinationKey) ~= "string" then
		return false, "Invalid destination request."
	end

	local success, errorMessage = pcall(function()
		requestRemote:FireServer(destinationKey)
	end)

	if not success then
		return false, string.format("Teleport request failed to send: %s", tostring(errorMessage))
	end

	return true
end

function TeleportClient:Destroy()
	if self._feedbackConnection then
		self._feedbackConnection:Disconnect()
		self._feedbackConnection = nil
	end
end

return TeleportClient
