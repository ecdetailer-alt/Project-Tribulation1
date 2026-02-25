local MenuConfig = {
	GameName = "Tribulation",
	MaxPartySize = 4,
	Cinematics = {
		DefaultScene = "FirePit",
		IdleShiftScene = "BlackFogHorizon",
		IdleShiftSeconds = 10,
		PlayClickScene = "BossClashFreezeFrame",
		SceneCPreTeleportDelay = 1.05,
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
	SceneAnchors = {
		FirePit = {
			CameraPart = "MenuCam_A_FirePit",
			LookAtPart = "MenuLookAt_A_FirePit",
		},
		BlackFogHorizon = {
			CameraPart = "MenuCam_B_Fog",
			LookAtPart = "MenuLookAt_B_Fog",
		},
		BossClashFreezeFrame = {
			CameraPart = "MenuCam_C_Boss",
			LookAtPart = "MenuLookAt_C_Boss",
		},
	},
}

return MenuConfig
