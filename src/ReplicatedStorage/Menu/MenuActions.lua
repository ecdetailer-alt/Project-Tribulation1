local MenuActions = {
	{
		Id = "PlayCampaign",
		Label = "Play (Campaign)",
		Kind = "Teleport",
		Destination = "Campaign",
	},
	{
		Id = "OpenWorld",
		Label = "Open World",
		Kind = "Teleport",
		Destination = "OpenWorld",
	},
	{
		Id = "Party",
		Label = "Party",
		Kind = "Panel",
		PanelId = "Party",
	},
	{
		Id = "CharacterCustomization",
		Label = "Character Customization",
		Kind = "Panel",
		PanelId = "CharacterCustomization",
	},
	{
		Id = "Settings",
		Label = "Settings",
		Kind = "Panel",
		PanelId = "Settings",
	},
}

return MenuActions
