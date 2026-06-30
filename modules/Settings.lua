-- modules/Settings.lua - cleanup, safety, and keybind controls section registration.

local Settings = {}

function Settings.register(ctx)
    local runtime = ctx.runtime
    local Players = ctx.Players
    local ReplicatedStorage = ctx.ReplicatedStorage
    local RunService = ctx.RunService
    local UserInputService = ctx.UserInputService
    local Lighting = ctx.Lighting
    local Workspace = ctx.Workspace
    local LocalPlayer = ctx.LocalPlayer
    local Remotes = ctx.Remotes
    local Tabs = ctx.Tabs
    local group = ctx.group
    local track = ctx.track
    local trackInstance = ctx.trackInstance
    local disconnectKey = ctx.disconnectKey
    local setKeyConnection = ctx.setKeyConnection
    local spawnTask = ctx.spawnTask
    local notify = ctx.notify
    local get = ctx.get
    local refreshCharacter = ctx.refreshCharacter
    local charParts = ctx.charParts
    local safeFire = ctx.safeFire
    local safeInvoke = ctx.safeInvoke
    local sno = ctx.sno
    local destroyToy = ctx.destroyToy
    local stopVelocity = ctx.stopVelocity
    local checkHome = ctx.checkHome
    local spawnToy = ctx.spawnToy
    local getNearestPlayer = ctx.getNearestPlayer
    local setLoop = ctx.setLoop
    local struggleOnce = ctx.struggleOnce
    local stopVerifiedProtection = ctx.stopVerifiedProtection
    local clearGucci = ctx.clearGucci
    local buildGucciToy = ctx.buildGucciToy
    local startAutoGucci = ctx.startAutoGucci
    local setAntiDestroy = ctx.setAntiDestroy
    local setHighPatrol = ctx.setHighPatrol
    local setAntiPaint = ctx.setAntiPaint
    local setAntiBurn = ctx.setAntiBurn
    local setAntiBlob = ctx.setAntiBlob
    local setWalkSpeed = ctx.setWalkSpeed
    local setInfinityJump = ctx.setInfinityJump
    local setSuperGrab = ctx.setSuperGrab
    local setLineExtend = ctx.setLineExtend
    local setGrabMods = ctx.setGrabMods
    local setAura = ctx.setAura
    local setPlayerESP = ctx.setPlayerESP
    local setPCLDESP = ctx.setPCLDESP
    local setAntiKickItem = ctx.setAntiKickItem
    local setInputLagGuard = ctx.setInputLagGuard
    local teleportMap = ctx.teleportMap
    local deleteLegs = ctx.deleteLegs
    local SettingsGroup = group(Tabs.Settings, "Cleanup / Safety", "left")
    SettingsGroup:AddLabel("No auto public-chat. No public chat startup spam. No pack/lazy payload system.")
    SettingsGroup:AddButton("Disable all loops", function() for key in pairs(runtime.toggles) do runtime.toggles[key] = false end; runtime.cleanup(); notify("NomNom", "Runtime cleaned", 1) end)
    SettingsGroup:AddButton("Refresh remotes/character", function() refreshCharacter(LocalPlayer.Character); notify("NomNom", "Refreshed", 1) end)

    local KeyGroup = group(Tabs.Settings, "Keybinds", "right")
    KeyGroup:AddKeyPicker("GucciKey", { Text = "Bind Gucci key", Default = "J", Callback = function() buildGucciToy(false) end })
    KeyGroup:AddKeyPicker("PlatformKey", { Text = "High safe platform key", Default = "X", Callback = function() local _,_,root = charParts(); if not root then return end; if not runtime.platform then local p = Instance.new("Part"); p.Name = "NomNomSkyBase"; p.Size = Vector3.new(800,2,800); p.Anchored = true; p.CFrame = CFrame.new(0, 1000000, 0); p.Parent = Workspace; runtime.platform = trackInstance(p) end; runtime.platformSaved = runtime.platformSaved or root.CFrame; if (root.Position - runtime.platform.Position).Magnitude > 100 then root.CFrame = runtime.platform.CFrame + Vector3.new(0,5,0) else root.CFrame = runtime.platformSaved; runtime.platformSaved = nil end end })

    notify("NomNom FTAP Alt", "Unified Wourld-style script loaded", 5)
end

return Settings

