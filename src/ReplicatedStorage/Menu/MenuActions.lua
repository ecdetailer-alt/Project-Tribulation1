local MenuConfig = require(script.Parent:WaitForChild("MenuConfig"))

local MenuActions = {}

function MenuActions.Execute(actionId, controller)
	if actionId == "Continue" then
		controller:SetStatus("Continue selected", false)
		controller:RequestScene(MenuConfig.Scenes.ContinueScene, "continue")
		controller:Emit("MenuContinueClicked", {
			ActionId = actionId,
		})
		controller:Emit("MenuCameraImpact", {
			Magnitude = 0.55,
			Duration = 0.2,
		})
		return
	end

	if actionId == "OpenWorld" then
		controller:SetStatus("Open World selected", false)
		return
	end

	if actionId == "Party" then
		controller:SetStatus("Party selected", false)
		return
	end

	if actionId == "Character" then
		controller:SetStatus("Character selected", false)
		return
	end

	if actionId == "Settings" then
		local enabled = controller:ToggleHoverSceneSwitching()
		controller:SetStatus(enabled and "Hover scene switching: ON" or "Hover scene switching: OFF", false)
	end
end

return MenuActions
