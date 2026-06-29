--[[
    NomNom FTAP — Roo Consolidated Build
    Standalone Xeno-style Luau script for owned/private FTAP testing.

    Synthesized from Source_RooClone_20260629-183754 and previous NomNomFTAP build:
    - one Rayfield UI path
    - rerun cleanup key
    - tracked connections/instances
    - movement/QoL controls
    - local ESP/debug overlays
    - custom local chat overlay
    - guarded FTAP toy/vehicle helpers
    - rate-limited protection toggles
    - bundled from maintainable src modules/reference layout
    - Extreme Map Patrol / Map Orbit Guard with safe-Y clamping
    - ChildAdded spawn wait, Fast Verify, recovery lock, authorized cleanup/counter-response gates

    Notes:
    - Server-side game state depends on your owned/private place mechanics.
    - Player-affecting test helpers are gated by whitelist/authorized target mode.
]]

local CLEANUP_KEY = "__NomNomFTAP_RooCleanup_V1"
if getgenv and getgenv()[CLEANUP_KEY] then
    pcall(getgenv()[CLEANUP_KEY])
end

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// State
local State = {
    Enabled = true,
    Connections = {},
    Instances = {},
    Threads = {},
    ESP = {},
    ChatHistory = {},
    Whitelist = {},
    SelectedTarget = nil,
    SelectedToy = "DiceBig",
    FlingToy = nil,
    FlingConn = nil,
    LastRemote = {},

    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    AntiVoid = false,
    AntiVoidY = -100,
    AntiRagdoll = false,
    AntiGrab = false,
    AntiFire = false,
    AntiExplode = false,
    AntiLag = false,
    ESPEnabled = false,
    ESPNames = true,
    ESPDistance = true,
    ESPRainbow = false,
    ESPColor = Color3.fromRGB(80, 255, 150),
    ChatEnabled = false,
    MasslessGrab = false,
    MasslessSense = 40,
    SuperFling = false,
    SuperFlingStrength = 850,
    UFOFollow = false,
    UFOSpin = false,
    UFOSpinSpeed = 5,
    UFOSpinRadius = 14,
    UFOHeight = 7,
    AuthorizedTargetsOnly = true,
    LoopFling = false,
    LoopFlingCooldown = 0.75,

    AuthorizedCounterResponse = false,
    AuthorizedCleanupCooldown = 7,
    AuthorizedCounterCooldown = 6,
    LastAuthorizedCounterResponse = 0,

    GucciGuardEnabled = false,
    GucciGuardMode = "Adaptive High Vault",
    GucciGuardToy = "Auto",
    GucciGuardDistance = 10,
    GucciGuardHeight = 85,
    GucciGuardMaxHeight = 250,
    GucciGuardCheckRate = 0.25,
    GucciGuardMaintainRate = 0.35,
    GucciGuardSpawnCooldown = 2.5,
    GucciGuardSpawnTimeout = 3.5,
    GucciGuardFastVerifyWindow = 1.25,
    GucciGuardFastVerifyInterval = 0.08,
    GucciPatrolEnabled = true,
    GucciPatrolIntensity = 1.25,
    GucciPatrolSafeMinY = 35,
    GucciPatrolVaultHeight = 135,
    GucciPatrolWaypointRadius = 180,
    GucciPatrolWaypointCount = 10,
    GucciPatrolUpdateInterval = 0.16,
    GucciPatrolOwnershipInterval = 0.45,
    GucciGuardRespawnBase = 1.5,
    GucciGuardMaxBackoff = 10,
    GucciGuardRetainOnDisable = false,
    RecoverViaSuspectSeat = false,
    AuthorizedGuardCleanup = false,
    GucciGuard = {
        Active = false,
        Respawning = false,
        SpawnPending = false,
        RecoveryLock = false,
        RecoveryReason = nil,
        RecoveryAttempts = 0,
        ConsecutiveFailures = 0,
        LastSuccessfulProtection = 0,
        CurrentGucciModel = nil,
        CurrentSeat = nil,
        CurrentAnchor = nil,
        LastSpawn = 0,
        LastCheck = 0,
        LostCount = 0,
        RetryAfter = 0,
        LastModeFlip = 0,
        SafeCycleDown = false,
        LastHighMaintain = 0,
        LastPatrolStep = 0,
        PatrolIndex = 1,
        PatrolWaypoints = {},
        RecoveryWaypoint = nil,
        RecoveryWaypointCreatedAt = 0,
        FastVerifyUntil = 0,
        FastVerifyNext = 0,
        LastOwnershipAttempt = 0,
        LastSeatAttempt = 0,
        LastSuspectSeatAttempt = 0,
        LastAuthorizedCleanup = 0,
        LastVerifiedProtected = 0,
        LastProtectionLoss = 0,
        PendingProtectionLoss = nil,
        LastSeatOccupantName = "none",
        LastOwnerName = "unknown",
        LastProtectedStatus = "not checked",
    },

    DefensiveMonitorEnabled = true,
    DefensiveResponseEnabled = false,
    DefensiveResponseMode = "Mark Only",
    DefensiveResponseCooldown = 4,
    DefensiveScanRadius = 55,
    DefensiveHealthDrop = 35,
    DefensiveForcedMoveStuds = 45,
    DefensiveLog = {},
    RecentGrab = nil,
    SuspectedAttacker = nil,
    SuspectedAttackerUserId = nil,
    SuspectedAttackerName = nil,
    SuspectedAttackerMarkedAt = 0,
    LastDefenseResponse = 0,
    LastDefenseLog = 0,
    LastHealth = nil,
    LastRootPosition = nil,
    LastMoveSpike = 0,
    MoveSpikeCount = 0,
    LastSeatChange = 0,
    LastDeathAt = 0,
}

local function now()
    return os.clock()
end

local function tableCount(t)
    local count = 0
    for _ in pairs(t or {}) do count += 1 end
    return count
end

local function pushBounded(list, item, maxItems)
    table.insert(list, item)
    while #list > (maxItems or 30) do
        table.remove(list, 1)
    end
end

local function trackConnection(name, conn)
    if State.Connections[name] then
        pcall(function() State.Connections[name]:Disconnect() end)
    end
    State.Connections[name] = conn
    return conn
end

local function removeConnection(name)
    if State.Connections[name] then
        pcall(function() State.Connections[name]:Disconnect() end)
        State.Connections[name] = nil
    end
end

local function trackInstance(instance)
    if instance then
        table.insert(State.Instances, instance)
    end
    return instance
end

local function notify(title, content, duration)
    duration = duration or 3
    if State.Rayfield then
        pcall(function()
            State.Rayfield:Notify({ Title = title, Content = content, Duration = duration })
        end)
    else
        pcall(function()
            StarterGui:SetCore("SendNotification", { Title = title, Text = content, Duration = duration })
        end)
    end
end

local function safeWait(parent, name, timeout)
    if not parent then return nil end
    local obj = parent:FindFirstChild(name)
    if obj then return obj end
    local ok, result = pcall(function()
        return parent:WaitForChild(name, timeout or 3)
    end)
    return ok and result or nil
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local character = getCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local character = getCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getToyFolder()
    return Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
end

local function waitForToyFolder(timeout)
    local folder = getToyFolder()
    if folder then return folder end
    local ok, result = pcall(function()
        return Workspace:WaitForChild(LocalPlayer.Name .. "SpawnedInToys", timeout or 2)
    end)
    return ok and result or nil
end

local function getMenuToys()
    return ReplicatedStorage:FindFirstChild("MenuToys")
end

local function getGrabEvents()
    return ReplicatedStorage:FindFirstChild("GrabEvents")
end

local function getCharacterEvents()
    return ReplicatedStorage:FindFirstChild("CharacterEvents")
end

local function getRemote(path)
    local current = ReplicatedStorage
    for _, name in ipairs(path) do
        current = current and current:FindFirstChild(name)
    end
    return current
end

local function fireRateLimited(key, interval, fn)
    local t = now()
    if State.LastRemote[key] and t - State.LastRemote[key] < interval then
        return false
    end
    State.LastRemote[key] = t
    local ok = pcall(fn)
    return ok
end

local function sanitizeName(text)
    text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

local function isWhitelisted(player)
    if not player then return false end
    for _, name in ipairs(State.Whitelist) do
        if string.lower(name) == string.lower(player.Name) or string.lower(name) == string.lower(player.DisplayName) then
            return true
        end
    end
    return false
end

local function isAuthorizedTarget(player)
    if not player or player == LocalPlayer then return false end
    if not State.AuthorizedTargetsOnly then return true end
    return isWhitelisted(player) or player:GetAttribute("NomNomAuthorizedTarget") == true
end

local function getAliveRoot(player)
    if not player or not player.Character then return nil end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if hum and hum.Health > 0 and root then
        return root, hum
    end
    return nil
end

