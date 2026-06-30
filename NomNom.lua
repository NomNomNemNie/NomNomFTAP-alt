-- NomNom.lua - unified Wourld-style Obsidian integration for NomNomFTAP-alt.
-- Built from Source/Strong/The Wourld, Source/Strong/NoName, and Source/Strong/XOCO.
-- No lazy packs, no encoded payloads, no automatic public chat.

(function()
    local RUNTIME_KEY = "__NomNomFTAPAltUnified_v20260630_nonpack"
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local previous = env[RUNTIME_KEY]
    if type(previous) == "table" and type(previous.cleanup) == "function" then
        pcall(previous.cleanup)
    end

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local StarterGui = game:GetService("StarterGui")
    local Lighting = game:GetService("Lighting")
    local Workspace = workspace
    local LocalPlayer = Players.LocalPlayer

    local runtime = {
        connections = {},
        tasks = {},
        instances = {},
        toggles = {},
        values = {
            walkSpeed = 5,
            jumpPower = 60,
            flingPower = 600,
            auraRange = 40,
            lineDistanceStep = 7,
            lineResponsiveness = 30,
            selectedMap = "Green House",
            gucciToy = "TractorGreen",
            inputToy = "FoodHamburger",
            antiKickToy = "SpookyCandle1",
        },
        character = nil,
        humanoid = nil,
        root = nil,
        head = nil,
        inventory = nil,
        lastNotify = {},
        gucci = { active = false, toy = nil, connection = nil, destroyConnection = nil, busy = false, safeCFrame = nil },
        mapPoints = {
            ["Green House"] = CFrame.new(-548.305054, -2.45424771, 79.3213348),
            ["Pink House"] = CFrame.new(-475.493835, -2.70774508, -159.395279),
            ["Witch House"] = CFrame.new(270.225922, -2.48055029, 458.186493),
            ["Blue House"] = CFrame.new(501.939911, 88.2323608, -349.129211),
            ["China House"] = CFrame.new(545.441833, 128.004593, -99.4881439),
        },
    }
    env[RUNTIME_KEY] = runtime

    local function track(conn)
        if conn then table.insert(runtime.connections, conn) end
        return conn
    end

    local function trackInstance(obj)
        if obj then table.insert(runtime.instances, obj) end
        return obj
    end

    local function disconnectKey(key)
        local conn = runtime.connections[key]
        if conn and conn.Disconnect then pcall(function() conn:Disconnect() end) end
        runtime.connections[key] = nil
    end

    local function setKeyConnection(key, conn)
        disconnectKey(key)
        runtime.connections[key] = conn
        return conn
    end

    function runtime.cleanup()
        for key, conn in pairs(runtime.connections) do
            pcall(function() if conn and conn.Disconnect then conn:Disconnect() end end)
            runtime.connections[key] = nil
        end
        for _, th in ipairs(runtime.tasks) do
            pcall(function() task.cancel(th) end)
        end
        runtime.tasks = {}
        for _, obj in ipairs(runtime.instances) do
            pcall(function() if obj and obj.Parent then obj:Destroy() end end)
        end
        runtime.instances = {}
        if runtime.Library and runtime.Library.Unload then pcall(function() runtime.Library:Unload() end) end
        if runtime.Window and runtime.Window.Unload then pcall(function() runtime.Window:Unload() end) end
    end

    local function spawnTask(fn)
        local th = task.spawn(fn)
        table.insert(runtime.tasks, th)
        return th
    end

    local function notify(title, text, cooldown)
        local key = tostring(title) .. tostring(text)
        local now = os.clock()
        if cooldown and runtime.lastNotify[key] and now - runtime.lastNotify[key] < cooldown then return end
        runtime.lastNotify[key] = now
        pcall(function()
            StarterGui:SetCore("SendNotification", { Title = tostring(title or "NomNom"), Text = tostring(text or ""), Duration = 4 })
        end)
        if runtime.Library and runtime.Library.Notify then
            pcall(function() runtime.Library:Notify(tostring(title or "NomNom"), tostring(text or ""), 4) end)
            pcall(function() runtime.Library:Notify({ Title = tostring(title or "NomNom"), Content = tostring(text or ""), Duration = 4 }) end)
        end
    end

    local function get(path, timeout)
        local node = path[1]
        for i = 2, #path do
            if not node then return nil end
            node = node:FindFirstChild(path[i]) or node:WaitForChild(path[i], timeout or 2)
        end
        return node
    end

    local Remotes = {
        GrabEvents = ReplicatedStorage:WaitForChild("GrabEvents", 10),
        MenuToys = ReplicatedStorage:WaitForChild("MenuToys", 10),
        CharacterEvents = ReplicatedStorage:WaitForChild("CharacterEvents", 10),
        PlayerEvents = ReplicatedStorage:WaitForChild("PlayerEvents", 10),
        DataEvents = ReplicatedStorage:WaitForChild("DataEvents", 10),
        GameCorrectionEvents = ReplicatedStorage:WaitForChild("GameCorrectionEvents", 10),
    }
    Remotes.SetNetworkOwner = Remotes.GrabEvents and Remotes.GrabEvents:WaitForChild("SetNetworkOwner", 10)
    Remotes.CreateGrabLine = Remotes.GrabEvents and Remotes.GrabEvents:WaitForChild("CreateGrabLine", 10)
    Remotes.DestroyGrabLine = Remotes.GrabEvents and Remotes.GrabEvents:WaitForChild("DestroyGrabLine", 10)
    Remotes.SpawnToy = Remotes.MenuToys and Remotes.MenuToys:WaitForChild("SpawnToyRemoteFunction", 10)
    Remotes.DestroyToy = Remotes.MenuToys and Remotes.MenuToys:WaitForChild("DestroyToy", 10)
    Remotes.Ragdoll = Remotes.CharacterEvents and Remotes.CharacterEvents:WaitForChild("RagdollRemote", 10)
    Remotes.Struggle = Remotes.CharacterEvents and Remotes.CharacterEvents:WaitForChild("Struggle", 10)
    Remotes.Sticky = Remotes.PlayerEvents and Remotes.PlayerEvents:WaitForChild("StickyPartEvent", 10)
    Remotes.LineColor = Remotes.DataEvents and Remotes.DataEvents:WaitForChild("UpdateLineColorsEvent", 10)
    Remotes.Correction = Remotes.GameCorrectionEvents and Remotes.GameCorrectionEvents:FindFirstChild("GameCorrectionsNotify")

    local function refreshCharacter(char)
        runtime.character = char or LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        runtime.humanoid = runtime.character:FindFirstChildOfClass("Humanoid") or runtime.character:WaitForChild("Humanoid", 5)
        runtime.root = runtime.character:FindFirstChild("HumanoidRootPart") or runtime.character:WaitForChild("HumanoidRootPart", 5)
        runtime.head = runtime.character:FindFirstChild("Head") or runtime.character:WaitForChild("Head", 5)
        runtime.inventory = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys") or Workspace:WaitForChild(LocalPlayer.Name .. "SpawnedInToys", 5)
        if runtime.toggles.noVoidDespawn then Workspace.FallenPartsDestroyHeight = -1000000000 end
        if runtime.toggles.antiMassless and runtime.root then runtime.root.Massless = false end
    end

    refreshCharacter(LocalPlayer.Character)
    track(LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.25)
        refreshCharacter(char)
        if runtime.toggles.verifiedProtection then
            task.defer(function() runtime.startVerifiedProtection() end)
        end
    end))

    local function charParts()
        return runtime.character, runtime.humanoid, runtime.root, runtime.head
    end

    local function safeFire(remote, ...)
        if remote then pcall(function(...) remote:FireServer(...) end, ...) end
    end

    local function safeInvoke(remote, ...)
        if not remote then return nil end
        local args = {...}
        local ok, result = pcall(function() return remote:InvokeServer(table.unpack(args)) end)
        if ok then return result end
        return nil
    end

    local function sno(part)
        if part and Remotes.SetNetworkOwner then safeFire(Remotes.SetNetworkOwner, part, part.CFrame) end
    end

    local function destroyToy(toy)
        if toy and Remotes.DestroyToy then safeFire(Remotes.DestroyToy, toy) end
    end

    local function stopVelocity(part)
        if part then
            pcall(function()
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end

    local function checkHome()
        local plots = Workspace:FindFirstChild("Plots")
        local plotItems = Workspace:FindFirstChild("PlotItems")
        if not plots or not plotItems then return nil end
        for i = 1, 5 do
            local plot = plots:FindFirstChild("Plot" .. i)
            local owners = plot and plot:FindFirstChild("PlotSign") and plot.PlotSign:FindFirstChild("ThisPlotsOwners")
            if owners then
                for _, owner in ipairs(owners:GetChildren()) do
                    if owner.Value == LocalPlayer.Name then
                        return plotItems:FindFirstChild("Plot" .. i), plot
                    end
                end
            end
        end
        return nil
    end

    local function spawnToy(name, cf, velocity, timeout)
        refreshCharacter(LocalPlayer.Character)
        local inv = runtime.inventory or Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
        if not inv or not Remotes.SpawnToy then return nil end
        local canSpawn = LocalPlayer:FindFirstChild("CanSpawnToy")
        local inPlot = LocalPlayer:FindFirstChild("InPlot")
        local inOwnedPlot = LocalPlayer:FindFirstChild("InOwnedPlot")
        if inPlot and inOwnedPlot and inPlot.Value and not inOwnedPlot.Value then
            local t = os.clock()
            repeat task.wait(0.05) until not inPlot.Value or os.clock() - t > 2
        end
        if canSpawn and not canSpawn.Value then
            local t = os.clock()
            repeat task.wait(0.05) until canSpawn.Value or os.clock() - t > 2
        end
        local container = inv
        if inOwnedPlot and inOwnedPlot.Value then
            container = checkHome() or inv
        end
        local found
        local conn
        conn = container.ChildAdded:Connect(function(child)
            if child.Name == name then found = child end
        end)
        track(conn)
        task.spawn(function()
            safeInvoke(Remotes.SpawnToy, name, cf or (runtime.root and runtime.root.CFrame * CFrame.new(0, 8, -8)) or CFrame.new(), velocity or Vector3.zero)
        end)
        local start = os.clock()
        repeat
            found = found or container:FindFirstChild(name)
            task.wait(0.03)
        until found or os.clock() - start > (timeout or 3)
        pcall(function() conn:Disconnect() end)
        return found
    end

    local function getNearestPlayer(range)
        local _, _, root = charParts()
        if not root then return nil end
        local best, bestDist
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local c = player.Character
                local r = c and c:FindFirstChild("HumanoidRootPart")
                local h = c and c:FindFirstChildOfClass("Humanoid")
                if r and h and h.Health > 0 then
                    local d = (r.Position - root.Position).Magnitude
                    if d <= (range or math.huge) and (not bestDist or d < bestDist) then
                        best, bestDist = player, d
                    end
                end
            end
        end
        return best, bestDist
    end

    local function setLoop(name, enabled, callback, interval)
        runtime.toggles[name] = enabled
        disconnectKey("loop_" .. name)
        if enabled then
            local acc = 0
            setKeyConnection("loop_" .. name, RunService.Heartbeat:Connect(function(dt)
                acc += dt
                if acc >= (interval or 0) then
                    acc = 0
                    if runtime.toggles[name] then pcall(callback) end
                end
            end))
        end
    end

    local function struggleOnce()
        safeFire(Remotes.Struggle, "Unbind")
        safeFire(Remotes.Struggle, LocalPlayer)
        local _, _, root = charParts()
        if root then safeFire(Remotes.Ragdoll, root, 0) end
    end

    function runtime.startVerifiedProtection()
        runtime.toggles.verifiedProtection = true
        setLoop("verifiedProtectionLoop", true, function()
            local char, hum, root, head = charParts()
            if not (char and hum and root and head) then return end
            local isHeld = LocalPlayer:FindFirstChild("IsHeld")
            local grabbed = (isHeld and isHeld.Value) or head:FindFirstChild("PartOwner") ~= nil
            if grabbed then
                root.Anchored = true
                hum.Sit = false
                hum.AutoRotate = true
                struggleOnce()
                stopVelocity(root)
                root.CFrame = root.CFrame + hum.MoveDirection * 0.45
            else
                if root.Anchored and not runtime.toggles.recoveryLock then root.Anchored = false end
            end
            if runtime.toggles.antiSeatSteal and hum.Sit and hum.SeatPart and not tostring(hum.SeatPart.Parent):find("CreatureBlobman") then
                hum.Sit = false
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            end
            if runtime.toggles.antiMassless and root.Massless then root.Massless = false end
        end, 0.03)
    end

    local function stopVerifiedProtection()
        runtime.toggles.verifiedProtection = false
        setLoop("verifiedProtectionLoop", false, function() end)
        local _, _, root = charParts()
        if root then root.Anchored = false end
    end

    local function clearGucci()
        local g = runtime.gucci
        g.active = false
        g.busy = false
        if g.connection then pcall(function() g.connection:Disconnect() end) g.connection = nil end
        if g.destroyConnection then pcall(function() g.destroyConnection:Disconnect() end) g.destroyConnection = nil end
        local inv = runtime.inventory or Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
        if inv then
            for _, toy in ipairs(inv:GetChildren()) do
                if toy.Name == "NomNomGucci" or toy.Name == "AutoGucci" or toy.Name == runtime.values.gucciToy then
                    destroyToy(toy)
                end
            end
        end
    end

    local function buildGucciToy(auto)
        if runtime.gucci.busy then return end
        runtime.gucci.busy = true
        local char, hum, root = charParts()
        if not (char and hum and root) then runtime.gucci.busy = false return end
        runtime.gucci.safeCFrame = root.CFrame
        local toyName = runtime.values.gucciToy or "TractorGreen"
        local toy = spawnToy(toyName, root.CFrame * CFrame.new(0, 14, 20), Vector3.zero, 3)
        if not toy then runtime.gucci.busy = false notify("Gucci", "Toy spawn failed", 2) return end
        runtime.gucci.toy = toy
        toy.Name = "NomNomGucci"
        local seat = toy:FindFirstChild("VehicleSeat") or toy:WaitForChild("VehicleSeat", 2)
        if not seat then runtime.gucci.busy = false return end
        for _, part in ipairs(toy:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
            end
        end
        local deadline = os.clock() + 0.8
        while os.clock() < deadline do
            seat:Sit(hum)
            safeFire(Remotes.Ragdoll, root, 0)
            task.wait(0.05)
        end
        hum.Sit = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        task.defer(function()
            task.wait(0.15)
            if toy and toy.Parent then
                toy:PivotTo(CFrame.new(0, 1000000, 0))
                local bp = Instance.new("BodyPosition")
                bp.Name = "NomNomGucciHold"
                bp.Position = Vector3.new(0, 1000000, 0)
                bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bp.Parent = toy.PrimaryPart or seat
                trackInstance(bp)
            end
        end)
        runtime.gucci.active = auto or runtime.gucci.active
        runtime.gucci.busy = false
        notify("Gucci", "Protection bound", 2)
    end

    local function startAutoGucci(enabled)
        runtime.toggles.autoGucci = enabled
        if not enabled then clearGucci() return end
        buildGucciToy(true)
        disconnectKey("autoGucciWatch")
        setKeyConnection("autoGucciWatch", RunService.Heartbeat:Connect(function()
            if not runtime.toggles.autoGucci or runtime.gucci.busy then return end
            local _, hum, root, head = charParts()
            if not (hum and root and head) or hum.Health <= 0 then return end
            local isHeld = LocalPlayer:FindFirstChild("IsHeld")
            local needs = (isHeld and isHeld.Value) or hum.Sit or head:FindFirstChild("PartOwner") ~= nil
            local owned = true
            if type(isnetworkowner) == "function" then pcall(function() owned = isnetworkowner(root) end) end
            if needs or not owned or not (runtime.gucci.toy and runtime.gucci.toy.Parent) then
                buildGucciToy(true)
            end
        end))
    end

    local function setAntiDestroy(enabled)
        runtime.toggles.antiDestroy = enabled
        disconnectKey("antiDestroyWatch")
        if enabled then
            setKeyConnection("antiDestroyWatch", RunService.Heartbeat:Connect(function()
                local inv = runtime.inventory
                if not inv then return end
                for _, toy in ipairs(inv:GetChildren()) do
                    if toy.Name == "NomNomGucci" or toy.Name == "AutoGucci" then
                        for _, part in ipairs(toy:GetDescendants()) do
                            if part:IsA("BasePart") then stopVelocity(part) end
                        end
                    end
                end
            end))
        end
    end

    local function setHighPatrol(enabled)
        runtime.toggles.highPatrol = enabled
        disconnectKey("highPatrol")
        if enabled then
            local saved
            setKeyConnection("highPatrol", RunService.Heartbeat:Connect(function()
                local _, _, root = charParts()
                if not root then return end
                saved = saved or root.CFrame
                if root.Position.Y < -50 then root.CFrame = saved end
            end))
        end
    end

    local function setAntiPaint(enabled)
        runtime.toggles.antiPaint = enabled
        disconnectKey("antiPaintNew")
        local function remove(obj)
            if runtime.toggles.antiPaint and obj.Name == "PaintPlayerPart" then pcall(function() obj:Destroy() end) end
        end
        if enabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do remove(obj) end
            setKeyConnection("antiPaintNew", Workspace.DescendantAdded:Connect(function(obj) task.defer(remove, obj) end))
        end
    end

    local function setAntiBurn(enabled)
        runtime.toggles.antiBurn = enabled
        disconnectKey("antiBurn")
        if not enabled then return end
        local _, hum, root = charParts()
        local fireDebounce = hum and hum:FindFirstChild("FireDebounce")
        if fireDebounce then
            setKeyConnection("antiBurn", fireDebounce:GetPropertyChangedSignal("Value"):Connect(function()
                if fireDebounce.Value and root then
                    local old = root.CFrame
                    local barrier = get({Workspace, "Map", "Hole", "PoisonBigHole", "ExtinguishPart"}, 1)
                    if barrier and barrier:IsA("BasePart") then
                        local oldPos = barrier.Position
                        local deadline = os.clock() + 2
                        repeat
                            barrier.Position = root.Position
                            task.wait()
                        until not fireDebounce.Value or os.clock() > deadline
                        barrier.Position = oldPos
                        root.CFrame = old
                    end
                end
            end))
        end
    end

    local function setAntiBlob(enabled)
        runtime.toggles.antiBlob = enabled
        disconnectKey("antiBlobLoop")
        if enabled then
            setKeyConnection("antiBlobLoop", RunService.Heartbeat:Connect(function()
                local char, _, root = charParts()
                if not (char and root) then return end
                for _, part in ipairs(char:GetChildren()) do
                    if part:IsA("BasePart") and part.Massless then
                        part.Massless = false
                        root.AssemblyLinearVelocity = Vector3.new(0, 250, 0)
                        struggleOnce()
                    end
                end
                for _, folder in ipairs(Workspace:GetChildren()) do
                    if folder.Name:find("SpawnedInToys") or folder.Name:match("Plot%d") then
                        for _, blob in ipairs(folder:GetDescendants()) do
                            if blob.Name == "CreatureBlobman" then
                                local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
                                local drop = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
                                if drop then
                                    for _, weldName in ipairs({"RightWeld", "LeftWeld"}) do
                                        local weld = blob:FindFirstChild(weldName, true)
                                        if weld then pcall(function() drop:FireServer(weld, root) end) end
                                    end
                                end
                            end
                        end
                    end
                end
            end))
        end
    end

    local function setWalkSpeed(enabled)
        runtime.toggles.walkSpeed = enabled
        disconnectKey("walkSpeed")
        if enabled then
            setKeyConnection("walkSpeed", RunService.Stepped:Connect(function()
                local _, hum, root = charParts()
                if hum and root and hum.MoveDirection.Magnitude > 0 then
                    root.CFrame = root.CFrame + hum.MoveDirection * ((16 * runtime.values.walkSpeed) / 10)
                end
            end))
        end
    end

    local function setInfinityJump(enabled)
        runtime.toggles.infinityJump = enabled
        disconnectKey("infinityJump")
        if enabled then
            setKeyConnection("infinityJump", UserInputService.JumpRequest:Connect(function()
                local _, hum = charParts()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end))
        end
    end

    local function setSuperGrab(enabled)
        runtime.toggles.superGrab = enabled
        disconnectKey("superGrabAdd")
        disconnectKey("superGrabInput")
        disconnectKey("superGrabRemove")
        local grabbed
        if enabled then
            setKeyConnection("superGrabAdd", Workspace.ChildAdded:Connect(function(child)
                if child.Name == "GrabParts" then
                    local grab = child:WaitForChild("GrabPart", 1)
                    local weld = grab and grab:WaitForChild("WeldConstraint", 1)
                    grabbed = weld and weld.Part1
                end
            end))
            setKeyConnection("superGrabInput", UserInputService.InputBegan:Connect(function(input, processed)
                if processed then return end
                if input.UserInputType == Enum.UserInputType.MouseButton2 and grabbed then
                    local bv = Instance.new("BodyVelocity")
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Velocity = Workspace.CurrentCamera.CFrame.LookVector * runtime.values.flingPower
                    bv.Parent = grabbed
                    game:GetService("Debris"):AddItem(bv, 4)
                    grabbed = nil
                end
            end))
            setKeyConnection("superGrabRemove", Workspace.ChildRemoved:Connect(function(child)
                if child.Name == "GrabParts" then grabbed = nil end
            end))
        end
    end

    local function setLineExtend(enabled)
        runtime.toggles.lineExtend = enabled
        disconnectKey("lineWheel")
        disconnectKey("lineAdded")
        runtime.values.lineDistance = 0
        if enabled then
            setKeyConnection("lineWheel", UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseWheel then
                    runtime.values.lineDistance = math.max(3, runtime.values.lineDistance or 3)
                    runtime.values.lineDistance += input.Position.Z > 0 and runtime.values.lineDistanceStep or -runtime.values.lineDistanceStep
                end
            end))
            setKeyConnection("lineAdded", Workspace.ChildAdded:Connect(function(child)
                if child.Name == "GrabParts" and child:IsA("Model") then
                    local drag = child:WaitForChild("DragPart", 1)
                    if not drag then return end
                    local clone = drag:Clone()
                    clone.Name = "NomNomDragPart"
                    clone.Parent = child
                    runtime.values.lineDistance = (clone.Position - Workspace.CurrentCamera.CFrame.Position).Magnitude
                    local align = clone:FindFirstChildOfClass("AlignPosition")
                    if align and clone:FindFirstChild("DragAttach") then align.Attachment1 = clone.DragAttach end
                    if drag:FindFirstChildOfClass("AlignPosition") then drag:FindFirstChildOfClass("AlignPosition").Enabled = false end
                    spawnTask(function()
                        while child.Parent and clone.Parent and runtime.toggles.lineExtend do
                            clone.Position = Workspace.CurrentCamera.CFrame.Position + Workspace.CurrentCamera.CFrame.LookVector * (runtime.values.lineDistance or 15)
                            task.wait()
                        end
                    end)
                end
            end))
        end
    end

    local function setGrabMods(enabled)
        runtime.toggles.grabMods = enabled
        disconnectKey("grabMods")
        if enabled then
            setKeyConnection("grabMods", Workspace.ChildAdded:Connect(function(child)
                if child.Name ~= "GrabParts" then return end
                task.wait(0.1)
                local drag = child:FindFirstChild("NomNomDragPart") or child:FindFirstChild("DragPart")
                if drag then
                    for _, obj in ipairs(drag:GetDescendants()) do
                        if obj:IsA("AlignPosition") then
                            obj.Responsiveness = runtime.values.lineResponsiveness
                            obj.MaxForce = math.huge
                            obj.MaxVelocity = math.huge
                        elseif obj:IsA("AlignOrientation") then
                            obj.Responsiveness = runtime.values.lineResponsiveness
                            obj.MaxTorque = math.huge
                        end
                    end
                end
                local grab = child:FindFirstChild("GrabPart")
                local weld = grab and grab:FindFirstChild("WeldConstraint")
                local part = weld and weld.Part1
                local parent = part and part.Parent
                local root = parent and parent:FindFirstChild("HumanoidRootPart")
                if runtime.toggles.spinGrab and root then
                    local bav = Instance.new("BodyAngularVelocity")
                    bav.AngularVelocity = Vector3.new(0, 10, 0)
                    bav.MaxTorque = Vector3.new(0, math.huge, 0)
                    bav.Parent = root
                    game:GetService("Debris"):AddItem(bav, 3)
                end
                if runtime.toggles.ragdollGrab and root then
                    safeFire(Remotes.Ragdoll, root, 1)
                end
            end))
        end
    end

    local function setAura(name, enabled, action)
        runtime.toggles[name] = enabled
        disconnectKey(name)
        if enabled then
            setKeyConnection(name, RunService.Heartbeat:Connect(function()
                local target = getNearestPlayer(runtime.values.auraRange)
                if target and target.Character then
                    local root = target.Character:FindFirstChild("HumanoidRootPart")
                    if root then action(target, root) end
                end
            end))
        end
    end

    local function setPlayerESP(enabled)
        runtime.toggles.playerESP = enabled
        disconnectKey("espRefresh")
        local function clear()
            for _, player in ipairs(Players:GetPlayers()) do
                local head = player.Character and player.Character:FindFirstChild("Head")
                local gui = head and head:FindFirstChild("NomNomESP")
                if gui then gui:Destroy() end
            end
        end
        if not enabled then clear() return end
        local function add(player)
            if player == LocalPlayer then return end
            local head = player.Character and player.Character:FindFirstChild("Head")
            if not head or head:FindFirstChild("NomNomESP") then return end
            local gui = Instance.new("BillboardGui")
            gui.Name = "NomNomESP"
            gui.Size = UDim2.new(0, 140, 0, 40)
            gui.StudsOffset = Vector3.new(0, 3, 0)
            gui.AlwaysOnTop = true
            gui.Adornee = head
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, 0, 1, 0)
            label.Text = player.Name .. " (@" .. player.DisplayName .. ")"
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextStrokeTransparency = 0
            label.TextScaled = true
            label.Parent = gui
            gui.Parent = head
            trackInstance(gui)
        end
        setKeyConnection("espRefresh", RunService.Heartbeat:Connect(function()
            for _, player in ipairs(Players:GetPlayers()) do add(player) end
        end))
    end

    local function setPCLDESP(enabled)
        runtime.toggles.pcldESP = enabled
        disconnectKey("pcldESP")
        local function remove(obj)
            local esp = obj:FindFirstChild("NomNomPCLD")
            if esp then esp:Destroy() end
        end
        local function add(obj)
            if obj.Name == "PlayerCharacterLocationDetector" and obj:IsA("BasePart") and not obj:FindFirstChild("NomNomPCLD") then
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "NomNomPCLD"
                box.Size = obj.Size
                box.AlwaysOnTop = true
                box.ZIndex = 10
                box.Color3 = Color3.fromRGB(0, 255, 255)
                box.Transparency = 0.65
                box.Adornee = obj
                box.Parent = obj
                trackInstance(box)
            end
        end
        for _, obj in ipairs(Workspace:GetChildren()) do if enabled then add(obj) else remove(obj) end end
        if enabled then setKeyConnection("pcldESP", Workspace.ChildAdded:Connect(add)) end
    end

    local function setAntiKickItem(enabled)
        runtime.toggles.antiKickItem = enabled
        disconnectKey("antiKickItem")
        if enabled then
            setKeyConnection("antiKickItem", RunService.Heartbeat:Connect(function()
                local _, _, root = charParts()
                local inv = runtime.inventory
                if not (root and inv) then return end
                local item = inv:FindFirstChild("NomNomAntiKickItem")
                if not item then
                    item = spawnToy(runtime.values.antiKickToy, root.CFrame, Vector3.zero, 2)
                    if item then item.Name = "NomNomAntiKickItem" end
                end
                local hit = item and (item:FindFirstChild("Hitbox") or item:FindFirstChild("HoldPart") or item.PrimaryPart)
                if hit then
                    sno(hit)
                    hit.CFrame = root.CFrame
                    hit.CanCollide = false
                    hit.CanTouch = false
                    hit.CanQuery = false
                end
            end))
        end
    end

    local function setInputLagGuard(enabled)
        runtime.toggles.inputLagGuard = enabled
        disconnectKey("inputLagGuard")
        if enabled then
            setKeyConnection("inputLagGuard", RunService.Heartbeat:Connect(function()
                local char, _, root = charParts()
                if not (char and root) then return end
                local inv = runtime.inventory
                if not inv then return end
                local item = inv:FindFirstChild(runtime.values.inputToy)
                if not item then item = spawnToy(runtime.values.inputToy, root.CFrame * CFrame.new(0, -8, 0), Vector3.zero, 2) end
                local hold = item and item:FindFirstChild("HoldPart")
                if hold then
                    for _, part in ipairs(item:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false; part.Massless = true end
                    end
                    local holdRemote = hold:FindFirstChild("HoldItemRemoteFunction")
                    local dropRemote = hold:FindFirstChild("DropItemRemoteFunction")
                    if holdRemote then safeInvoke(holdRemote, item, char) end
                    if dropRemote then safeInvoke(dropRemote, item, root.CFrame * CFrame.new(0, 500, 0), Vector3.zero) end
                end
            end))
        end
    end

    local function teleportMap()
        local _, _, root = charParts()
        local cf = runtime.mapPoints[runtime.values.selectedMap]
        if root and cf then root.CFrame = cf; stopVelocity(root) end
    end

    local function deleteLegs()
        local char, hum, root = charParts()
        if not (char and hum and root) then return end
        local ll, rl = char:FindFirstChild("Left Leg"), char:FindFirstChild("Right Leg")
        if not (ll and rl) then return end
        local old = char:GetPivot()
        local oldHeight = Workspace.FallenPartsDestroyHeight
        Workspace.FallenPartsDestroyHeight = -1000000000
        safeFire(Remotes.Ragdoll, root, 2)
        task.wait(0.4)
        ll.CFrame = CFrame.new(0, -50000, 0)
        rl.CFrame = CFrame.new(0, -50000, 0)
        task.wait(0.2)
        char:PivotTo(old)
        Workspace.FallenPartsDestroyHeight = oldHeight
    end

    local function tryLoadObsidian()
        local ok, lib = pcall(function()
            return (loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua")))()
        end)
        if ok and type(lib) == "table" then return lib end
        return nil
    end

    local Library = tryLoadObsidian()
    runtime.Library = Library
    if not Library then
        notify("NomNom", "Obsidian UI failed to load", 10)
        return
    end

    local Window = Library:CreateWindow({
        Title = "NomNom FTAP Alt • Wourld Unified",
        Footer = "The Wourld UI + NoName/XOCO features • no packs",
        ToggleKeybind = Enum.KeyCode.RightControl,
        Center = true,
        AutoShow = true,
    })
    runtime.Window = Window

    local Tabs = {
        Home = Window:AddTab("Home", "house"),
        Protection = Window:AddTab("Protection / Gucci", "shield"),
        Combat = Window:AddTab("Combat / Grab", "swords"),
        Player = Window:AddTab("Player", "user"),
        Visuals = Window:AddTab("Visuals", "eye"),
        Toys = Window:AddTab("Toys / Utility", "package"),
        Teleports = Window:AddTab("Teleports / Map", "map"),
        Settings = Window:AddTab("Settings", "settings"),
    }

    local function group(tab, name, side)
        return tab:AddLeftGroupbox and (side == "left" and tab:AddLeftGroupbox(name) or tab:AddRightGroupbox(name)) or tab:AddGroupbox(name)
    end

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

    local VisualGroup = group(Tabs.Visuals, "Camera / ESP", "left")
    VisualGroup:AddToggle("ThirdPerson", { Text = "Third person", Default = false, Callback = function(v) LocalPlayer.CameraMaxZoomDistance = 1e9; LocalPlayer.CameraMode = v and Enum.CameraMode.Classic or Enum.CameraMode.LockFirstPerson end })
    VisualGroup:AddSlider("FOV", { Text = "FOV", Min = 10, Max = 120, Default = 80, Rounding = 0, Callback = function(v) Workspace.CurrentCamera.FieldOfView = v end })
    VisualGroup:AddToggle("PlayerESP", { Text = "Player ESP", Default = false, Callback = setPlayerESP })
    VisualGroup:AddToggle("PCLDESP", { Text = "PCLD ESP", Default = false, Callback = setPCLDESP })

    local VisualRight = group(Tabs.Visuals, "Lighting", "right")
    VisualRight:AddButton("Fullbright", function() Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false end)
    VisualRight:AddButton("Low Graphics", function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01; for _, obj in ipairs(Workspace:GetDescendants()) do if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then obj.Enabled = false end end end)
    VisualRight:AddButton("Reset camera", function() Workspace.CurrentCamera.FieldOfView = 80; LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson end)

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

    local MapGroup = group(Tabs.Teleports, "Map", "left")
    MapGroup:AddDropdown("MapPoint", { Text = "House", Values = {"Green House", "Pink House", "Witch House", "Blue House", "China House"}, Default = "Green House", Callback = function(v) runtime.values.selectedMap = v end })
    MapGroup:AddButton("Teleport selected", teleportMap)
    MapGroup:AddToggle("Loop selected teleport", { Text = "Loop selected map point", Default = false, Callback = function(v) setLoop("loopMap", v, teleportMap, 0.15) end })
    MapGroup:AddToggle("Random house patrol", { Text = "Random house patrol", Default = false, Callback = function(v) runtime.toggles.randomPatrol = v; disconnectKey("randomPatrol"); if v then setKeyConnection("randomPatrol", RunService.Heartbeat:Connect(function() if math.random() < 0.02 then local keys = {"Green House", "Pink House", "Witch House", "Blue House", "China House"}; runtime.values.selectedMap = keys[math.random(#keys)]; teleportMap() end end)) end end })

    local TargetGroup = group(Tabs.Teleports, "Players", "right")
    TargetGroup:AddButton("Teleport to nearest", function() local target = getNearestPlayer(500); local _,_,root = charParts(); local tr = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart"); if root and tr then root.CFrame = tr.CFrame * CFrame.new(0,0,3) end end)
    TargetGroup:AddButton("Bring nearest network", function() local target = getNearestPlayer(80); local tr = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart"); if tr then sno(tr) end end)

    local SettingsGroup = group(Tabs.Settings, "Cleanup / Safety", "left")
    SettingsGroup:AddLabel("No auto public-chat. No public chat startup spam. No pack/lazy payload system.")
    SettingsGroup:AddButton("Disable all loops", function() for key in pairs(runtime.toggles) do runtime.toggles[key] = false end; runtime.cleanup(); notify("NomNom", "Runtime cleaned", 1) end)
    SettingsGroup:AddButton("Refresh remotes/character", function() refreshCharacter(LocalPlayer.Character); notify("NomNom", "Refreshed", 1) end)

    local KeyGroup = group(Tabs.Settings, "Keybinds", "right")
    KeyGroup:AddKeyPicker("GucciKey", { Text = "Bind Gucci key", Default = "J", Callback = function() buildGucciToy(false) end })
    KeyGroup:AddKeyPicker("PlatformKey", { Text = "High safe platform key", Default = "X", Callback = function() local _,_,root = charParts(); if not root then return end; if not runtime.platform then local p = Instance.new("Part"); p.Name = "NomNomSkyBase"; p.Size = Vector3.new(800,2,800); p.Anchored = true; p.CFrame = CFrame.new(0, 1000000, 0); p.Parent = Workspace; runtime.platform = trackInstance(p) end; runtime.platformSaved = runtime.platformSaved or root.CFrame; if (root.Position - runtime.platform.Position).Magnitude > 100 then root.CFrame = runtime.platform.CFrame + Vector3.new(0,5,0) else root.CFrame = runtime.platformSaved; runtime.platformSaved = nil end end })

    notify("NomNom FTAP Alt", "Unified Wourld-style script loaded", 5)
end)()
