-- modules/Visuals.lua - camera, ESP, and lighting controls section registration.

local Visuals = {}

function Visuals.register(ctx)
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
    local VisualGroup = group(Tabs.Visuals, "Camera / ESP", "left")
    VisualGroup:AddToggle("ThirdPerson", { Text = "Third person", Default = false, Callback = function(v) LocalPlayer.CameraMaxZoomDistance = 1e9; LocalPlayer.CameraMode = v and Enum.CameraMode.Classic or Enum.CameraMode.LockFirstPerson end })
    VisualGroup:AddSlider("FOV", { Text = "FOV", Min = 10, Max = 120, Default = 80, Rounding = 0, Callback = function(v) Workspace.CurrentCamera.FieldOfView = v end })
    VisualGroup:AddToggle("PlayerESP", { Text = "Player ESP", Default = false, Callback = setPlayerESP })
    VisualGroup:AddToggle("PCLDESP", { Text = "PCLD ESP", Default = false, Callback = setPCLDESP })

    local VisualRight = group(Tabs.Visuals, "Lighting", "right")
    VisualRight:AddButton("Fullbright", function() Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false end)
    VisualRight:AddButton("Low Graphics", function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01; for _, obj in ipairs(Workspace:GetDescendants()) do if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then obj.Enabled = false end end end)
    VisualRight:AddButton("Reset camera", function() Workspace.CurrentCamera.FieldOfView = 80; LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson end)
end

return Visuals