local function getPlayerByName(text)
    text = string.lower(sanitizeName(text))
    if text == "" then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        local name = string.lower(player.Name)
        local display = string.lower(player.DisplayName)
        if name == text or display == text or name:sub(1, #text) == text or display:sub(1, #text) == text then
            return player
        end
    end
    return nil
end

local function getSelectedTargetPlayer()
    if typeof(State.SelectedTarget) == "Instance" and State.SelectedTarget:IsA("Player") and State.SelectedTarget.Parent == Players then
        return State.SelectedTarget
    end
    if type(State.SelectedTarget) == "string" then
        return getPlayerByName(State.SelectedTarget)
    end
    return nil
end

local function nearestPlayer(position, maxDistance, authorizedOnly)
    local bestPlayer, bestDistance = nil, maxDistance or math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and (not authorizedOnly or isAuthorizedTarget(player)) then
            local root = getAliveRoot(player)
            if root then
                local dist = (position - root.Position).Magnitude
                if dist <= bestDistance then
                    bestPlayer, bestDistance = player, dist
                end
            end
        end
    end
    return bestPlayer, bestDistance
end

local function allAuthorizedTargets(maxDistance)
    local list = {}
    local myRoot = getRoot()
    for _, player in ipairs(Players:GetPlayers()) do
        if isAuthorizedTarget(player) then
            local root = getAliveRoot(player)
            if root and (not maxDistance or not myRoot or (myRoot.Position - root.Position).Magnitude <= maxDistance) then
                table.insert(list, player)
            end
        end
    end
    table.sort(list, function(a, b) return a.Name < b.Name end)
    return list
end

local function spawnToy(toyName, cf, velocity)
    local menuToys = getMenuToys()
    local spawnRemote = menuToys and menuToys:FindFirstChild("SpawnToyRemoteFunction")
    if not spawnRemote then
        notify("NomNom FTAP", "SpawnToyRemoteFunction not found", 3)
        return false
    end
    return pcall(function()
        spawnRemote:InvokeServer(toyName, cf, velocity or Vector3.zero)
    end)
end

local function destroyToy(toy)
    local menuToys = getMenuToys()
    local remote = menuToys and menuToys:FindFirstChild("DestroyToy")
    if remote and toy then
        pcall(function() remote:FireServer(toy) end)
    elseif toy and toy.Destroy then
        pcall(function() toy:Destroy() end)
    end
end

local function setNetworkOwner(part, cf, interval, keySuffix)
    local remote = getRemote({"GrabEvents", "SetNetworkOwner"})
    if remote and part then
        local key = "SetNetworkOwner" .. tostring(keySuffix or "")
        fireRateLimited(key, interval or 0.12, function()
            remote:FireServer(part, cf or part.CFrame)
        end)
    end
end

local function getOwnedToyFolder()
    return getToyFolder()
end

local function findLatestOwnedToyByNames(names, sinceTime)
    local folder = getOwnedToyFolder()
    if not folder then return nil end
    local allowed = {}
    for _, name in ipairs(names) do allowed[name] = true end
    local latest, latestScore = nil, -math.huge
    for _, child in ipairs(folder:GetChildren()) do
        if allowed[child.Name] then
            local score = 0
            pcall(function() score = child:GetAttribute("NomNomSpawnTick") or 0 end)
            if score == 0 then score = now() end
            if score >= (sinceTime or 0) - 3 and score > latestScore then
                latest, latestScore = child, score
            end
        end
    end
    return latest
end

local function waitForOwnedToyChildAdded(names, sinceTime, timeout)
    local folder = waitForToyFolder(1.5)
    if not folder then return nil end
    local existing = findLatestOwnedToyByNames(names, sinceTime)
    if existing then return existing end

    local allowed = {}
    for _, name in ipairs(names) do allowed[name] = true end
    local finished = false
    local found = nil
    local conn
    conn = folder.ChildAdded:Connect(function(child)
        if allowed[child.Name] and not found then
            pcall(function() child:SetAttribute("NomNomSpawnTick", now()) end)
            found = child
            finished = true
        end
    end)

    local deadline = now() + (timeout or State.GucciGuardSpawnTimeout or 3)
    repeat
        local scan = findLatestOwnedToyByNames(names, sinceTime)
        if scan then
            found = scan
            break
        end
        task.wait(0.05)
    until found or finished or now() >= deadline or not State.Enabled

    if conn then pcall(function() conn:Disconnect() end) end
    return found
end

local function findFirstDescendantByClass(root, className)
    if not root then return nil end
    if root:IsA(className) then return root end
    for _, child in ipairs(root:GetDescendants()) do
        if child:IsA(className) then return child end
    end
    return nil
end

local function findFirstBasePart(root)
    if not root then return nil end
    if root:IsA("BasePart") then return root end
    return findFirstDescendantByClass(root, "BasePart")
end

local function isInstanceAlive(inst)
    return typeof(inst) == "Instance" and inst.Parent ~= nil and inst:IsDescendantOf(game)
end

local function cacheRecentGrab(owner, grabModel, grabbedPart)
    State.RecentGrab = {
        Owner = owner,
        Model = grabModel,
        Part = grabbedPart,
        Time = now(),
    }
end

local function logDefense(reason, player)
    local name = player and (player.DisplayName .. " (@" .. player.Name .. ")") or "no safe target"
    local message = string.format("%s | %s", tostring(reason or "signal"), name)
    pushBounded(State.DefensiveLog, os.date("%H:%M:%S") .. " " .. message, 40)
    if now() - State.LastDefenseLog > 0.75 then
        State.LastDefenseLog = now()
        notify("NomNom Defense", message, 4)
        warn("[NomNomFTAP][Defense]", message)
    end
end

local function markSuspectedAttacker(player, reason)
    if not player or player == LocalPlayer then return nil end
    State.SuspectedAttacker = player
    State.SuspectedAttackerUserId = player.UserId
    State.SuspectedAttackerName = player.Name
    State.SuspectedAttackerMarkedAt = now()
    pcall(function() player:SetAttribute("NomNomSuspectedPrivateTest", true) end)
    return player, reason or "suspected attacker persisted"
end

local function getPersistedSuspectedAttacker()
    if State.SuspectedAttacker and State.SuspectedAttacker.Parent == Players then
        return State.SuspectedAttacker
    end
    if State.SuspectedAttackerUserId then
        local byId = Players:GetPlayerByUserId(State.SuspectedAttackerUserId)
        if byId then
            State.SuspectedAttacker = byId
            return byId
        end
    end
    if State.SuspectedAttackerName then
        local byName = Players:FindFirstChild(State.SuspectedAttackerName)
        if byName and byName:IsA("Player") then
            State.SuspectedAttacker = byName
            return byName
        end
    end
    return nil
end

local function cleanupGucciGuard(destroyModel, keepRecoveryLock)
    local guard = State.GucciGuard
    guard.Active = false
    guard.Respawning = false
    guard.SpawnPending = false
    guard.CurrentSeat = nil
    guard.CurrentAnchor = nil
    guard.PendingProtectionLoss = nil
    guard.LastProtectedStatus = "cleaned"
    removeConnection("GucciModelAncestry")
    removeConnection("GucciSeatAncestry")
    removeConnection("GucciSeatOccupant")
    if not keepRecoveryLock then
        guard.RecoveryLock = false
        guard.RecoveryReason = nil
    end
    if destroyModel and guard.CurrentGucciModel then
        destroyToy(guard.CurrentGucciModel)
    end
    guard.CurrentGucciModel = nil
end

local function getGuardToyChoices()
    if State.GucciGuardToy == "TractorGreen" then return {"TractorGreen"} end
    if State.GucciGuardToy == "CreatureBlobman" then return {"CreatureBlobman"} end
    return {"TractorGreen", "CreatureBlobman"}
end

local function findGuardSeat(model)
    if not model then return nil end
    if model:IsA("Seat") or model:IsA("VehicleSeat") then return model end
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("Seat") or desc:IsA("VehicleSeat") then
            return desc
        end
    end
    return nil
end

local function modelMatchesGuardChoice(model)
    if not model then return false end
    for _, toyName in ipairs(getGuardToyChoices()) do
        if model.Name == toyName then return true end
    end
    return false
end

local function findExistingGuardModel()
    local folder = getOwnedToyFolder()
    if not folder then return nil end
    local best, bestScore = nil, -math.huge
    for _, child in ipairs(folder:GetChildren()) do
        if modelMatchesGuardChoice(child) then
            local seat = findGuardSeat(child)
            local anchor = seat or findFirstBasePart(child)
            if anchor then
                local score = 0
                pcall(function() score = child:GetAttribute("NomNomSpawnTick") or 0 end)
                if score == 0 then score = child == State.GucciGuard.CurrentGucciModel and now() or 1 end
                if score > bestScore then
                    best = child
                    bestScore = score
                end
            end
        end
    end
    return best
end

local function getPartOwnerName(inst)
    if not inst then return nil end
    local value = nil
    pcall(function()
        value = inst:FindFirstChild("PartOwner") or inst:FindFirstChild("PartOwner", true)
    end)
    if value and value:IsA("StringValue") then
        return value.Value
    end
    return nil
end

local function getGuardOwnerName(model, anchor)
    if not model then return nil end
    local function firstOwner(candidate)
        local ownerName = getPartOwnerName(candidate)
        if ownerName and ownerName ~= "" then
            return ownerName
        end
        return nil
    end
    return firstOwner(model:FindFirstChild("Head"))
        or firstOwner(model:FindFirstChild("GrabbableHitbox"))
        or firstOwner(model:FindFirstChild("VehicleSeat") or model:FindFirstChildWhichIsA("VehicleSeat", true))
        or firstOwner(anchor)
end

local function isGuardInExpectedContainer(model)
    if not model or not isInstanceAlive(model) then return false end
    local folder = getOwnedToyFolder()
    if folder and model:IsDescendantOf(folder) then return true end
    local plots = Workspace:FindFirstChild("Plots")
    if plots and model:IsDescendantOf(plots) then return true end
    local plotItems = Workspace:FindFirstChild("PlotItems")
    if plotItems and model:IsDescendantOf(plotItems) then return true end
    return false
end

local function flagGucciProtectionLoss(reason)
    if not State.GucciGuardEnabled then return end
    local guard = State.GucciGuard
    guard.PendingProtectionLoss = tostring(reason or "protection loss")
    guard.LastProtectionLoss = now()
    guard.RecoveryLock = true
    guard.RecoveryReason = guard.PendingProtectionLoss
    guard.FastVerifyUntil = math.max(guard.FastVerifyUntil or 0, now() + (State.GucciGuardFastVerifyWindow or 1.25))
    guard.LastProtectedStatus = guard.PendingProtectionLoss
end

local function monitorBoundGucciGuard(model, seat)
    removeConnection("GucciModelAncestry")
    removeConnection("GucciSeatAncestry")
    removeConnection("GucciSeatOccupant")
    local guard = State.GucciGuard
    if model then
        trackConnection("GucciModelAncestry", model.AncestryChanged:Connect(function(_, parent)
            if State.GucciGuardEnabled and guard.CurrentGucciModel == model and (not parent or not model:IsDescendantOf(Workspace)) then
                flagGucciProtectionLoss("anti-destroy protection loss: model ancestry changed")
            end
        end))
    end
    if seat then
        trackConnection("GucciSeatAncestry", seat.AncestryChanged:Connect(function(_, parent)
            if State.GucciGuardEnabled and guard.CurrentSeat == seat and (not parent or not seat:IsDescendantOf(Workspace)) then
                flagGucciProtectionLoss("anti-destroy protection loss: seat not descendant of workspace")
            end
        end))
        trackConnection("GucciSeatOccupant", seat:GetPropertyChangedSignal("Occupant"):Connect(function()
            if not State.GucciGuardEnabled or guard.CurrentSeat ~= seat then return end
            local hum = getHumanoid()
            local occupant = seat.Occupant
            guard.LastSeatOccupantName = occupant and occupant.Parent and occupant.Parent.Name or "none"
            guard.FastVerifyUntil = math.max(guard.FastVerifyUntil or 0, now() + 0.6)
            if occupant and hum and occupant ~= hum then
                flagGucciProtectionLoss("anti-steal-seat protection loss: seat occupant changed")
            elseif not occupant and hum and (guard.LastVerifiedProtected or 0) > 0 and hum.SeatPart ~= seat then
                flagGucciProtectionLoss("anti-steal-seat protection loss: seat occupant cleared")
            end
        end))
    end
end

local function getGucciProtectionState()
    local guard = State.GucciGuard
    local model = guard.CurrentGucciModel
    local seat = guard.CurrentSeat
    local anchor = guard.CurrentAnchor or seat or findFirstBasePart(model)
    local root = getRoot()
    local hum = getHumanoid()
    if not State.GucciGuardEnabled then return false, "guard disabled" end
    if guard.PendingProtectionLoss then return false, guard.PendingProtectionLoss end
    if not isInstanceAlive(model) then return false, "anti-destroy protection loss: model missing" end
    if not model:IsDescendantOf(Workspace) then return false, "anti-destroy protection loss: model not descendant of workspace" end
    if not isGuardInExpectedContainer(model) then return false, "anti-destroy protection loss: model not in owned toy folder/plot items" end
    if not seat then return false, "verified protected failed: seat unavailable" end
    if not isInstanceAlive(seat) or not seat:IsDescendantOf(Workspace) then return false, "anti-destroy protection loss: seat not descendant of workspace" end
    if not root or not hum or hum.Health <= 0 then return false, "verified protected failed: character unavailable" end

    local occupant = seat.Occupant
    guard.LastSeatOccupantName = occupant and occupant.Parent and occupant.Parent.Name or "none"
    if occupant and occupant ~= hum then
        return false, "anti-steal-seat protection loss: seat occupant changed"
    end
    if hum.SeatPart and hum.SeatPart ~= seat then
        return false, "anti-steal-seat protection loss: local humanoid seated elsewhere"
    end
    local seatDistance = (root.Position - seat.Position).Magnitude
    if hum.SeatPart ~= seat and seatDistance > math.max(12, State.GucciGuardDistance + 5) then
        return false, "verified protected failed: local humanoid not seated/proximate"
    end

    local ownerName = getGuardOwnerName(model, anchor)
    guard.LastOwnerName = ownerName or "unknown"
    if ownerName and ownerName ~= LocalPlayer.Name then
        return false, "protection loss: ownership loss to " .. tostring(ownerName)
    end

    if anchor and anchor:IsA("BasePart") then
        local safeY = math.max(State.GucciPatrolSafeMinY or 35, (State.AntiVoidY or -100) + 25)
        if anchor.Position.Y < safeY - 8 then
            return false, "protection loss: model moved out of safe patrol area"
        end
        local maxDistance = math.max(160, (State.GucciPatrolWaypointRadius or 180) + (State.GucciGuardMaxHeight or 250) + 100)
        if (root.Position - anchor.Position).Magnitude > maxDistance then
            return false, "protection loss: model moved out of safe patrol area"
        end
    end

    guard.LastProtectedStatus = "verified protected"
    guard.LastVerifiedProtected = now()
    return true, "verified protected"
end

local function getClampedGucciHeight()
    return math.clamp(math.abs(State.GucciGuardHeight or 85), 25, math.clamp(State.GucciGuardMaxHeight or 250, 60, 500))
end

local function getGucciVaultOffset()
    local mode = State.GucciGuardMode
    local high = getClampedGucciHeight()
    if mode == "Map Orbit Guard" or mode == "Extreme Map Patrol" then
        return Vector3.new(0, math.clamp(State.GucciPatrolVaultHeight or high, high, State.GucciGuardMaxHeight), 0)
    elseif mode == "Maximum Upward Vault" or mode == "High Sky Vault" then
        return Vector3.new(0, high, 0)
    elseif mode == "Adaptive High Vault" then
        local root = getRoot()
        local extra = (root and root.Position.Y < State.AntiVoidY + 60) and 45 or 0
        return Vector3.new(0, math.min(high + extra, State.GucciGuardMaxHeight), 0)
    elseif mode == "Downward Vault (Unsafe Experimental)" then
        return Vector3.new(0, -math.min(high, 80), 0)
    end
    return Vector3.new(0, high, 0)
end

local function clampSafePatrolPosition(pos)
    local safeY = math.max(State.GucciPatrolSafeMinY or 35, (State.AntiVoidY or -100) + 25)
    local highY = math.clamp(State.GucciPatrolVaultHeight or State.GucciGuardHeight or 135, safeY + 8, State.GucciGuardMaxHeight or 250)
    return Vector3.new(pos.X, math.max(pos.Y, safeY, highY), pos.Z)
end

local function rebuildPatrolWaypoints(center)
    local guard = State.GucciGuard
    table.clear(guard.PatrolWaypoints)
    center = center or (getRoot() and getRoot().Position) or Vector3.new(0, State.GucciPatrolSafeMinY, 0)
    local radius = math.clamp(State.GucciPatrolWaypointRadius or 180, 40, 750)
    local count = math.clamp(math.floor(State.GucciPatrolWaypointCount or 10), 4, 24)
    local high = math.clamp(State.GucciPatrolVaultHeight or 135, State.GucciPatrolSafeMinY or 35, State.GucciGuardMaxHeight or 250)

    if Workspace:FindFirstChild("Map") then
        local samples = {}
        for _, obj in ipairs(Workspace.Map:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Size.Magnitude >= 25 and #samples < count then
                local p = obj.Position + Vector3.new(0, high, 0)
                if p.Y >= (State.GucciPatrolSafeMinY or 35) then
                    table.insert(samples, clampSafePatrolPosition(p))
                end
            end
        end
        for _, p in ipairs(samples) do table.insert(guard.PatrolWaypoints, p) end
    end

    for i = #guard.PatrolWaypoints + 1, count do
        local angle = (i / count) * math.pi * 2
        local yPulse = (i % 3) * 12
        local p = center + Vector3.new(math.cos(angle) * radius, high + yPulse, math.sin(angle) * radius)
        table.insert(guard.PatrolWaypoints, clampSafePatrolPosition(p))
    end
    guard.PatrolIndex = math.clamp(guard.PatrolIndex or 1, 1, math.max(1, #guard.PatrolWaypoints))
end

local function getNextPatrolCFrame(root)
    local guard = State.GucciGuard
    if #guard.PatrolWaypoints == 0 then rebuildPatrolWaypoints(root and root.Position) end
    if #guard.PatrolWaypoints == 0 then return nil end
    local intensity = math.clamp(State.GucciPatrolIntensity or 1.25, 0.25, 3)
    local jumps = math.max(1, math.floor(intensity + 0.5))
    guard.PatrolIndex = ((guard.PatrolIndex + jumps - 1) % #guard.PatrolWaypoints) + 1
    local target = guard.PatrolWaypoints[guard.PatrolIndex]
    if guard.RecoveryLock and guard.RecoveryWaypoint then
        target = guard.RecoveryWaypoint:Lerp(target, 0.72)
    end
    local lookAt = root and root.Position or Vector3.new(0, target.Y, 0)
    return CFrame.new(clampSafePatrolPosition(target), lookAt)
end

local function getGucciSpawnCFrame()
    local root = getRoot()
    if not root then return nil end
    local look = root.CFrame.LookVector
    local planar = Vector3.new(look.X, 0, look.Z)
    if planar.Magnitude < 0.05 then planar = Vector3.new(0, 0, -1) end
    local offset = planar.Unit * math.clamp(State.GucciGuardDistance, 4, 35) + getGucciVaultOffset()
    return CFrame.new(root.Position + offset, root.Position)
end

local function seatLocalCharacterOnGuard(seat)
    local hum = getHumanoid()
    local root = getRoot()
    if not hum or not root or not seat or not isInstanceAlive(seat) then return false end
    pcall(function()
        root.CFrame = seat.CFrame * CFrame.new(0, 2.2, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    task.wait(0.08)
    pcall(function() seat:Sit(hum) end)
    return hum.SeatPart == seat or (root.Position - seat.Position).Magnitude <= 7
end

local function markGuardModel(model)
    if not model then return end
    pcall(function() model:SetAttribute("NomNomGucciGuard", true) end)
    pcall(function() model:SetAttribute("NomNomSpawnTick", now()) end)
end

local function bindGucciGuardModel(model, reason)
    if not model or not isInstanceAlive(model) then return false end
    markGuardModel(model)
    local seat = findGuardSeat(model)
    local anchor = seat or findFirstBasePart(model)
    if not anchor then return false end
    local guard = State.GucciGuard
    guard.CurrentGucciModel = model
    guard.CurrentSeat = seat
    guard.CurrentAnchor = anchor
    guard.Active = true
    guard.Respawning = false
    guard.SpawnPending = false
    guard.RetryAfter = 0
    guard.PendingProtectionLoss = nil
    guard.LastProtectedStatus = "binding from " .. tostring(reason or "scan")
    monitorBoundGucciGuard(model, seat)
    guard.FastVerifyUntil = math.max(guard.FastVerifyUntil or 0, now() + (State.GucciGuardFastVerifyWindow or 1.25))
    if now() - guard.LastOwnershipAttempt >= 0.45 then
        guard.LastOwnershipAttempt = now()
        setNetworkOwner(anchor, anchor.CFrame, State.GucciPatrolOwnershipInterval, "Guard")
    end
    if seat and now() - guard.LastSeatAttempt >= 0.85 then
        guard.LastSeatAttempt = now()
        seatLocalCharacterOnGuard(seat)
    end
    if reason then notify("Gucci Guard", "Active via " .. model.Name .. " (" .. reason .. ")", 3) end
    return true
end

local function gucciLossReason()
    if not State.GucciGuardEnabled then return nil end
    local ok, reason = getGucciProtectionState()
    if ok then return nil end
    return reason or "protection loss"
end

local function gucciProtectionConfirmed()
    local ok = getGucciProtectionState()
    return State.GucciGuardEnabled and ok == true
end

local function maintainHighGucciPosition(force)
    local guard = State.GucciGuard
    if not State.GucciGuardEnabled or not guard.Active then return false end
    local t = now()
    local fastVerifyActive = (guard.FastVerifyUntil or 0) > t
    local interval = fastVerifyActive and math.min(State.GucciGuardFastVerifyInterval or 0.08, State.GucciGuardMaintainRate) or State.GucciGuardMaintainRate
    if not force and t - guard.LastHighMaintain < interval then return false end
    guard.LastHighMaintain = t

    local model = guard.CurrentGucciModel
    local anchor = guard.CurrentAnchor or guard.CurrentSeat or findFirstBasePart(model)
    local root = getRoot()
    if not model or not anchor or not root or not isInstanceAlive(model) or not isInstanceAlive(anchor) then return false end

    local desired
    local usePatrol = State.GucciPatrolEnabled or State.GucciGuardMode == "Extreme Map Patrol" or State.GucciGuardMode == "Map Orbit Guard" or guard.RecoveryLock
    if usePatrol and (force or fastVerifyActive or t - guard.LastPatrolStep >= (State.GucciPatrolUpdateInterval or 0.16)) then
        guard.LastPatrolStep = t
        desired = getNextPatrolCFrame(root)
    end
    if not desired then
        local look = root.CFrame.LookVector
        local planar = Vector3.new(look.X, 0, look.Z)
        if planar.Magnitude < 0.05 then planar = Vector3.new(0, 0, -1) end
        desired = CFrame.new(clampSafePatrolPosition(root.Position + (planar.Unit * math.clamp(State.GucciGuardDistance, 4, 35)) + getGucciVaultOffset()), root.Position)
    end

    pcall(function()
        if model.PivotTo then
            model:PivotTo(desired)
        else
            anchor.CFrame = desired
        end
        anchor.AssemblyLinearVelocity = Vector3.zero
        anchor.AssemblyAngularVelocity = Vector3.zero
    end)

    if t - guard.LastOwnershipAttempt >= (State.GucciPatrolOwnershipInterval or 0.45) then
        guard.LastOwnershipAttempt = t
        setNetworkOwner(anchor, desired, State.GucciPatrolOwnershipInterval, "Guard")
    end
    if guard.CurrentSeat and t - guard.LastSeatAttempt >= (fastVerifyActive and 0.25 or 0.85) then
        guard.LastSeatAttempt = t
        local hum = getHumanoid()
        if not hum or hum.SeatPart ~= guard.CurrentSeat or guard.CurrentSeat.Occupant ~= hum then
            seatLocalCharacterOnGuard(guard.CurrentSeat)
        end
    end
    return true
end

local function spawnGucciGuard(reason)
    local guard = State.GucciGuard
    if not State.GucciGuardEnabled or guard.Respawning or guard.SpawnPending or not State.Enabled then return false end

    local existing = findExistingGuardModel()
    if existing and bindGucciGuardModel(existing, "reused existing guard") then
        maintainHighGucciPosition(true)
        return true
    end

    local t = now()
    local cooldown = math.max(State.GucciGuardSpawnCooldown, State.GucciGuardRespawnBase)
    if t < guard.RetryAfter or t - guard.LastSpawn < cooldown then return false end
    local cf = getGucciSpawnCFrame()
    if not cf then return false end

    guard.Respawning = true
    guard.SpawnPending = true
    guard.LastSpawn = t
    guard.RecoveryAttempts += 1
    cleanupGucciGuard(false, true)
    guard.Respawning = true
    guard.SpawnPending = true

    local spawnedModel
    for _, toyName in ipairs(getGuardToyChoices()) do
        local fired = fireRateLimited("GucciSpawn" .. toyName, State.GucciGuardSpawnCooldown, function()
            spawnToy(toyName, cf, Vector3.zero)
        end)
        if fired then
            spawnedModel = waitForOwnedToyChildAdded({toyName}, t, State.GucciGuardSpawnTimeout) or findExistingGuardModel()
            if spawnedModel then break end
        end
    end

    guard.Respawning = false
    guard.SpawnPending = false
    if not spawnedModel then
        guard.LostCount += 1
        guard.ConsecutiveFailures += 1
        guard.RetryAfter = now() + math.min(State.GucciGuardMaxBackoff, State.GucciGuardRespawnBase + (guard.ConsecutiveFailures * 0.9))
        notify("Gucci Guard", "ChildAdded spawn wait timed out; spawnPending cleared with backoff", 3)
        return false
    end

    if bindGucciGuardModel(spawnedModel, reason or "spawned via ChildAdded") then
        guard.ConsecutiveFailures = 0
        guard.LastSuccessfulProtection = now()
        guard.FastVerifyUntil = now() + (State.GucciGuardFastVerifyWindow or 1.25)
        rebuildPatrolWaypoints((getRoot() and getRoot().Position) or nil)
        maintainHighGucciPosition(true)
        return true
    end

    guard.ConsecutiveFailures += 1
    guard.RetryAfter = now() + math.min(State.GucciGuardMaxBackoff, State.GucciGuardRespawnBase + guard.ConsecutiveFailures)
    return false
end

local function findPlayerToyFolder(player)
    if not player then return nil end
    return Workspace:FindFirstChild(player.Name .. "SpawnedInToys")
end

local function findVisibleGuardForPlayer(player)
    local folder = findPlayerToyFolder(player)
    if not folder then return nil end
    for _, child in ipairs(folder:GetChildren()) do
        if (child.Name == "CreatureBlobman" or child.Name == "TractorGreen") and findGuardSeat(child) and findFirstBasePart(child) then
            return child
        end
    end
    return nil
end

local function recoverViaSuspectSeat()
    if not State.RecoverViaSuspectSeat or gucciProtectionConfirmed() then return false end
    local guard = State.GucciGuard
    if now() - guard.LastSuspectSeatAttempt < 2.5 then return false end
    guard.LastSuspectSeatAttempt = now()

    local suspect = getPersistedSuspectedAttacker()
    if not suspect or not isAuthorizedTarget(suspect) then return false end
    local suspectGuard = findVisibleGuardForPlayer(suspect)
    if not suspectGuard then return false end
    local seat = findGuardSeat(suspectGuard)
    if not seat then return false end
    logDefense("authorized suspect seat recovery attempt", suspect)
    return seatLocalCharacterOnGuard(seat)
end

local function authorizedTargetGuardCleanup()
    if not State.AuthorizedGuardCleanup then return false end
    if gucciProtectionConfirmed() then return false end
    local t = now()
    local guard = State.GucciGuard
    if t - guard.LastAuthorizedCleanup < (State.AuthorizedCleanupCooldown or 7) then return false end
    local suspect = getPersistedSuspectedAttacker()
    if not suspect or not isAuthorizedTarget(suspect) then return false end
    local suspectGuard = findVisibleGuardForPlayer(suspect)
    if not suspectGuard then return false end
    guard.LastAuthorizedCleanup = t
    logDefense("Authorized Guard Cleanup: targeted visible suspect guard only", suspect)
    destroyToy(suspectGuard)
    return true
end

local function authorizedCounterResponse(reason, position)
    if not State.AuthorizedCounterResponse then return false end
    local t = now()
    if t - State.LastAuthorizedCounterResponse < (State.AuthorizedCounterCooldown or 6) then return false end
    local suspect = getPersistedSuspectedAttacker()
    if not suspect or not isAuthorizedTarget(suspect) then return false end
    State.LastAuthorizedCounterResponse = t
    logDefense("Authorized Counter Response: bounded private-test marker after recovery start", suspect)
    local root = getRoot()
    local targetRoot = getAliveRoot(suspect)
    if root and targetRoot then
        fireRateLimited("AuthorizedCounterToy", State.AuthorizedCounterCooldown or 6, function()
            spawnToy(State.SelectedToy or "DiceBig", CFrame.new(root.Position:Lerp(targetRoot.Position, 0.25) + Vector3.new(0, 6, 0), targetRoot.Position), Vector3.zero)
        end)
    end
    return true
end

local function enterGucciRecoveryLock(reason)
    if not State.GucciGuardEnabled then return end
    local guard = State.GucciGuard
    guard.RecoveryLock = true
    guard.RecoveryReason = reason or "unknown"
    local root = getRoot()
    if root then
        guard.RecoveryWaypoint = clampSafePatrolPosition(root.Position + Vector3.new(0, State.GucciPatrolVaultHeight or 135, 0))
        guard.RecoveryWaypointCreatedAt = now()
    end
    guard.FastVerifyUntil = math.max(guard.FastVerifyUntil or 0, now() + (State.GucciGuardFastVerifyWindow or 1.25))
    rebuildPatrolWaypoints(root and root.Position or nil)
    if State.Threads.GucciRecovery then return end

    State.Threads.GucciRecovery = true
    task.spawn(function()
        while State.Enabled and State.GucciGuardEnabled and guard.RecoveryLock do
            guard.RecoveryAttempts += 1
            local existing = findExistingGuardModel()
            if existing then
                bindGucciGuardModel(existing, "recovery lock reuse")
            end
            maintainHighGucciPosition(true)
            if gucciProtectionConfirmed() then
                guard.RecoveryLock = false
                guard.RecoveryReason = nil
                guard.PendingProtectionLoss = nil
                guard.ConsecutiveFailures = 0
                guard.LastSuccessfulProtection = now()
                notify("Gucci Guard", "Recovery lock cleared; verified protected", 3)
                break
            end
            recoverViaSuspectSeat()
            authorizedTargetGuardCleanup()
            if not gucciProtectionConfirmed() then
                spawnGucciGuard(reason or "recovery lock")
            end
            maintainHighGucciPosition(true)
            if not gucciProtectionConfirmed() then
                authorizedCounterResponse("recovery lock", guard.RecoveryWaypoint)
            end
            local fast = (guard.FastVerifyUntil or 0) > now()
            local sleepFor = fast and (State.GucciGuardFastVerifyInterval or 0.08) or math.clamp(State.GucciGuardRespawnBase + (guard.ConsecutiveFailures * 0.45), 0.65, State.GucciGuardMaxBackoff)
            task.wait(sleepFor)
        end
        State.Threads.GucciRecovery = nil
    end)
end

local function maintainGucciGuard(forceReason)
    if not State.GucciGuardEnabled then return end
    local guard = State.GucciGuard
    local t = now()
    local fastVerifyActive = (guard.FastVerifyUntil or 0) > t or guard.RecoveryLock or guard.PendingProtectionLoss ~= nil
    local checkInterval = fastVerifyActive and math.min(State.GucciGuardFastVerifyInterval or 0.08, State.GucciGuardCheckRate or 0.25) or (State.GucciGuardCheckRate or 0.25)
    if not forceReason and t - guard.LastCheck < checkInterval then
        maintainHighGucciPosition(false)
        return
    end
    guard.LastCheck = t

    if not guard.Active then
        local existing = findExistingGuardModel()
        if existing then bindGucciGuardModel(existing, "startup reuse") end
    end

    local reason = forceReason or gucciLossReason()
    if reason then
        guard.LostCount += 1
        guard.ConsecutiveFailures += 1
        guard.RetryAfter = t + math.min(State.GucciGuardMaxBackoff, State.GucciGuardRespawnBase + (guard.ConsecutiveFailures * 0.65))
        notify("Gucci Guard", "recovery lock: " .. reason, 3)
        enterGucciRecoveryLock(reason)
    elseif guard.CurrentSeat then
        guard.Active = true
        guard.ConsecutiveFailures = 0
        guard.PendingProtectionLoss = nil
        guard.LastSuccessfulProtection = t
        guard.LastVerifiedProtected = t
        guard.RecoveryLock = false
        maintainHighGucciPosition(false)
    elseif not guard.Active then
        spawnGucciGuard("startup")
    end
end

local function getRecentGrabOwnerNear(position)
    local grab = State.RecentGrab
    if not grab or now() - grab.Time > 5 then return nil end
    if grab.Owner and grab.Owner ~= LocalPlayer then return grab.Owner end
    if grab.Part and position and isInstanceAlive(grab.Part) then
        local nearest = nearestPlayer(grab.Part.Position, State.DefensiveScanRadius, false)
        if nearest then return nearest end
    end
    return nil
end

local function chooseSuspectedAttacker(reason, position)
    local selected = getSelectedTargetPlayer()
    if selected and isAuthorizedTarget(selected) then return selected, "selected target" end

    local persisted = getPersistedSuspectedAttacker()
    if persisted then return persisted, "persisted suspected attacker" end

    local grabOwner = getRecentGrabOwnerNear(position)
    if grabOwner then return grabOwner, "recent grab proximity" end

    if position then
        local authorized = nearestPlayer(position, State.DefensiveScanRadius, true)
        if authorized then return authorized, "nearest authorized" end
        local anyPlayer = nearestPlayer(position, State.DefensiveScanRadius, false)
        if anyPlayer then return anyPlayer, "nearest player marker" end
    end

    return nil, reason or "unattributed"
end

local function findHeldObjectPart()
    local root = getRoot()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "GrabParts" then
            local grabPart = obj:FindFirstChild("GrabPart") or obj:FindFirstChild("DragPart")
            local weld = grabPart and grabPart:FindFirstChildOfClass("WeldConstraint")
            local part = weld and weld.Part1 or findFirstBasePart(obj)
            if part and (not root or (part.Position - root.Position).Magnitude <= 40) then
                return part, obj
            end
        end
    end
    return nil, nil
end

local function resolveResponseTarget(reason, position)
    local target, source = chooseSuspectedAttacker(reason, position)
    if target then markSuspectedAttacker(target, source) end
    if target and isAuthorizedTarget(target) then
        return target, source
    end
    return nil, source
end

local function performDefensiveResponse(reason, position)
    local target, source = resolveResponseTarget(reason, position)
    logDefense(reason .. " [" .. tostring(source) .. "]", target)
    if State.GucciGuardEnabled then enterGucciRecoveryLock("defense signal: " .. tostring(reason)) end
    if State.GucciGuardEnabled and State.GucciGuard.RecoveryLock then
        authorizedCounterResponse(reason, position)
    end
    if not State.DefensiveResponseEnabled then return end
    local mode = State.DefensiveResponseMode
    if mode == "Off" or mode == "Mark Only" then return end
    if not target then return end

    local t = now()
    if t - State.LastDefenseResponse < State.DefensiveResponseCooldown then return end
    State.LastDefenseResponse = t

    local targetRoot = getAliveRoot(target)
    local myRoot = getRoot()
    if not targetRoot or not myRoot then return end

    if mode == "Defensive Toy Response" then
        local shieldCf = CFrame.new(myRoot.Position:Lerp(targetRoot.Position, 0.35) + Vector3.new(0, 4, 0), targetRoot.Position)
        fireRateLimited("DefenseToySpawn", State.DefensiveResponseCooldown, function()
            spawnToy(State.SelectedToy or "DiceBig", shieldCf, Vector3.zero)
        end)
        notify("NomNom Defense", "Spawned defensive toy marker for " .. target.Name, 3)
    elseif mode == "SuperFling Response if held object exists" then
        local heldPart = findHeldObjectPart()
        if heldPart then
            setNetworkOwner(heldPart, heldPart.CFrame)
            local direction = (targetRoot.Position - myRoot.Position)
            if direction.Magnitude > 1 then direction = direction.Unit else direction = myRoot.CFrame.LookVector end
            local bv = Instance.new("BodyVelocity")
            bv.Name = "NomNomDefensivePulse"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = direction * math.clamp(State.SuperFlingStrength, 100, 2500)
            bv.Parent = heldPart
            Debris:AddItem(bv, 0.35)
            notify("NomNom Defense", "Rate-limited defensive pulse toward " .. target.Name, 3)
        else
            notify("NomNom Defense", "No held object available; marked only", 3)
        end
    end
end

local function recordDefenseSignal(reason, position)
    if not State.DefensiveMonitorEnabled then return end
    performDefensiveResponse(reason, position or (getRoot() and getRoot().Position))
end

local function attachHumanoidMonitor(character)
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    State.LastHealth = hum and hum.Health or nil
    State.LastRootPosition = root and root.Position or nil
    if not hum then return end

    removeConnection("DefenseHealth")
    removeConnection("DefenseDied")
    removeConnection("DefenseSeated")
    removeConnection("DefenseStateChanged")

    trackConnection("DefenseHealth", hum.HealthChanged:Connect(function(health)
        local last = State.LastHealth or health
        local drop = last - health
        State.LastHealth = health
        if drop >= State.DefensiveHealthDrop then
            local hitPos = (getRoot() and getRoot().Position) or (root and root.Position)
            local target = select(1, chooseSuspectedAttacker("large health delta", hitPos))
            if target then markSuspectedAttacker(target, "large health delta") end
            recordDefenseSignal("large health delta " .. math.floor(drop), hitPos)
        end
    end))

    trackConnection("DefenseDied", hum.Died:Connect(function()
        State.LastDeathAt = now()
        local deathPos = (getRoot() and getRoot().Position) or (root and root.Position)
        local target = select(1, chooseSuspectedAttacker("sudden death", deathPos))
        if target then markSuspectedAttacker(target, "sudden death") end
        recordDefenseSignal("sudden death", deathPos)
        if State.GucciGuardEnabled then
            enterGucciRecoveryLock("character death")
        end
    end))

    trackConnection("DefenseSeated", hum.Seated:Connect(function(active, seatPart)
        State.LastSeatChange = now()
        if active and seatPart and State.GucciGuard.CurrentSeat ~= seatPart then
            recordDefenseSignal("unexpected seat/ragdoll control", root and root.Position)
        end
    end))

    trackConnection("DefenseStateChanged", hum.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Ragdoll or newState == Enum.HumanoidStateType.FallingDown then
            recordDefenseSignal("ragdoll/fall indicator", root and root.Position)
        end
    end))
end

--// Cleanup
local function clearESP()
    for player, bundle in pairs(State.ESP) do
        for _, inst in pairs(bundle) do
            pcall(function() inst:Destroy() end)
        end
        State.ESP[player] = nil
    end
end

local function cleanup()
    State.Enabled = false
    cleanupGucciGuard(true)
    for name, conn in pairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
        State.Connections[name] = nil
    end
    for _, inst in ipairs(State.Instances) do
        pcall(function() inst:Destroy() end)
    end
    table.clear(State.Instances)
    clearESP()
    if State.FlingConn then pcall(function() State.FlingConn:Disconnect() end) end
    if State.FlingToy then destroyToy(State.FlingToy) end
    State.FlingConn = nil
    State.FlingToy = nil
end

if getgenv then
    getgenv()[CLEANUP_KEY] = cleanup
end

--// Rayfield loader
local Rayfield
local okRayfield, rayResult = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if okRayfield then
    Rayfield = rayResult
    State.Rayfield = Rayfield
else
    warn("[NomNomFTAP] Rayfield failed to load:", rayResult)
    return
end

local Window = Rayfield:CreateWindow({
    Name = "NomNom FTAP • Roo Build",
    LoadingTitle = "NomNom FTAP",
    LoadingSubtitle = "consolidated private-test utility",
    Theme = "Amethyst",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "NomNomFTAP",
        FileName = "RooBuildConfig",
    },
    KeySystem = false,
})

--// Movement/QoL
local MainTab = Window:CreateTab("Main", 4483362458)
MainTab:CreateSection("Character")

MainTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    CurrentValue = State.WalkSpeed,
    Flag = "NN_WalkSpeed",
    Callback = function(value)
        State.WalkSpeed = value
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = value end
    end,
})

MainTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 250},
    Increment = 1,
    CurrentValue = State.JumpPower,
    Flag = "NN_JumpPower",
    Callback = function(value)
        State.JumpPower = value
        local hum = getHumanoid()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = value
        end
    end,
})

MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "NN_InfiniteJump",
    Callback = function(value)
        State.InfiniteJump = value
    end,
})

MainTab:CreateButton({
    Name = "Unlock Camera Zoom",
    Callback = function()
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = 100000
        notify("NomNom FTAP", "Camera zoom unlocked", 2)
    end,
})

MainTab:CreateButton({
    Name = "Respawn Character",
    Callback = function()
        local hum = getHumanoid()
        if hum then hum.Health = 0 end
    end,
})

MainTab:CreateButton({
    Name = "Teleport to Safe Height",
    Callback = function()
        local root = getRoot()
        if root then
            root.CFrame = CFrame.new(0, 50, 0)
        end
    end,
})

trackConnection("InfiniteJump", UserInputService.JumpRequest:Connect(function()
    if not State.InfiniteJump then return end
    local hum = getHumanoid()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

--// Protection
local ProtectionTab = Window:CreateTab("Protection", 4483362458)
ProtectionTab:CreateSection("Local Guards")

ProtectionTab:CreateToggle({
    Name = "Anti Void",
    CurrentValue = false,
    Flag = "NN_AntiVoid",
    Callback = function(value) State.AntiVoid = value end,
})

ProtectionTab:CreateSlider({
    Name = "Anti Void Y",
    Range = {-500, 0},
    Increment = 5,
    CurrentValue = State.AntiVoidY,
    Flag = "NN_AntiVoidY",
    Callback = function(value) State.AntiVoidY = value end,
})

ProtectionTab:CreateToggle({
    Name = "Anti Ragdoll Assist",
    CurrentValue = false,
    Flag = "NN_AntiRagdoll",
    Callback = function(value) State.AntiRagdoll = value end,
})

ProtectionTab:CreateToggle({
    Name = "Anti Grab Assist",
    CurrentValue = false,
    Flag = "NN_AntiGrab",
    Callback = function(value) State.AntiGrab = value end,
})

ProtectionTab:CreateToggle({
    Name = "Anti Fire Assist",
    CurrentValue = false,
    Flag = "NN_AntiFire",
    Callback = function(value) State.AntiFire = value end,
})

ProtectionTab:CreateToggle({
    Name = "Anti Explode Stabilizer",
    CurrentValue = false,
    Flag = "NN_AntiExplode",
    Callback = function(value) State.AntiExplode = value end,
})

ProtectionTab:CreateToggle({
    Name = "Anti Input Lag",
    CurrentValue = false,
    Flag = "NN_AntiLag",
    Callback = function(value)
        State.AntiLag = value
        pcall(function()
            local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
            local beam = scripts and scripts:FindFirstChild("CharacterAndBeamMove")
            if beam then beam.Disabled = value end
        end)
    end,
})

ProtectionTab:CreateSection("Gucci Guard / Auto Gucci")

ProtectionTab:CreateParagraph({
    Title = "Gucci Guard Safety",
    Content = "Spawns TractorGreen or CreatureBlobman as a private-test defensive guard anchor. Extreme Map Patrol / Map Orbit Guard loops guard toys around safe high map waypoints; toys are clamped above safe minimum Y and never intentionally sent into void. Ported protection patterns from The Wourld add anti-steal-seat, anti-destroy, seat occupant, ownership, and safe patrol-area checks before declaring verified protected. Downward Vault remains unsafe/experimental only.",
})

ProtectionTab:CreateParagraph({
    Title = "Fast Verify + ChildAdded spawn wait",
    Content = "Spawn uses existing toy scan plus ChildAdded wait with spawnPending/backoff instead of fixed delay spam. After bind/recovery, Fast Verify briefly increases bounded checks, then returns to normal maintenance cadence.",
})

ProtectionTab:CreateParagraph({
    Title = "Leak-Prone Features",
    Content = "Leak-prone means code/state is more likely to reveal private info or expose fragile hooks/logs. It affects privacy and stability, not raw protection power. Features that strengthen Gucci Guard without secrets or spam stay available; risky extras stay off by default.",
})

ProtectionTab:CreateToggle({
    Name = "Enable Gucci Guard",
    CurrentValue = false,
    Flag = "NN_GucciGuard",
    Callback = function(value)
        State.GucciGuardEnabled = value
        if value then
            State.GucciGuard.LostCount = 0
            State.GucciGuard.ConsecutiveFailures = 0
            State.GucciGuard.RecoveryAttempts = 0
            State.GucciGuard.RetryAfter = 0
            State.GucciGuard.PendingProtectionLoss = nil
            State.GucciGuard.LastProtectedStatus = "enabled; awaiting verified protected"
            State.GucciGuard.FastVerifyUntil = now() + (State.GucciGuardFastVerifyWindow or 1.25)
            State.GucciGuard.RecoveryLock = true
            task.spawn(function() enterGucciRecoveryLock("enabled") end)
        else
            cleanupGucciGuard(not State.GucciGuardRetainOnDisable)
            notify("Gucci Guard", "Disabled and cleaned state", 2)
        end
    end,
})

ProtectionTab:CreateDropdown({
    Name = "Gucci Vault Strategy",
    Options = {"Adaptive High Vault", "High Sky Vault", "Maximum Upward Vault", "Map Orbit Guard", "Extreme Map Patrol", "Downward Vault (Unsafe Experimental)"},
    CurrentOption = {State.GucciGuardMode},
    Flag = "NN_GucciGuardMode",
    Callback = function(option)
        State.GucciGuardMode = type(option) == "table" and option[1] or option
        notify("Gucci Guard", "Vault mode: " .. State.GucciGuardMode, 2)
    end,
})

ProtectionTab:CreateDropdown({
    Name = "Gucci Anchor Toy",
    Options = {"Auto", "TractorGreen", "CreatureBlobman"},
    CurrentOption = {State.GucciGuardToy},
    Flag = "NN_GucciGuardToy",
    Callback = function(option)
        State.GucciGuardToy = type(option) == "table" and option[1] or option
    end,
})

ProtectionTab:CreateSlider({
    Name = "Gucci Guard Distance",
    Range = {4, 35},
    Increment = 1,
    CurrentValue = State.GucciGuardDistance,
    Flag = "NN_GucciGuardDistance",
    Callback = function(value) State.GucciGuardDistance = value end,
})

ProtectionTab:CreateSlider({
    Name = "High Vault Height",
    Range = {25, State.GucciGuardMaxHeight},
    Increment = 5,
    CurrentValue = State.GucciGuardHeight,
    Flag = "NN_GucciGuardHeight",
    Callback = function(value) State.GucciGuardHeight = math.clamp(value, 25, State.GucciGuardMaxHeight) end,
})

ProtectionTab:CreateSlider({
    Name = "Spawn Cooldown",
    Range = {1, 8},
    Increment = 0.5,
    CurrentValue = State.GucciGuardSpawnCooldown,
    Flag = "NN_GucciSpawnCooldown",
    Callback = function(value) State.GucciGuardSpawnCooldown = math.clamp(value, 1, 8) end,
})

ProtectionTab:CreateSection("Extreme Map Patrol / Map Orbit Guard")
ProtectionTab:CreateToggle({
    Name = "Extreme Map Patrol Enabled",
    CurrentValue = State.GucciPatrolEnabled,
    Flag = "NN_ExtremeMapPatrol",
    Callback = function(value)
        State.GucciPatrolEnabled = value
        rebuildPatrolWaypoints((getRoot() and getRoot().Position) or nil)
        notify("Gucci Guard", value and "Extreme Map Patrol enabled" or "Extreme Map Patrol disabled", 2)
    end,
})
ProtectionTab:CreateSlider({
    Name = "Patrol Speed / Intensity",
    Range = {0.25, 3},
    Increment = 0.25,
    CurrentValue = State.GucciPatrolIntensity,
    Flag = "NN_GucciPatrolIntensity",
    Callback = function(value) State.GucciPatrolIntensity = math.clamp(value, 0.25, 3) end,
})
ProtectionTab:CreateSlider({
    Name = "Safe Minimum Y",
    Range = {0, 150},
    Increment = 5,
    CurrentValue = State.GucciPatrolSafeMinY,
    Flag = "NN_GucciPatrolSafeY",
    Callback = function(value) State.GucciPatrolSafeMinY = math.clamp(value, 0, 150); rebuildPatrolWaypoints((getRoot() and getRoot().Position) or nil) end,
})
ProtectionTab:CreateSlider({
    Name = "Patrol High Vault Height",
    Range = {50, State.GucciGuardMaxHeight},
    Increment = 5,
    CurrentValue = State.GucciPatrolVaultHeight,
    Flag = "NN_GucciPatrolVault",
    Callback = function(value) State.GucciPatrolVaultHeight = math.clamp(value, 50, State.GucciGuardMaxHeight); rebuildPatrolWaypoints((getRoot() and getRoot().Position) or nil) end,
})
ProtectionTab:CreateSlider({
    Name = "Waypoint Radius",
    Range = {40, 750},
    Increment = 10,
    CurrentValue = State.GucciPatrolWaypointRadius,
    Flag = "NN_GucciPatrolRadius",
    Callback = function(value) State.GucciPatrolWaypointRadius = math.clamp(value, 40, 750); rebuildPatrolWaypoints((getRoot() and getRoot().Position) or nil) end,
})
ProtectionTab:CreateSlider({
    Name = "Waypoint Count",
    Range = {4, 24},
    Increment = 1,
    CurrentValue = State.GucciPatrolWaypointCount,
    Flag = "NN_GucciPatrolCount",
    Callback = function(value) State.GucciPatrolWaypointCount = math.clamp(math.floor(value), 4, 24); rebuildPatrolWaypoints((getRoot() and getRoot().Position) or nil) end,
})
ProtectionTab:CreateSlider({
    Name = "Patrol Update Interval",
    Range = {0.08, 0.6},
    Increment = 0.02,
    CurrentValue = State.GucciPatrolUpdateInterval,
    Flag = "NN_GucciPatrolInterval",
    Callback = function(value) State.GucciPatrolUpdateInterval = math.clamp(value, 0.08, 0.6) end,
})

ProtectionTab:CreateToggle({
    Name = "Retain Gucci Model On Disable",
    CurrentValue = false,
    Flag = "NN_GucciRetain",
    Callback = function(value) State.GucciGuardRetainOnDisable = value end,
})

ProtectionTab:CreateButton({
    Name = "Respawn Gucci Guard Now",
    Callback = function()
        cleanupGucciGuard(true, true)
        State.GucciGuard.RetryAfter = 0
        State.GucciGuard.RecoveryLock = true
        task.spawn(function() enterGucciRecoveryLock("manual respawn") end)
    end,
})

ProtectionTab:CreateButton({
    Name = "Show Gucci Guard Status",
    Callback = function()
        local guard = State.GucciGuard
        local modelName = guard.CurrentGucciModel and guard.CurrentGucciModel.Name or "none"
        local _, currentStatus = getGucciProtectionState()
        notify("Gucci Guard", string.format("active=%s recovery lock=%s model=%s status=%s occupant=%s owner=%s lost=%d failures=%d attempts=%d spawnPending=%s ChildAdded timeout=%.1f Fast Verify %.1fs patrol=%s waypoints=%d backoff=%.1f", tostring(guard.Active), tostring(guard.RecoveryLock), modelName, tostring(currentStatus or guard.LastProtectedStatus), tostring(guard.LastSeatOccupantName), tostring(guard.LastOwnerName), guard.LostCount, guard.ConsecutiveFailures, guard.RecoveryAttempts, tostring(guard.SpawnPending), State.GucciGuardSpawnTimeout, math.max(0, (guard.FastVerifyUntil or 0) - now()), tostring(State.GucciPatrolEnabled), #(guard.PatrolWaypoints or {}), math.max(0, guard.RetryAfter - now())), 8)
    end,
})

trackConnection("ProtectionHeartbeat", RunService.Heartbeat:Connect(function()
    if not State.Enabled then return end
    local root = getRoot()
    local hum = getHumanoid()

    if State.AntiVoid and root and root.Position.Y < State.AntiVoidY then
        root.CFrame = CFrame.new(0, 50, 0)
        root.AssemblyLinearVelocity = Vector3.zero
    end

    if State.AntiRagdoll and root and hum then
        local rag = hum:FindFirstChild("Ragdolled")
        if rag and rag:IsA("BoolValue") and rag.Value then
            local remote = getRemote({"CharacterEvents", "RagdollRemote"})
            if remote then
                fireRateLimited("AntiRagdoll", 0.2, function() remote:FireServer(root, 0) end)
            end
        end
    end

    if State.AntiGrab and root then
        local characterEvents = getCharacterEvents()
        local struggle = characterEvents and characterEvents:FindFirstChild("Struggle")
        local ragdoll = characterEvents and characterEvents:FindFirstChild("RagdollRemote")
        fireRateLimited("AntiGrab", 0.25, function()
            if struggle then struggle:FireServer() end
            if ragdoll then ragdoll:FireServer(root, 0) end
        end)
    end

    if State.GucciGuardEnabled then
        maintainGucciGuard()
    end

    if State.AntiFire and root then
        local hasFire = root:FindFirstChild("FireLight") or root:FindFirstChild("FireParticleEmitter") or root:FindFirstChildOfClass("Fire")
        if hasFire then
            pcall(function()
                local big = Workspace.Map.Hole.PoisonBigHole:FindFirstChild("ExtinguishPart")
                local small = Workspace.Map.Hole.PoisonSmallHole:FindFirstChild("ExtinguishPart")
                local extinguisher = big or small
                if extinguisher then extinguisher.CFrame = root.CFrame end
            end)
        end
    end
end))

trackConnection("AntiExplodeWatcher", Workspace.ChildAdded:Connect(function(obj)
    if not State.AntiExplode then return end
    if not obj:IsA("BasePart") or obj.Name ~= "Part" then return end
    local root = getRoot()
    if root and (root.Position - obj.Position).Magnitude <= 25 then
        pcall(function()
            root.Anchored = true
            task.wait(0.03)
            root.Anchored = false
        end)
    end
end))

--// Visuals / ESP
local VisualTab = Window:CreateTab("Visuals", 4483362458)
VisualTab:CreateSection("Local Debug ESP")

local function removeESP(player)
    local bundle = State.ESP[player]
    if bundle then
        for _, inst in pairs(bundle) do pcall(function() inst:Destroy() end) end
        State.ESP[player] = nil
    end
end

local function applyESP(player)
    if player == LocalPlayer then return end
    removeESP(player)
    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not root or not head then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "NomNomESP_Highlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.65
    highlight.OutlineTransparency = 0
    highlight.Parent = character

    local bill = Instance.new("BillboardGui")
    bill.Name = "NomNomESP_Name"
    bill.Adornee = head
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 180, 0, 44)
    bill.ExtentsOffset = Vector3.new(0, 2.5, 0)
    bill.Parent = character

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextStrokeTransparency = 0
    label.TextColor3 = State.ESPColor
    label.Parent = bill

    State.ESP[player] = { highlight, bill, label }
end

local function refreshESP()
    clearESP()
    for _, player in ipairs(Players:GetPlayers()) do
        applyESP(player)
    end
end

VisualTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "NN_ESP",
    Callback = function(value)
        State.ESPEnabled = value
        if value then refreshESP() else clearESP() end
    end,
})

VisualTab:CreateToggle({
    Name = "Show Names",
    CurrentValue = true,
    Flag = "NN_ESPNames",
    Callback = function(value) State.ESPNames = value end,
})

VisualTab:CreateToggle({
    Name = "Show Distance",
    CurrentValue = true,
    Flag = "NN_ESPDistance",
    Callback = function(value) State.ESPDistance = value end,
})

VisualTab:CreateToggle({
    Name = "Rainbow ESP",
    CurrentValue = false,
    Flag = "NN_ESPRainbow",
    Callback = function(value) State.ESPRainbow = value end,
})

VisualTab:CreateColorPicker({
    Name = "ESP Color",
    Color = State.ESPColor,
    Flag = "NN_ESPColor",
    Callback = function(value) State.ESPColor = value end,
})

VisualTab:CreateButton({
    Name = "Refresh ESP",
    Callback = refreshESP,
})

trackConnection("PlayerAddedESP", Players.PlayerAdded:Connect(function(player)
    trackConnection("ESPCharacter_" .. player.UserId, player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if State.ESPEnabled then applyESP(player) end
    end))
end))

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        trackConnection("ESPCharacter_" .. player.UserId, player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if State.ESPEnabled then applyESP(player) end
        end))
    end
