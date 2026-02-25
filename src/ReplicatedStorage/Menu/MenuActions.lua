local MenuActions = {
	{
		Id = "ContinueCampaign",
		Label = "Continue (Campaign)",
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
		Id = "Character",
		Label = "Character",
		Kind = "Panel",
		PanelId = "Character",
	},
	{
		Id = "Settings",
		Label = "Settings",
		Kind = "Panel",
		PanelId = "Settings",
	},
}

return MenuActions
