--[[
    NomNom FTAP source module reference: Defense
    Target-affecting behavior must remain explicitly authorized/private-test gated.
]]

local Defense = {}

Defense.gates = {
    authorizedTargetsOnlyDefault = true,
    authorizedGuardCleanupDefault = false,
    authorizedCounterResponseDefault = false,
    legacyDefensiveResponseDefault = false,
}

Defense.safeFlow = {
    "Detect health drops, death, seat changes, ragdoll/fall, grab proximity, and repeated forced movement.",
    "Mark suspected attacker locally and persist by UserId/name across respawn.",
    "Start local Gucci Guard recovery first when a defense signal arrives.",
    "Only after recovery starts, optionally run Authorized Guard Cleanup / Authorized Counter Response.",
    "Reject all cleanup/counter-response unless suspect is whitelisted or NomNomAuthorizedTarget.",
    "Use cooldowns and bounded retries; otherwise log/mark only.",
    "Gucci protection loss from anti-steal-seat, anti-destroy, seat occupant mismatch, ownership loss, or safe patrol-area drift starts recovery lock first.",
    "Do not attack indiscriminately on guard protection loss; destructive/counter behavior remains off by default and authorized/suspected-target gated.",
}

return Defense
