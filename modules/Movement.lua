-- modules/Movement.lua - movement and world/player controls section registration.

local Movement = {}

function Movement.register(ctx)
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
    local PlayerGroup = group(Tabs.Player, "Movement", "left")
    PlayerGroup:AddSlider("WalkSpeed", { Text = "WalkSpeed multiplier", Min = 1, Max = 10, Default = 5, Rounding = 0, Callback = function(v) runtime.values.walkSpeed = v end })
    PlayerGroup:AddToggle("ApplyWalkSpeed", { Text = "Apply WalkSpeed", Default = false, Callback = setWalkSpeed })
    PlayerGroup:AddToggle("InfinityJump", { Text = "Infinity Jump", Default = false, Callback = setInfinityJump })
    PlayerGroup:AddButton("Stop velocity", function() local _,_,root = charParts(); stopVelocity(root) end)
    PlayerGroup:AddButton("Perm ragdoll pulse", function() local _,_,root = charParts(); if root then safeFire(Remotes.Ragdoll, root, 1) end end)

    local GameGroup = group(Tabs.Player, "World Tweaks", "right")
    GameGroup:AddToggle("OceanWalk", { Text = "Ocean walk", Default = false, Callback = function(v) local ocean = get({Workspace, "Map", "AlwaysHereTweenedObjects", "Ocean", "Object", "ObjectModel"}, 1); if ocean then for _, p in ipairs(ocean:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = v; p.CanTouch = v; p.CanQuery = v end end end end })
    GameGroup:AddToggle("AntiBarrier", { Text = "Anti Barrier", Default = false, Callback = function(v) local plots = Workspace:FindFirstChild("Plots"); if plots then for i=1,5 do local barrier = plots:FindFirstChild("Plot"..i) and plots["Plot"..i]:FindFirstChild("Barrier"); if barrier then for _, p in ipairs(barrier:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = not v; p.CanQuery = not v end end end end end end })
    GameGroup:AddToggle("AutoCorrectionReset", { Text = "Correction reset on Flying", Default = false, Callback = function(v) runtime.toggles.autoCorrectionReset = v; disconnectKey("autoCorrectionReset"); if v and Remotes.Correction then setKeyConnection("autoCorrectionReset", Remotes.Correction.OnClientEvent:Connect(function(reason) if reason == "Flying" then local char, hum = runtime.character, runtime.humanoid; if hum then hum.Health = 0 end; if char then pcall(function() char:BreakJoints() end) end end end)) end end })
end

return Movement