end

trackConnection("ESPUpdate", RunService.RenderStepped:Connect(function()
    if not State.ESPEnabled then return end
    local myRoot = getRoot()
    local hue = (tick() * 0.12) % 1
    local color = State.ESPRainbow and Color3.fromHSV(hue, 0.8, 1) or State.ESPColor
    for player, bundle in pairs(State.ESP) do
        local highlight, bill, label = bundle[1], bundle[2], bundle[3]
        if not player.Character or not highlight.Parent then
            removeESP(player)
            if State.ESPEnabled then applyESP(player) end
        else
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local dist = (myRoot and root) and math.floor((myRoot.Position - root.Position).Magnitude) or 0
            highlight.Enabled = true
            highlight.FillColor = color
            highlight.OutlineColor = color
            bill.Enabled = State.ESPNames
            label.TextColor3 = color
            label.Text = player.DisplayName .. " (@" .. player.Name .. ")" .. (State.ESPDistance and ("\n" .. dist .. " studs") or "")
        end
    end
end))

--// Chat overlay
local ChatTab = Window:CreateTab("Chat", 4483362458)
ChatTab:CreateSection("NomNom Local Chat Overlay")

local ChatGui = Instance.new("ScreenGui")
ChatGui.Name = "NomNomFTAP_ChatOverlay"
ChatGui.ResetOnSpawn = false
ChatGui.DisplayOrder = 1000
ChatGui.Enabled = false
ChatGui.Parent = (RunService:IsStudio() and LocalPlayer:FindFirstChildOfClass("PlayerGui")) or CoreGui
trackInstance(ChatGui)

