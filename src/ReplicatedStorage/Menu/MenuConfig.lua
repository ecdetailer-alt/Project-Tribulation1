local MenuConfig = {
	GameName = "Tribulation",
	MaxPartySize = 4,
	Cinematics = {
		DefaultScene = "FirePit",
		BreathingFrequency = 0.55,
	},
	-- Replace these with your actual destination PlaceIds.
	TeleportDestinations = {
		Campaign = {
			DisplayName = "Campaign",
			PlaceId = game.PlaceId,
		},
		OpenWorld = {
			DisplayName = "Open World",
			PlaceId = game.PlaceId,
		},
	},
}

return MenuConfig
