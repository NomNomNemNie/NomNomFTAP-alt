-- modules/Toys.lua - toy utilities and line color controls section registration.

local Toys = {}

function Toys.register(ctx)
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
    local ToysGroup = group(Tabs.Toys, "Toy Utilities", "left")
    ToysGroup:AddDropdown("InputToy", { Text = "Input guard toy", Values = {"FoodHamburger", "FoodMayonnaise", "FoodBread", "FoodBanana", "PoopPile", "FoodPizzaCheese"}, Default = "FoodHamburger", Callback = function(v) runtime.values.inputToy = v end })
    ToysGroup:AddToggle("InputLagGuard", { Text = "Anti input-lag toy cycle", Default = false, Callback = setInputLagGuard })
    ToysGroup:AddButton("Spawn Blobman", function() spawnToy("CreatureBlobman", (runtime.root and runtime.root.CFrame * CFrame.new(0, 0, -8)) or CFrame.new(), Vector3.zero, 3) end)
    ToysGroup:AddButton("Spawn Tractor", function() spawnToy("TractorGreen", (runtime.root and runtime.root.CFrame * CFrame.new(0, 0, -8)) or CFrame.new(), Vector3.zero, 3) end)
    ToysGroup:AddButton("Clear NomNom toys", clearGucci)

    local ServerGroup = group(Tabs.Toys, "Line Color", "right")
    ServerGroup:AddButton("RGB line pulse", function() safeFire(Remotes.LineColor, ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))), ColorSequenceKeypoint.new(1, Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))) })) end)
    ServerGroup:AddButton("Invisible line", function() safeFire(Remotes.LineColor, ColorSequence.new(Color3.new(0,0,0))) end)
    ServerGroup:AddButton("Return base line", function() safeFire(Remotes.LineColor, ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(230,255,240)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80,150,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)) })) end)
end

return Toys