local ChatFrame = Instance.new("Frame")
ChatFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
ChatFrame.Position = UDim2.new(0.5, -190, 0.5, -155)
ChatFrame.Size = UDim2.new(0, 380, 0, 310)
ChatFrame.Active = true
ChatFrame.Draggable = true
ChatFrame.Parent = ChatGui
Instance.new("UICorner", ChatFrame).CornerRadius = UDim.new(0, 16)

local ChatTitle = Instance.new("TextLabel")
ChatTitle.BackgroundTransparency = 1
ChatTitle.Position = UDim2.new(0, 14, 0, 0)
ChatTitle.Size = UDim2.new(1, -50, 0, 38)
ChatTitle.Font = Enum.Font.GothamBold
ChatTitle.TextSize = 15
ChatTitle.TextXAlignment = Enum.TextXAlignment.Left
ChatTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
ChatTitle.Text = "NomNom Chat • F8"
ChatTitle.Parent = ChatFrame

local CloseChat = Instance.new("TextButton")
CloseChat.BackgroundColor3 = Color3.fromRGB(42, 42, 52)
CloseChat.Position = UDim2.new(1, -34, 0, 8)
CloseChat.Size = UDim2.new(0, 24, 0, 24)
CloseChat.Font = Enum.Font.GothamBold
CloseChat.Text = "×"
CloseChat.TextSize = 16
CloseChat.TextColor3 = Color3.new(1, 1, 1)
CloseChat.Parent = ChatFrame
Instance.new("UICorner", CloseChat).CornerRadius = UDim.new(1, 0)
trackConnection("CloseChat", CloseChat.MouseButton1Click:Connect(function() ChatGui.Enabled = false end))

