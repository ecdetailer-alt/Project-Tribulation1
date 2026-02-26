# Project Tribulation1

## Run with Rojo

1. Start the dev server: `rojo serve default.project.json`
2. In Roblox Studio, open the Rojo plugin and connect to `localhost:34872`

## Cinematic Menu Foundation (Phase 1)

- Client camera controller: `src/StarterPlayer/StarterPlayerScripts/MenuCameraController.lua`
- Scene visual controller: `src/StarterPlayer/StarterPlayerScripts/MenuSceneVisualController.lua`
- Menu UI app: `src/StarterGui/MenuUI/MenuApp.client.lua`
- Menu orchestration: `src/ReplicatedStorage/Menu/MenuController.lua`
- Asset pack catalog: `src/ReplicatedStorage/Menu/MenuAssetCatalog.lua`
- Teleport wrapper: `src/ReplicatedStorage/Menu/TeleportClient.lua`
- Party scaffold client: `src/ReplicatedStorage/Party/PartyClient.lua`
- Party scaffold server: `src/ServerScriptService/PartyServer.server.lua`
- Environment bootstrap loader: `src/ServerScriptService/MenuEnvironmentBootstrap.server.lua`
- Static menu scene assets: `src/Workspace/*.model.json`
- Post-processing shader stack assets: `src/Lighting/*.model.json`

## Scene Rigs Added

- `BreachlineSetDress` model (hazard strips, debris, ash emitter attachment)
- `DomeImpactRig` model (impact spark attachment + impact pulse light)
- `CityMegablockCluster` model (extra skyline depth + window glow)
- Fire pit now includes attachment + ember emitter + point light + fire object
- Breach horizon now includes attachment + dust emitter + glow light

## PlaceId Configuration

Teleport destinations are configured in `src/ReplicatedStorage/Menu/MenuConfig.lua`.
Set `TeleportDestinations.Campaign.PlaceId` and `TeleportDestinations.OpenWorld.PlaceId` to your real target place IDs.

## High-Quality Environment Packs

`MenuEnvironmentBootstrap.server.lua` loads curated free Creator Store packs from `MenuAssetCatalog.lua` and places them around the menu skyline.

1. In Studio: `Game Settings -> Security`
2. Enable `Allow Loading Third Party Assets`
3. In `MenuAssetCatalog.lua`, toggle `Enabled = true/false` per pack
4. Test in Play Solo; imported content appears under `Workspace/ImportedMenuAssets`

By default the script strips scripts/modules from imported assets for safety and anchors everything for menu stability.

## Scene Behavior

- Default scene: Fire Pit
- Auto shift to Black Fog after 10 seconds idle
- Boss Clash scene triggers on Continue (Campaign) click before teleport
- Settings panel includes `Hover Scene Switching` toggle
- Camera anchors are Workspace parts:
  - `MenuCam_A_FirePit` / `MenuLookAt_A_FirePit`
  - `MenuCam_B_Fog` / `MenuLookAt_B_Fog`
  - `MenuCam_C_Boss` / `MenuLookAt_C_Boss`
