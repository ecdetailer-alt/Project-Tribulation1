local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local MenuConfig = require(ReplicatedStorage:WaitForChild("Menu"):WaitForChild("MenuConfig"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Menu")
local requestRemote = remotesFolder:WaitForChild("TeleportRequest")
local feedbackRemote = remotesFolder:WaitForChild("TeleportFeedback")

local function sendFeedback(player, text, isError)
	feedbackRemote:FireClient(player, {
		Text = text,
		IsError = isError == true,
	})
end

local function getDestination(destinationKey)
	if type(destinationKey) ~= "string" then
		return nil, "Invalid destination payload."
	end

	local destination = MenuConfig.TeleportDestinations[destinationKey]
	if not destination then
		return nil, string.format("Unknown destination '%s'.", destinationKey)
	end

	local placeId = destination.PlaceId
	if type(placeId) ~= "number" or placeId <= 0 then
		return nil, string.format("Destination '%s' has an invalid PlaceId.", destinationKey)
	end

	return destination
end

requestRemote.OnServerEvent:Connect(function(player, destinationKey)
	local destination, errorMessage = getDestination(destinationKey)
	if not destination then
		sendFeedback(player, errorMessage, true)
		return
	end

	sendFeedback(player, string.format("Teleporting to %s...", destination.DisplayName), false)

	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions:SetTeleportData({
		origin = "Menu",
		destination = destinationKey,
		requestedAt = os.time(),
	})

	local success, teleportError = pcall(function()
		TeleportService:TeleportAsync(destination.PlaceId, { player }, teleportOptions)
	end)

	if not success then
		sendFeedback(player, string.format("Teleport failed: %s", tostring(teleportError)), true)
	end
end)
