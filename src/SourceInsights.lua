--[[
    NomNom FTAP source module reference: SourceInsights
    Engineering-only pattern extraction from Source_RooClone_20260629-183754.
]]

local SourceInsights = {}

SourceInsights.filesReviewed = {
    "Sorce_main/Invisible.lua",
    "Sorce_main/UFO.lua",
    "Sorce_main/Doc/LoopFling.lua",
    "Sorce_main/BlackHub.lua",
    "Comparable Gucci/anti-loopkill snippets found by source search",
}

SourceInsights.safePatterns = {
    "Refresh character/root/humanoid references on CharacterAdded and root acquired.",
    "Reconnect Died/SeatPart/Occupant watchers after respawn.",
    "Reuse owned toys where possible, then spawn with ChildAdded/WaitForChild timeout.",
    "Monitor ownership tags/PartOwner and recover when control changes.",
    "Use waypoint/orbit movement at safe high altitude rather than void/despawn movement.",
    "Keep target actions opt-in, authorized, cooldown-bound, and recovery-first.",
}

return SourceInsights
