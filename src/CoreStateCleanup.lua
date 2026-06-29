--[[
    NomNom FTAP source module reference: Core / State / Cleanup
    This file is maintainable source documentation for the bundled standalone NomNom.lua.
    Xeno-style runtime should still use NomNom.lua unless a loader/bundler is introduced.
]]

local CoreStateCleanup = {}

CoreStateCleanup.defaultConfig = {
    cleanupKey = "__NomNomFTAP_RooCleanup_V1",
    standaloneEntrypoint = "NomNom.lua",
    configFolder = "NomNomFTAP",
    ownedPrivateTestingOnly = true,
}

CoreStateCleanup.stateFamilies = {
    runtime = {"Enabled", "Connections", "Instances", "Threads", "LastRemote"},
    identity = {"Whitelist", "AuthorizedTargetsOnly", "SelectedTarget"},
    gucciGuard = {
        "GucciGuardEnabled",
        "GucciGuardMode",
        "GucciPatrolEnabled",
        "GucciPatrolSafeMinY",
        "GucciGuard.SpawnPending",
        "GucciGuard.RecoveryLock",
        "GucciGuard.FastVerifyUntil",
    },
    defense = {
        "DefensiveMonitorEnabled",
        "AuthorizedGuardCleanup",
        "AuthorizedCounterResponse",
        "SuspectedAttackerUserId",
        "SuspectedAttackerName",
    },
}

CoreStateCleanup.patterns = {
    "Use a rerun cleanup key before creating UI/connections.",
    "Track every connection and temporary instance in State for deterministic unload.",
    "Use fireRateLimited for remotes and bounded loops for recovery/maintenance.",
    "Persist suspect markers by UserId/name across respawn while keeping responses gated.",
}

return CoreStateCleanup
