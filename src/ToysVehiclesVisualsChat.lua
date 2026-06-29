--[[
    NomNom FTAP source module reference: Toys / Vehicles / Visuals / Chat
    Benign local tooling and helper patterns used by the bundled script.
]]

local ToysVehiclesVisualsChat = {}

ToysVehiclesVisualsChat.toys = {
    "Spawn selected toy near local root with rate-limited remote use.",
    "Massless grab tuning watches Workspace.ChildAdded for GrabParts and bounds the loop to object lifetime.",
    "Release velocity / defensive marker tools are local/private-test helpers and not indiscriminate loops.",
}

ToysVehiclesVisualsChat.visuals = {
    "Local ESP uses tracked instances and refresh/remove helpers.",
    "Chat overlay uses bounded in-memory history and cleanup tracking.",
}

ToysVehiclesVisualsChat.vehicles = {
    "UFO hitbox debug follows/orbits local root with local CFrame updates only.",
    "Vehicle/source patterns informed waypoint/orbit movement, not public griefing automation.",
}

return ToysVehiclesVisualsChat
