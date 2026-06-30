-- modules/Gucci.lua - home, protection, and Gucci/protection controls section registration.

local Gucci = {}

function Gucci.register(ctx)
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
    local HomeLeft = group(Tabs.Home, "Unified Build", "left")
    HomeLeft:AddLabel("Standalone synthesized script; no lazy source-pack buttons, no encoded chunk table, and no payload loader.")
    HomeLeft:AddLabel("Base UX: The Wourld Obsidian style. Integrated features: Wourld protection + NoName grab/player/visuals + XOCO Gucci/defense/toys.")
    HomeLeft:AddButton("Local test notification", function() notify("NomNom", "Unified script is active", 1) end)

    local HomeRight = group(Tabs.Home, "Runtime", "right")
    HomeRight:AddButton("Refresh character cache", function() refreshCharacter(LocalPlayer.Character); notify("Runtime", "Character cache refreshed", 1) end)
    HomeRight:AddButton("Rerun cleanup", function() runtime.cleanup() end)

    local ProtectMain = group(Tabs.Protection, "Verified Protection", "left")
    ProtectMain:AddToggle("VerifiedProtection", { Text = "Verified Anti-Grab / Struggle", Default = false, Callback = function(v) if v then runtime.startVerifiedProtection() else stopVerifiedProtection() end end })
    ProtectMain:AddToggle("AntiSeatSteal", { Text = "Anti steal-seat", Default = true, Callback = function(v) runtime.toggles.antiSeatSteal = v end })
    ProtectMain:AddToggle("AntiMassless", { Text = "Anti massless / blob physics", Default = true, Callback = function(v) runtime.toggles.antiMassless = v end })
    ProtectMain:AddToggle("RecoveryLock", { Text = "Recovery lock", Default = false, Callback = function(v) runtime.toggles.recoveryLock = v; local _,_,root=charParts(); if root then root.Anchored = v end end })
    ProtectMain:AddToggle("AntiBlob", { Text = "Anti Blob / Drop Aura", Default = false, Callback = setAntiBlob })
    ProtectMain:AddToggle("AntiPaint", { Text = "Anti Paint", Default = false, Callback = setAntiPaint })
    ProtectMain:AddToggle("AntiBurn", { Text = "Anti Burn", Default = false, Callback = setAntiBurn })
    ProtectMain:AddToggle("NoVoidDespawn", { Text = "No void despawn", Default = true, Callback = function(v) runtime.toggles.noVoidDespawn = v; Workspace.FallenPartsDestroyHeight = v and -1000000000 or -100 end })

    local GucciGroup = group(Tabs.Protection, "Gucci / Anti-Kick", "right")
    GucciGroup:AddDropdown("GucciToy", { Text = "Gucci toy", Values = {"TractorGreen", "CreatureBlobman"}, Default = "TractorGreen", Callback = function(v) runtime.values.gucciToy = v end })
    GucciGroup:AddButton("Bind Gucci now", function() buildGucciToy(false) end)
    GucciGroup:AddToggle("AutoGucci", { Text = "Auto Gucci watchdog", Default = false, Callback = startAutoGucci })
    GucciGroup:AddToggle("AntiDestroy", { Text = "Anti-destroy stabilizer", Default = false, Callback = setAntiDestroy })
    GucciGroup:AddToggle("HighPatrol", { Text = "High/safe patrol", Default = false, Callback = setHighPatrol })
    GucciGroup:AddDropdown("AntiKickToy", { Text = "Anti-kick item", Values = {"SpookyCandle1", "JapaneseLantern", "SprayCanWD"}, Default = "SpookyCandle1", Callback = function(v) runtime.values.antiKickToy = v end })
    GucciGroup:AddToggle("AntiKickItem", { Text = "Anti-kick item attach", Default = false, Callback = setAntiKickItem })
    GucciGroup:AddButton("Delete Legs", deleteLegs)
end

return Gucci

