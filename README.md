# Project Tribulation1

## Run with Rojo

1. Start the dev server: `rojo serve default.project.json`
2. In Roblox Studio, open the Rojo plugin and connect to `localhost:34872`

## Cinematic Menu Foundation (Phase 1)

- Client camera controller: `src/StarterPlayer/StarterPlayerScripts/MenuCameraController.lua`
- Scene visual controller: `src/StarterPlayer/StarterPlayerScripts/MenuSceneVisualController.lua`
- Menu UI app: `src/StarterGui/MenuUI/MenuApp.client.lua`
- Menu orchestration: `src/ReplicatedStorage/Menu/MenuController.lua`
- Teleport wrapper: `src/ReplicatedStorage/Menu/TeleportClient.lua`
- Party scaffold client: `src/ReplicatedStorage/Party/PartyClient.lua`
- Party scaffold server: `src/ServerScriptService/PartyServer.server.lua`
- Static menu scene assets: `src/Workspace/*.model.json`

## PlaceId Configuration

Teleport destinations are configured in `src/ReplicatedStorage/Menu/MenuConfig.lua`.
Set `TeleportDestinations.Campaign.PlaceId` and `TeleportDestinations.OpenWorld.PlaceId` to your real target place IDs.

## Scene Behavior

- Default scene: Fire Pit
- Auto shift to Black Fog after 10 seconds idle
- Boss Clash scene triggers on Continue (Campaign) click before teleport
- Camera anchors are Workspace parts:
  - `MenuCam_A_FirePit` / `MenuLookAt_A_FirePit`
  - `MenuCam_B_Fog` / `MenuLookAt_B_Fog`
  - `MenuCam_C_Boss` / `MenuLookAt_C_Boss`
