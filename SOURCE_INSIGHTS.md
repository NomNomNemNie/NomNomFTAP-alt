# SOURCE_INSIGHTS

This pass mined engineering patterns from the source reference clone and intentionally avoided copying indiscriminate public-game griefing behavior. The bundled runtime remains [`NomNom.lua`](NomNom.lua:1), with source/reference summaries under [`src`](src:1).

## Files reviewed

- [`Invisible.lua`](../Source_RooClone_20260629-183754/Sorce_main/Invisible.lua:1): Gucci tractor/blobman lifecycle, seat validation, respawn/death watchers, ragdoll state reacquisition, occupant monitoring.
- [`UFO.lua`](../Source_RooClone_20260629-183754/Sorce_main/UFO.lua:1): waypoint/orbit movement and hitbox follow/spin ideas adapted into safe local debug/orbit patterns.
- [`LoopFling.lua`](../Source_RooClone_20260629-183754/Sorce_main/Doc/LoopFling.lua:1): ownership monitoring, existing toy reuse, target list gating, ChildAdded handling, cleanup of monitors.
- [`BlackHub.lua`](../Source_RooClone_20260629-183754/Sorce_main/BlackHub.lua:1): ChildAdded/WaitForChild spawn waits, plot/owned toy lookup, CharacterAdded reacquisition, Gucci maintenance loops, cooldown/backoff ideas.
- Comparable source-search hits for `CharacterAdded`, `Died`, `VehicleSeat`, `SetNetworkOwner`, and `SpawnToyRemoteFunction`.

## Safe engineering patterns extracted

1. **Ownership monitoring**: monitor toy parts and re-request ownership at throttled intervals; clear monitors when toys disappear.
2. **Existing toy reuse**: scan the owned spawned-toy folder first and bind a valid guard before spawning another toy.
3. **ChildAdded spawn wait**: replace fixed spawn sleeps with owned-folder `ChildAdded` plus timeout and a `spawnPending` guard.
4. **Seat validation**: validate model ancestry, seat existence, occupant/SeatPart relationship, and local root proximity before considering Gucci protected.
5. **Waypoint/orbit movement**: use generated/discovered waypoints for Map Orbit Guard movement instead of void/despawn placement.
6. **Safe-Y clamping**: guard toys are clamped above a configured safe minimum Y and high vault height.
7. **Backoff and bounded retries**: spawn/recovery loops use cooldowns, retry-after timestamps, and maximum backoff.
8. **Cleanup discipline**: track connections/instances and cleanup guard state on unload or disable.
9. **Target authorization**: all player-affecting cleanup/counter-response behavior stays off by default and requires authorized/suspected target validation.
10. **Death/respawn reacquisition**: persist recovery intent and suspect markers, then reacquire character/root/humanoid as early as `CharacterAdded` and root availability allow.
11. **The Wourld Gucci Protect hardening**: port the refined local-protection ideas without copying destructive behavior: watch each seat occupant, monitor model/seat ancestry for anti-destroy signals, re-check owner markers, and require verified protected state before clearing recovery.

## Changes reflected in this clone

- Added `Extreme Map Patrol` / `Map Orbit Guard` controls and safe high waypoint patrol.
- Added `ChildAdded` spawn wait with `spawnPending` and timeout/backoff.
- Added `Fast Verify` window after binding/recovery.
- Added recovery waypoint and `recovery lock` patrol/ownership/reseat loop.
- Added off-by-default `Authorized Guard Cleanup` and `Authorized Counter Response` gates.
- Updated source modules under [`src`](src:1) to document Core/State/Cleanup, UI, GucciGuard, Defense, Toys, Visuals, Chat, Vehicles, and SourceInsights separation.
- Added NomNom-only Gucci protection hardening inspired by [`The Wourld`](../The%20Wourld:1): anti-steal-seat, anti-destroy, seat occupant monitoring, ownership loss checks, safe patrol-area validation, and stricter verified protected criteria that treat failures as protection loss and enter recovery lock.
