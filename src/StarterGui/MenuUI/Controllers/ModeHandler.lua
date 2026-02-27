local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local ModeHandler = {}
ModeHandler.__index = ModeHandler

function ModeHandler.new(options)
	options = options or {}

	local self = setmetatable({}, ModeHandler)
	self._player = options.Player
	self._statusCallback = options.OnStatus
	self._placeIds = options.PlaceIds or {
		Campaign = 0,
		OpenWorld = 0,
	}

	return self
end

function ModeHandler:SetStatusCallback(callback)
	self._statusCallback = callback
end

function ModeHandler:_status(text, isError)
	if self._statusCallback then
		self._statusCallback(text, isError)
	end
end

function ModeHandler:HandleMenuAction(actionId)
	if actionId == "Party" then
		self:_status("Party menu placeholder selected.", false)
		return
	end

	if actionId == "Settings" then
		self:_status("Settings menu placeholder selected.", false)
		return
	end

	self:_status("Unknown menu action: " .. tostring(actionId), true)
end

function ModeHandler:SelectMode(modeId)
	local placeId = self._placeIds[modeId]
	if type(placeId) ~= "number" or placeId <= 0 then
		self:_status(modeId .. " selected (placeholder - set PlaceId in ModeHandler).", false)
		warn(string.format("[ModeHandler] %s PlaceId is not configured.", modeId))
		return false
	end

	if RunService:IsStudio() then
		self:_status(modeId .. " selected (teleport disabled in Studio play session).", false)
		return false
	end

	if not self._player then
		self:_status("Cannot teleport: player unavailable.", true)
		return false
	end

	self:_status("Deploying to " .. modeId .. "...", false)
	local ok, err = pcall(function()
		TeleportService:Teleport(placeId, self._player)
	end)

	if not ok then
		self:_status("Teleport failed: " .. tostring(err), true)
		return false
	end

	return true
end

return ModeHandler