local History = Instance.new("ScrollingFrame")
History.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
History.BorderSizePixel = 0
History.Position = UDim2.new(0, 10, 0, 42)
History.Size = UDim2.new(1, -20, 1, -95)
History.ScrollBarThickness = 4
History.AutomaticCanvasSize = Enum.AutomaticSize.Y
History.Parent = ChatFrame
Instance.new("UICorner", History).CornerRadius = UDim.new(0, 12)
local HistoryLayout = Instance.new("UIListLayout", History)
HistoryLayout.Padding = UDim.new(0, 5)
HistoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
local HistoryPadding = Instance.new("UIPadding", History)
HistoryPadding.PaddingTop = UDim.new(0, 8)
HistoryPadding.PaddingLeft = UDim.new(0, 8)
HistoryPadding.PaddingRight = UDim.new(0, 8)
HistoryPadding.PaddingBottom = UDim.new(0, 8)

local Input = Instance.new("TextBox")
Input.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
Input.Position = UDim2.new(0, 10, 1, -42)
Input.Size = UDim2.new(1, -70, 0, 32)
Input.Font = Enum.Font.Gotham
Input.PlaceholderText = "Message..."
Input.Text = ""
Input.TextColor3 = Color3.new(1, 1, 1)
Input.TextSize = 13
Input.ClearTextOnFocus = false
Input.Parent = ChatFrame
Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 10)

