local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartyConstants = require(ReplicatedStorage:WaitForChild("Party"):WaitForChild("PartyConstants"))
local PartyService = require(script.Parent:WaitForChild("PartyService"))

local partyService = PartyService.new(PartyConstants.MaxPartySize)
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Party")

local createPartyRemote = remotesFolder:WaitForChild("CreatePartyRequest")
local inviteRemote = remotesFolder:WaitForChild("InvitePartyRequest")
local requestStateRemote = remotesFolder:WaitForChild("RequestPartyState")
local stateChangedRemote = remotesFolder:WaitForChild("PartyStateChanged")
local inviteReceivedRemote = remotesFolder:WaitForChild("PartyInviteReceived")

local function sendState(player, infoText, errorText)
	local state = partyService:GetStateForPlayer(player)
	state.Info = infoText
	state.Error = errorText
	stateChangedRemote:FireClient(player, state)
end

local function broadcastStates()
	for _, player in ipairs(Players:GetPlayers()) do
		sendState(player)
	end
end

createPartyRemote.OnServerEvent:Connect(function(player)
	local success, errorText = partyService:CreateParty(player)
	if not success then
		sendState(player, nil, errorText)
		return
	end

	broadcastStates()
	sendState(player, "Party created.", nil)
end)

inviteRemote.OnServerEvent:Connect(function(player, targetUserId)
	if type(targetUserId) ~= "number" then
		sendState(player, nil, "Invite must use a numeric UserId.")
		return
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		sendState(player, nil, "Target player is not in this server.")
		return
	end

	local success, errorText, partySnapshot = partyService:InvitePlayer(player, targetPlayer)
	if not success then
		sendState(player, nil, errorText)
		return
	end

	inviteReceivedRemote:FireClient(targetPlayer, {
		PartyId = partySnapshot.Id,
		FromUserId = player.UserId,
		FromName = player.Name,
	})

	broadcastStates()
	sendState(player, string.format("Invite sent to %s.", targetPlayer.Name), nil)
end)

requestStateRemote.OnServerInvoke = function(player)
	return partyService:GetStateForPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
	partyService:RemovePlayer(player)
	broadcastStates()
end)
