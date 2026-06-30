-- modules/Teleports.lua - map and player teleport controls section registration.

local Teleports = {}

function Teleports.register(ctx)
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
    local MapGroup = group(Tabs.Teleports, "Map", "left")
    MapGroup:AddDropdown("MapPoint", { Text = "House", Values = {"Green House", "Pink House", "Witch House", "Blue House", "China House"}, Default = "Green House", Callback = function(v) runtime.values.selectedMap = v end })
    MapGroup:AddButton("Teleport selected", teleportMap)
    MapGroup:AddToggle("Loop selected teleport", { Text = "Loop selected map point", Default = false, Callback = function(v) setLoop("loopMap", v, teleportMap, 0.15) end })
    MapGroup:AddToggle("Random house patrol", { Text = "Random house patrol", Default = false, Callback = function(v) runtime.toggles.randomPatrol = v; disconnectKey("randomPatrol"); if v then setKeyConnection("randomPatrol", RunService.Heartbeat:Connect(function() if math.random() < 0.02 then local keys = {"Green House", "Pink House", "Witch House", "Blue House", "China House"}; runtime.values.selectedMap = keys[math.random(#keys)]; teleportMap() end end)) end end })

    local TargetGroup = group(Tabs.Teleports, "Players", "right")
    TargetGroup:AddButton("Teleport to nearest", function() local target = getNearestPlayer(500); local _,_,root = charParts(); local tr = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart"); if root and tr then root.CFrame = tr.CFrame * CFrame.new(0,0,3) end end)
    TargetGroup:AddButton("Bring nearest network", function() local target = getNearestPlayer(80); local tr = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart"); if tr then sno(tr) end end)
end

return Teleports

