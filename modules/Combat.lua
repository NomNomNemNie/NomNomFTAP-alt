-- modules/Combat.lua - combat, grab, line, and aura controls section registration.

local Combat = {}

function Combat.register(ctx)
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
    local GrabGroup = group(Tabs.Combat, "Grab / Line", "left")
    GrabGroup:AddSlider("FlingPower", { Text = "Fling power", Min = 600, Max = 10000, Default = 600, Rounding = 0, Callback = function(v) runtime.values.flingPower = v end })
    GrabGroup:AddToggle("SuperGrab", { Text = "Super Strength (RMB)", Default = false, Callback = setSuperGrab })
    GrabGroup:AddToggle("LineExtend", { Text = "Infinity Line Extend", Default = false, Callback = setLineExtend })
    GrabGroup:AddSlider("LineStep", { Text = "Line extend step", Min = 1, Max = 10, Default = 7, Rounding = 0, Callback = function(v) runtime.values.lineDistanceStep = v end })
    GrabGroup:AddToggle("GrabMods", { Text = "Massless / responsiveness mods", Default = false, Callback = setGrabMods })
    GrabGroup:AddSlider("LineResponsiveness", { Text = "Grab responsiveness", Min = 1, Max = 200, Default = 30, Rounding = 0, Callback = function(v) runtime.values.lineResponsiveness = v end })
    GrabGroup:AddToggle("SpinGrab", { Text = "Spin Grab", Default = false, Callback = function(v) runtime.toggles.spinGrab = v end })
    GrabGroup:AddToggle("RagdollGrab", { Text = "Ragdoll Grab", Default = false, Callback = function(v) runtime.toggles.ragdollGrab = v end })

    local AuraGroup = group(Tabs.Combat, "Auras / Target", "right")
    AuraGroup:AddSlider("AuraRange", { Text = "Aura range", Min = 10, Max = 80, Default = 40, Rounding = 0, Callback = function(v) runtime.values.auraRange = v end })
    AuraGroup:AddToggle("ClickAura", { Text = "Click/Network Aura", Default = false, Callback = function(v) setAura("ClickAura", v, function(_, root) sno(root) end) end })
    AuraGroup:AddToggle("FlingAura", { Text = "Fling Aura", Default = false, Callback = function(v) setAura("FlingAura", v, function(_, root) sno(root); local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bv.Velocity = (runtime.root and runtime.root.CFrame.LookVector or Vector3.zAxis) * runtime.values.flingPower; bv.Parent = root; game:GetService("Debris"):AddItem(bv, 0.25) end) end })
    AuraGroup:AddButton("Bring nearest with blob", function() local target = getNearestPlayer(80); if not target then return end; local inv = runtime.inventory; local blob = inv and inv:FindFirstChild("CreatureBlobman"); local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart"); if blob and root and blob:FindFirstChild("BlobmanSeatAndOwnerScript") and blob:FindFirstChild("RightDetector") then pcall(function() blob.BlobmanSeatAndOwnerScript.CreatureGrab:FireServer(blob.RightDetector, root, blob.RightDetector.RightWeld) end) end end)
    AuraGroup:AddButton("Drop nearest blob hold", function() local target = getNearestPlayer(80); if not target then return end; local inv = runtime.inventory; local blob = inv and inv:FindFirstChild("CreatureBlobman"); local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart"); if blob and root and blob:FindFirstChild("BlobmanSeatAndOwnerScript") and blob:FindFirstChild("RightDetector") then pcall(function() blob.BlobmanSeatAndOwnerScript.CreatureDrop:FireServer(blob.RightDetector.RightWeld, root) end) end end)
end

return Combat

