--[[
    NomNom FTAP source module reference: GucciGuard
    Source/reference module for the standalone bundled NomNom.lua implementation.
]]

local GucciGuard = {}

GucciGuard.config = {
    modeOptions = {"Adaptive High Vault", "High Sky Vault", "Maximum Upward Vault", "Map Orbit Guard", "Extreme Map Patrol"},
    spawn = {
        toyChoices = {"TractorGreen", "CreatureBlobman"},
        spawnPendingGuard = true,
        childAddedWait = true,
        timeoutSeconds = 3.5,
        cooldownSeconds = 2.5,
        maxBackoffSeconds = 10,
    },
    patrol = {
        enabledDefault = true,
        safeMinY = 35,
        highVaultHeight = 135,
        waypointRadius = 180,
        waypointCount = 10,
        updateInterval = 0.16,
        ownershipInterval = 0.45,
    },
    fastVerify = {
        windowSeconds = 1.25,
        intervalSeconds = 0.08,
    },
}

GucciGuard.safePatterns = {
    "Reuse an existing owned TractorGreen/CreatureBlobman before spawning.",
    "Wait for ChildAdded and scan owned toy folder instead of fixed sleep loops.",
    "Use spawnPending/Respawning flags and backoff to avoid remote spam.",
    "Create a recovery waypoint from current/root position and clamp it above safe minimum Y.",
    "Move guard toys around generated/discovered map waypoints; never intentionally below safe Y.",
    "During recovery lock, run ownership, reseat, spawn/reuse, patrol, and fast verify in bounded cadence.",
}

return GucciGuard
