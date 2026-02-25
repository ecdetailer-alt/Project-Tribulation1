local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local RemoteNames = require(Shared:WaitForChild("RemoteNames"))

local remotesFolder = ReplicatedStorage:WaitForChild(RemoteNames.Folder)
local pingRemote = remotesFolder:WaitForChild(RemoteNames.Ping)
local announcementRemote = remotesFolder:WaitForChild(RemoteNames.Announcement)

announcementRemote.OnClientEvent:Connect(function(message)
	print(string.format("[Announcement] %s", message))
end)

task.defer(function()
	local ok, response = pcall(function()
		return pingRemote:InvokeServer("Client ready")
	end)

	if not ok then
		warn("[Client] Ping failed:", response)
		return
	end

	print(string.format(
		"[Client] Connected as %s to %s (serverTime=%s)",
		player.Name,
		response.project,
		tostring(response.serverTime)
	))
end)

print(string.format("[%s] Client bootstrap running.", GameConfig.ProjectName))