local Send = Instance.new("TextButton")
Send.BackgroundColor3 = Color3.fromRGB(90, 145, 255)
Send.Position = UDim2.new(1, -52, 1, -42)
Send.Size = UDim2.new(0, 42, 0, 32)
Send.Font = Enum.Font.GothamBold
Send.Text = "→"
Send.TextSize = 18
Send.TextColor3 = Color3.new(1, 1, 1)
Send.Parent = ChatFrame
Instance.new("UICorner", Send).CornerRadius = UDim.new(0, 10)

local function redrawChat()
    for _, child in ipairs(History:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for _, item in ipairs(State.ChatHistory) do
        local bubble = Instance.new("Frame")
        bubble.BackgroundColor3 = item.self and Color3.fromRGB(70, 125, 235) or Color3.fromRGB(35, 35, 46)
        bubble.Size = UDim2.new(1, 0, 0, 0)
        bubble.AutomaticSize = Enum.AutomaticSize.Y
        bubble.Parent = History
        Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 10)
        local pad = Instance.new("UIPadding", bubble)
        pad.PaddingTop = UDim.new(0, 6)
        pad.PaddingBottom = UDim.new(0, 6)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, 0, 0, 0)
        label.AutomaticSize = Enum.AutomaticSize.Y
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextWrapped = true
        label.RichText = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Text = string.format("<b>%s</b>  <font color='rgb(170,170,180)'>%s</font>\n%s", item.user, item.time, item.message)
        label.Parent = bubble
    end
    task.defer(function()
        History.CanvasPosition = Vector2.new(0, History.AbsoluteCanvasSize.Y)
    end)
end

local function addChat(user, message, self)
    message = tostring(message or ""):sub(1, 240)
    table.insert(State.ChatHistory, { user = user, message = message, self = self, time = os.date("%H:%M") })
    while #State.ChatHistory > 50 do table.remove(State.ChatHistory, 1) end
    redrawChat()
end

local function sendChat()
    local text = Input.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return end
    Input.Text = ""
    addChat(LocalPlayer.DisplayName, text, true)
    local ext = getRemote({"GrabEvents", "ExtendGrabLine"})
    if ext then
        fireRateLimited("CustomChat", 0.5, function()
            ext:FireServer("CUSTOMMSG:" .. LocalPlayer.DisplayName .. ":" .. text)
        end)
    end
end

trackConnection("ChatSendButton", Send.MouseButton1Click:Connect(sendChat))
trackConnection("ChatEnter", Input.FocusLost:Connect(function(enter) if enter then sendChat() end end))

local ext = getRemote({"GrabEvents", "ExtendGrabLine"})
if ext then
    trackConnection("ChatIncoming", ext.OnClientEvent:Connect(function(...)
        for _, value in ipairs({ ... }) do
            if typeof(value) == "string" and value:sub(1, 10) == "CUSTOMMSG:" then
                local parts = {}
                for part in value:gmatch("[^:]+") do table.insert(parts, part) end
                if #parts >= 3 then
                    addChat(parts[2], table.concat(parts, ":", 3), false)
                end
            end
        end
    end))
end

addChat("NomNom", "Loaded. Press F8 to toggle chat.", false)

ChatTab:CreateToggle({
    Name = "Enable Chat Overlay",
    CurrentValue = false,
    Flag = "NN_ChatOverlay",
    Callback = function(value)
        State.ChatEnabled = value
        ChatGui.Enabled = value
    end,
})

trackConnection("ChatKeybind", UserInputService.InputBegan:Connect(function(inputObject, processed)
    if processed then return end
    if inputObject.KeyCode == Enum.KeyCode.F8 then
        ChatGui.Enabled = not ChatGui.Enabled
    end
end))

--// Toy / vehicle tools
local ToolsTab = Window:CreateTab("Tools", 4483362458)
ToolsTab:CreateSection("Toy Helpers")

ToolsTab:CreateDropdown({
    Name = "Selected Toy",
    Options = {"DiceBig", "DiceSmall", "YouDecoy", "YouLittle", "NinjaShuriken", "BallSnowball", "TractorGreen", "CreatureBlobman"},
    CurrentOption = {State.SelectedToy},
    Flag = "NN_SelectedToy",
    Callback = function(option)
        State.SelectedToy = type(option) == "table" and option[1] or option
    end,
})

ToolsTab:CreateButton({
    Name = "Spawn Selected Toy",
    Callback = function()
        local root = getRoot()
        if not root then return end
        local ok = spawnToy(State.SelectedToy, root.CFrame * CFrame.new(0, 3, -5), Vector3.zero)
        notify("NomNom FTAP", ok and ("Spawned " .. State.SelectedToy) or "Spawn failed", 2)
    end,
})

ToolsTab:CreateToggle({
    Name = "Massless Grab",
    CurrentValue = false,
    Flag = "NN_MasslessGrab",
    Callback = function(value)
        State.MasslessGrab = value
    end,
})

ToolsTab:CreateSlider({
    Name = "Massless Sense",
    Range = {10, 250},
    Increment = 1,
    CurrentValue = State.MasslessSense,
    Flag = "NN_MasslessSense",
    Callback = function(value) State.MasslessSense = value end,
})

trackConnection("GrabPartsDefenseWatcher", Workspace.ChildAdded:Connect(function(obj)
    if obj.Name ~= "GrabParts" then return end
    task.spawn(function()
        local ok, grabbedPart = pcall(function()
            local grabPart = obj:WaitForChild("GrabPart", 1.5)
            local weld = grabPart and grabPart:WaitForChild("WeldConstraint", 1.5)
            return weld and weld.Part1
        end)
        local owner = nil
        if ok and grabbedPart then
            owner = nearestPlayer(grabbedPart.Position, State.DefensiveScanRadius, false)
        end
        cacheRecentGrab(owner, obj, ok and grabbedPart or nil)
    end)
end))

trackConnection("MasslessWatcher", Workspace.ChildAdded:Connect(function(obj)
    if not State.MasslessGrab or obj.Name ~= "GrabParts" then return end
    task.spawn(function()
        while State.MasslessGrab and obj.Parent do
            local dragPart = obj:FindFirstChild("DragPart")
            local alignPos = dragPart and dragPart:FindFirstChild("AlignPosition")
            local alignOri = dragPart and dragPart:FindFirstChild("AlignOrientation")
            if alignPos then
                alignPos.Responsiveness = State.MasslessSense
                alignPos.MaxForce = math.huge
                alignPos.MaxVelocity = math.huge
            end
            if alignOri then
                alignOri.Responsiveness = State.MasslessSense
                alignOri.MaxTorque = math.huge
            end
            task.wait(0.05)
        end
    end)
end))

ToolsTab:CreateToggle({
    Name = "Super Fling On Release",
    CurrentValue = false,
    Flag = "NN_SuperFling",
    Callback = function(value) State.SuperFling = value end,
})

ToolsTab:CreateSlider({
    Name = "Super Fling Strength",
    Range = {100, 2500},
    Increment = 50,
    CurrentValue = State.SuperFlingStrength,
    Flag = "NN_SuperFlingStrength",
    Callback = function(value) State.SuperFlingStrength = value end,
})

trackConnection("SuperFlingWatcher", Workspace.ChildAdded:Connect(function(obj)
    if obj.Name ~= "GrabParts" then return end
    task.spawn(function()
        local ok, grabbedPart = pcall(function()
            return obj:WaitForChild("GrabPart", 2):WaitForChild("WeldConstraint", 2).Part1
        end)
        if not ok or not grabbedPart then return end
        local bv = Instance.new("BodyVelocity")
        bv.Name = "NomNomReleaseVelocity"
        bv.MaxForce = Vector3.zero
        bv.Parent = grabbedPart
        Debris:AddItem(bv, 3)
        local conn
        conn = obj.AncestryChanged:Connect(function(_, parent)
            if parent ~= nil then return end
            if State.SuperFling and Camera then
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Velocity = Camera.CFrame.LookVector * State.SuperFlingStrength
            end
            Debris:AddItem(bv, 0.5)
            if conn then conn:Disconnect() end
        end)
    end)
end))

--// Authorized target test tools
local TargetTab = Window:CreateTab("Targets", 4483362458)
TargetTab:CreateSection("Authorized Private-Test Targets")

local whitelistInput = ""
TargetTab:CreateInput({
    Name = "Player Name / DisplayName",
    CurrentValue = "",
    PlaceholderText = "Exact name",
    RemoveTextAfterFocusLost = false,
    Flag = "NN_WhitelistInput",
    Callback = function(text) whitelistInput = sanitizeName(text) end,
})

TargetTab:CreateButton({
    Name = "Add Authorized Target",
    Callback = function()
        if whitelistInput ~= "" and not table.find(State.Whitelist, whitelistInput) then
            table.insert(State.Whitelist, whitelistInput)
            notify("NomNom FTAP", "Added authorized target: " .. whitelistInput, 3)
        end
    end,
})

TargetTab:CreateButton({
    Name = "Remove Authorized Target",
    Callback = function()
        for i, name in ipairs(State.Whitelist) do
            if string.lower(name) == string.lower(whitelistInput) then
                table.remove(State.Whitelist, i)
                notify("NomNom FTAP", "Removed: " .. whitelistInput, 3)
                break
            end
        end
    end,
})

