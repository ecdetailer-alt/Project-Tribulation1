local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local RemoteNames = require(Shared:WaitForChild("RemoteNames"))

local function getOrCreateInstance(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end

	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local remotesFolder = getOrCreateInstance(ReplicatedStorage, "Folder", RemoteNames.Folder)
local pingRemote = getOrCreateInstance(remotesFolder, "RemoteFunction", RemoteNames.Ping)
local announcementRemote = getOrCreateInstance(remotesFolder, "RemoteEvent", RemoteNames.Announcement)

local function ensureBaseplate()
	local existing = Workspace:FindFirstChild("Baseplate")
	if existing and existing:IsA("BasePart") then
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local baseplate = Instance.new("Part")
	baseplate.Name = "Baseplate"
	baseplate.Anchored = true
	baseplate.Size = Vector3.new(512, 10, 512)
	baseplate.Position = Vector3.new(0, -5, 0)
	baseplate.Material = Enum.Material.Concrete
	baseplate.Color = Color3.fromRGB(91, 154, 76)
	baseplate.TopSurface = Enum.SurfaceType.Smooth
	baseplate.BottomSurface = Enum.SurfaceType.Smooth
	baseplate.Parent = Workspace
	return baseplate
end

local baseplate = ensureBaseplate()

pingRemote.OnServerInvoke = function(player, clientMessage)
	return {
		ok = true,
		project = GameConfig.ProjectName,
		serverTime = os.time(),
		echo = clientMessage,
		player = player.Name,
	}
end

Players.PlayerAdded:Connect(function(player)
	local message = string.format("%s joined the server.", player.Name)
	announcementRemote:FireAllClients(message)
	print(string.format("[Server] %s", message))
end)

print(string.format(
	"[%s] Server bootstrap ready (version %s, debug=%s, baseplateSize=%s)",
	GameConfig.ProjectName,
	GameConfig.Version,
	tostring(GameConfig.Debug),
	tostring(baseplate.Size)
))
