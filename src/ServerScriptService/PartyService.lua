local PartyService = {}
PartyService.__index = PartyService

local function copySortedMembers(memberMap)
	local members = {}
	for _, member in pairs(memberMap) do
		table.insert(members, {
			UserId = member.UserId,
			Name = member.Name,
		})
	end

	table.sort(members, function(a, b)
		return a.UserId < b.UserId
	end)

	return members
end

function PartyService.new(maxPartySize)
	local self = setmetatable({}, PartyService)
	self._maxPartySize = maxPartySize
	self._parties = {}
	self._playerToParty = {}
	self._serial = 0
	return self
end

function PartyService:_nextPartyId()
	self._serial += 1
	return string.format("party_%d_%d", os.time(), self._serial)
end

function PartyService:_getPartyByPlayer(player)
	local partyId = self._playerToParty[player.UserId]
	if not partyId then
		return nil
	end

	return self._parties[partyId]
end

function PartyService:_serializeParty(party)
	if not party then
		return nil
	end

	return {
		Id = party.Id,
		LeaderUserId = party.LeaderUserId,
		LeaderName = party.LeaderName,
		MaxSize = self._maxPartySize,
		Members = copySortedMembers(party.Members),
	}
end

function PartyService:_serializePublicParties()
	local parties = {}
	for _, party in pairs(self._parties) do
		local memberCount = 0
		for _ in pairs(party.Members) do
			memberCount += 1
		end

		table.insert(parties, {
			Id = party.Id,
			LeaderUserId = party.LeaderUserId,
			LeaderName = party.LeaderName,
			MemberCount = memberCount,
			MaxSize = self._maxPartySize,
		})
	end

	table.sort(parties, function(a, b)
		return a.Id < b.Id
	end)

	return parties
end

function PartyService:GetStateForPlayer(player)
	return {
		MaxPartySize = self._maxPartySize,
		OwnParty = self:_serializeParty(self:_getPartyByPlayer(player)),
		PublicParties = self:_serializePublicParties(),
	}
end

function PartyService:CreateParty(player)
	if self:_getPartyByPlayer(player) then
		return false, "You are already in a party."
	end

	local partyId = self:_nextPartyId()
	local party = {
		Id = partyId,
		LeaderUserId = player.UserId,
		LeaderName = player.Name,
		Members = {
			[player.UserId] = {
				UserId = player.UserId,
				Name = player.Name,
			},
		},
	}

	self._parties[partyId] = party
	self._playerToParty[player.UserId] = partyId

	return true, nil, self:_serializeParty(party)
end

function PartyService:InvitePlayer(inviter, targetPlayer)
	local party = self:_getPartyByPlayer(inviter)
	if not party then
		local created, createError = self:CreateParty(inviter)
		if not created then
			return false, createError
		end

		party = self:_getPartyByPlayer(inviter)
	end

	if party.LeaderUserId ~= inviter.UserId then
		return false, "Only the party leader can send invites."
	end

	if self:_getPartyByPlayer(targetPlayer) then
		return false, "That player is already in a party."
	end

	local memberCount = 0
	for _ in pairs(party.Members) do
		memberCount += 1
	end

	if memberCount >= self._maxPartySize then
		return false, "Party is full."
	end

	if targetPlayer.UserId == inviter.UserId then
		return false, "You cannot invite yourself."
	end

	return true, nil, self:_serializeParty(party)
end

function PartyService:RemovePlayer(player)
	local party = self:_getPartyByPlayer(player)
	if not party then
		return
	end

	party.Members[player.UserId] = nil
	self._playerToParty[player.UserId] = nil

	local nextLeader
	for _, member in pairs(party.Members) do
		nextLeader = member
		break
	end

	if not nextLeader then
		self._parties[party.Id] = nil
		return
	end

	party.LeaderUserId = nextLeader.UserId
	party.LeaderName = nextLeader.Name
end

return PartyService