TargetTab:CreateButton({
    Name = "Show Authorized List",
    Callback = function()
        notify("Authorized Targets", #State.Whitelist > 0 and table.concat(State.Whitelist, ", ") or "Empty", 5)
    end,
})

TargetTab:CreateToggle({
    Name = "Authorized Targets Only",
    CurrentValue = true,
    Flag = "NN_AuthorizedOnly",
    Callback = function(value) State.AuthorizedTargetsOnly = value end,
})

TargetTab:CreateInput({
    Name = "Selected Defense Target",
    CurrentValue = "",
    PlaceholderText = "Optional exact/partial name",
    RemoveTextAfterFocusLost = false,
    Flag = "NN_SelectedDefenseTarget",
    Callback = function(text)
        State.SelectedTarget = sanitizeName(text)
    end,
})

TargetTab:CreateSection("Defensive Response")

TargetTab:CreateToggle({
    Name = "Enable Loopkill / Kill Detection",
    CurrentValue = true,
    Flag = "NN_DefenseMonitor",
    Callback = function(value)
        State.DefensiveMonitorEnabled = value
    end,
})

TargetTab:CreateToggle({
    Name = "Enable Auto Attack Back (Private Test, legacy gated)",
    CurrentValue = false,
    Flag = "NN_DefenseResponse",
    Callback = function(value)
        State.DefensiveResponseEnabled = value
        notify("NomNom Defense", value and "Auto response armed for authorized targets only" or "Auto response disabled", 3)
    end,
})

TargetTab:CreateDropdown({
    Name = "Defensive Response Mode",
    Options = {"Off", "Mark Only", "Defensive Toy Response", "SuperFling Response if held object exists"},
    CurrentOption = {State.DefensiveResponseMode},
    Flag = "NN_DefenseMode",
    Callback = function(option)
        State.DefensiveResponseMode = type(option) == "table" and option[1] or option
    end,
})

TargetTab:CreateSlider({
    Name = "Detection Scan Radius",
    Range = {15, 150},
    Increment = 5,
    CurrentValue = State.DefensiveScanRadius,
    Flag = "NN_DefenseScanRadius",
    Callback = function(value) State.DefensiveScanRadius = value end,
})

TargetTab:CreateSlider({
    Name = "Response Cooldown",
    Range = {2, 20},
    Increment = 1,
    CurrentValue = State.DefensiveResponseCooldown,
    Flag = "NN_DefenseCooldown",
    Callback = function(value) State.DefensiveResponseCooldown = value end,
})

TargetTab:CreateToggle({
    Name = "Recover via Suspect Seat (Private Test)",
    CurrentValue = false,
    Flag = "NN_RecoverViaSuspectSeat",
    Callback = function(value)
        State.RecoverViaSuspectSeat = value
        notify("NomNom Defense", value and "Authorized suspect seat recovery enabled" or "Suspect seat recovery disabled", 3)
    end,
})

TargetTab:CreateToggle({
    Name = "Authorized Guard Cleanup",
    CurrentValue = false,
    Flag = "NN_AuthorizedGuardCleanup",
    Callback = function(value)
        State.AuthorizedGuardCleanup = value
        notify("NomNom Defense", value and "Authorized Guard Cleanup enabled for visible whitelisted suspect guards only" or "Authorized Guard Cleanup disabled", 3)
    end,
})

TargetTab:CreateToggle({
    Name = "Authorized Counter Response",
    CurrentValue = false,
    Flag = "NN_AuthorizedCounterResponse",
    Callback = function(value)
        State.AuthorizedCounterResponse = value
        notify("NomNom Defense", value and "Authorized Counter Response armed after local recovery starts" or "Authorized Counter Response disabled", 3)
    end,
})

TargetTab:CreateButton({
    Name = "Show Defense Log",
    Callback = function()
        local recent = {}
        for i = math.max(1, #State.DefensiveLog - 5), #State.DefensiveLog do
            table.insert(recent, State.DefensiveLog[i])
        end
        notify("Defense Log", #recent > 0 and table.concat(recent, "\n") or "No detections recorded", 8)
    end,
})

TargetTab:CreateButton({
    Name = "Mark Suspected Target Now",
    Callback = function()
        local root = getRoot()
        local target, source = chooseSuspectedAttacker("manual mark", root and root.Position)
        if target then markSuspectedAttacker(target, source) end
        logDefense("manual mark [" .. tostring(source) .. "]", target)
    end,
})

TargetTab:CreateButton({
    Name = "Recover via Suspect Seat Now",
    Callback = function()
        if recoverViaSuspectSeat() then
            notify("NomNom Defense", "Attempted authorized suspect seat recovery", 3)
        else
            notify("NomNom Defense", "No authorized suspected guard seat available", 3)
        end
    end,
})

TargetTab:CreateParagraph({
    Title = "Target Safety",
    Content = "Targeted test helpers only scan whitelisted or NomNomAuthorizedTarget players by default. Suspect marks persist across respawn in local state; if no valid authorized target exists, the script only logs/marks and focuses on re-enabling Gucci Guard. Authorized Guard Cleanup and Authorized Counter Response are off by default and only run after local Gucci recovery starts.",
})

--// Vehicle/debug map helpers
local VehicleTab = Window:CreateTab("Vehicles", 4483362458)
VehicleTab:CreateSection("UFO Hitbox Debug")

local UFOCache = { Model = nil, Hitboxes = {}, LastRefresh = 0 }
local function getUFOHitboxes()
    local t = now()
    if t - UFOCache.LastRefresh < 1 and #UFOCache.Hitboxes > 0 then
        return UFOCache.Hitboxes
    end
    UFOCache.LastRefresh = t
    table.clear(UFOCache.Hitboxes)
    pcall(function()
        local model = Workspace.Map.AlwaysHereTweenedObjects.OuterUFO.Object.ObjectModel
        UFOCache.Model = model
        for _, child in ipairs(model:GetChildren()) do
            if child:IsA("BasePart") and child.Name:lower():find("hitbox") then
                table.insert(UFOCache.Hitboxes, child)
            end
        end
    end)
    return UFOCache.Hitboxes
end

VehicleTab:CreateToggle({
    Name = "UFO Hitboxes Follow",
    CurrentValue = false,
    Flag = "NN_UFOFollow",
    Callback = function(value)
        State.UFOFollow = value
        if value then State.UFOSpin = false end
    end,
})

VehicleTab:CreateToggle({
    Name = "UFO Hitboxes Spin",
    CurrentValue = false,
    Flag = "NN_UFOSpin",
    Callback = function(value)
        State.UFOSpin = value
        if value then State.UFOFollow = false end
    end,
})

VehicleTab:CreateSlider({
    Name = "UFO Spin Radius",
    Range = {4, 40},
    Increment = 1,
    CurrentValue = State.UFOSpinRadius,
    Flag = "NN_UFORadius",
    Callback = function(value) State.UFOSpinRadius = value end,
})

VehicleTab:CreateSlider({
    Name = "UFO Height",
    Range = {2, 40},
    Increment = 1,
    CurrentValue = State.UFOHeight,
    Flag = "NN_UFOHeight",
    Callback = function(value) State.UFOHeight = value end,
})

local ufoAngle = 0
trackConnection("UFOHitboxUpdate", RunService.RenderStepped:Connect(function(dt)
    if not State.UFOFollow and not State.UFOSpin then return end
    local root = getRoot()
    if not root then return end
    local hitboxes = getUFOHitboxes()
    if #hitboxes == 0 then return end
    if State.UFOSpin then
        ufoAngle += dt * State.UFOSpinSpeed
        for i, hitbox in ipairs(hitboxes) do
            local angle = ufoAngle + (i / #hitboxes) * math.pi * 2
            local offset = Vector3.new(math.cos(angle) * State.UFOSpinRadius, State.UFOHeight, math.sin(angle) * State.UFOSpinRadius)
            pcall(function() hitbox.CFrame = CFrame.new(root.Position + offset) end)
        end
    elseif State.UFOFollow then
        for _, hitbox in ipairs(hitboxes) do
            pcall(function() hitbox.CFrame = CFrame.new(root.Position + Vector3.new(0, State.UFOHeight, 0)) end)
        end
    end
end))

trackConnection("DefenseMovementMonitor", RunService.Heartbeat:Connect(function()
    if not State.Enabled then return end
    if State.GucciGuardEnabled and State.GucciGuard.RecoveryLock then
        maintainGucciGuard("recovery heartbeat")
    end
    if not State.DefensiveMonitorEnabled then return end
    local root = getRoot()
    if not root then
        if State.GucciGuardEnabled then enterGucciRecoveryLock("root reacquisition") end
        return
    end
    local pos = root.Position
    local last = State.LastRootPosition
    State.LastRootPosition = pos

    if State.AntiVoid and pos.Y < State.AntiVoidY then
        recordDefenseSignal("void/fall indicator", pos)
    end

    if last then
        local delta = (pos - last).Magnitude
        if delta >= State.DefensiveForcedMoveStuds then
            if now() - State.LastMoveSpike < 5 then
                State.MoveSpikeCount += 1
            else
                State.MoveSpikeCount = 1
            end
            State.LastMoveSpike = now()
            if State.MoveSpikeCount >= 2 then
                local target = select(1, chooseSuspectedAttacker("repeated forced movement", pos))
                if target then markSuspectedAttacker(target, "repeated forced movement") end
                recordDefenseSignal("repeated forced movement", pos)
                State.MoveSpikeCount = 0
            end
        end
    end
end))

--// Respawn reapply
local function handleCharacterReady(char, reason)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3)
    local root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)
    if hum then
        hum.WalkSpeed = State.WalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = State.JumpPower
    end
    attachHumanoidMonitor(char)
    if State.GucciGuardEnabled then
        State.GucciGuard.RetryAfter = 0
        State.GucciGuard.RecoveryLock = true
        if root then
            State.GucciGuard.RecoveryWaypoint = clampSafePatrolPosition(root.Position + Vector3.new(0, State.GucciPatrolVaultHeight or 135, 0))
        end
        task.defer(function()
            if State.Enabled and State.GucciGuardEnabled then enterGucciRecoveryLock(reason or "character root acquired") end
        end)
    end
    if State.ESPEnabled then refreshESP() end
end

trackConnection("CharacterAdded", LocalPlayer.CharacterAdded:Connect(function(char)
    task.defer(function() handleCharacterReady(char, "character respawn") end)
end))

if LocalPlayer.Character then
    task.defer(function() handleCharacterReady(LocalPlayer.Character, "initial character") end)
end

--// Final settings
local SettingsTab = Window:CreateTab("Settings", 4483362458)
SettingsTab:CreateSection("Build Info")
SettingsTab:CreateParagraph({
    Title = "NomNom FTAP Roo Build",
    Content = "Bundled standalone from src reference modules. Focus: Extreme Map Patrol / Map Orbit Guard, ChildAdded spawn wait with spawnPending, Fast Verify, recovery lock, safe-Y patrol, The Wourld-inspired anti-steal-seat/anti-destroy verified protected checks, authorized cleanup/counter-response gates, respawn/root reacquisition, local UI/visual/chat/tools, and low-noise bounded loops. See SOURCE_INSIGHTS for mined safe patterns.",
})
SettingsTab:CreateButton({
    Name = "Cleanup / Unload Script",
    Callback = function()
        cleanup()
        notify("NomNom FTAP", "Cleaned up current build", 2)
    end,
})

notify("NomNom FTAP", "Roo consolidated build loaded. F8 toggles chat.", 5)
print("[NomNomFTAP] Roo consolidated build loaded")
