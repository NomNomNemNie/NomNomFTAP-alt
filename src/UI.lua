--[[
    NomNom FTAP source module reference: UI
    Rayfield tab/section map for the standalone bundled NomNom.lua.
]]

local UI = {}

UI.tabs = {
    Main = {"Character", "Movement/QoL"},
    Protection = {
        "Local Guards",
        "Gucci Guard / Auto Gucci",
        "Extreme Map Patrol / Map Orbit Guard",
        "Fast Verify + ChildAdded spawn wait",
        "Verified protected / anti-steal-seat / anti-destroy status",
    },
    Visuals = {"Local Debug ESP"},
    Chat = {"NomNom Local Chat Overlay"},
    Tools = {"Toy Helpers", "Massless Grab", "Super Fling On Release"},
    Targets = {
        "Authorized Private-Test Targets",
        "Defensive Response",
        "Authorized Guard Cleanup",
        "Authorized Counter Response",
    },
    Vehicles = {"UFO Hitbox Debug"},
    Settings = {"Build Info", "Module/build strategy"},
}

return UI
