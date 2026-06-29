# NomNom FTAP Roo Clone

NomNom FTAP Roo Clone is a consolidated standalone Luau script for owned/private FTAP testing. The repository keeps `NomNom.lua` as the single paste-and-run entrypoint for Xeno-style executor use while also adding maintainable source/reference modules under `src`.

## Private-test usage

1. Open `NomNom.lua`.
2. Copy the whole file into the private test executor environment.
3. Run it in an owned/private place where you are allowed to test the behavior.
4. Use the in-script toggles to enable only the features needed for the current test.
5. Use the `Cleanup / Unload Script` button before rerunning if you want a manual reset; the script also includes a rerun cleanup key.

Do not use this project against servers, players, or experiences where you do not have authorization. Targeted private-test tools are designed to remain gated behind authorized target controls by default.

## Feature list

- One Rayfield UI path with tabbed controls.
- Rerun cleanup key for tracked connections, instances, ESP objects, and temporary physics helpers.
- Movement/QoL controls for walk speed, jump power, infinite jump, camera zoom, safe-height teleport, and respawn.
- Local protection toggles for anti-void, anti-ragdoll assist, anti-grab assist, anti-fire assist, anti-explode stabilization, and anti-input-lag behavior.
- Gucci Guard / Auto Gucci private-test guard anchor with high-vault strategies, Extreme Map Patrol / Map Orbit Guard, spawn cooldowns, ChildAdded spawn wait, Fast Verify, recovery lock, status display, and cleanup options.
- Defensive monitor and optional private-test response modes with authorized target gating, including off-by-default Authorized Guard Cleanup and Authorized Counter Response.
- Local debug ESP with name, distance, color, rainbow, and refresh controls.
- Local chat overlay with bounded history and F8 toggle.
- Toy helpers for selected toy spawning, massless grab tuning, and super-fling-on-release testing.
- UFO hitbox debug controls for follow/spin visualization.
- Respawn reapply handling for movement, monitors, guard recovery, and ESP refresh.

## Clone layout

| Path | Purpose |
|---|---|
| `NomNom.lua` | Standalone Xeno-style runnable entrypoint. Keep this file paste-and-run compatible. |
| `src/CoreStateCleanup.lua` | Source/reference split for cleanup key, state families, connection tracking, and bounded remote helpers. |
| `src/GucciGuard.lua` | Source/reference split for Gucci Guard, Extreme Map Patrol, ChildAdded spawn wait, Fast Verify, recovery lock, and safe-Y patrol. |
| `src/Defense.lua` | Source/reference split for detection, suspect persistence, authorized cleanup, and authorized counter-response gates. |
| `src/UI.lua` | Source/reference split for Rayfield tab/section map and build info. |
| `src/ToysVehiclesVisualsChat.lua` | Source/reference split for toys, local visuals, chat overlay, and vehicle/UFO debug patterns. |
| `src/SourceInsights.lua` | Source/reference split summarizing safe engineering patterns mined from the source clone. |
| `src/README.md` | Source module strategy and bundle notes. |
| `modules/README.md` | Reserved optional runtime module folder if a loader-compatible split is introduced later. |
| `SOURCE_INSIGHTS.md` | Deep source-pattern synthesis for this hardening pass. |
| `README.md` | Repository usage, layout, and maintenance notes. |
| `SOURCE_COMPARISON.md` | High-level comparison of archived source feature families used to guide consolidation. |
| `SOURCE_INVENTORY.md` | Safe inventory of source archives and benign feature labels. |

## Internal sections in NomNom.lua

`NomNom.lua` is intentionally organized as internal sections rather than required modules:

1. Header, cleanup key, and service acquisition.
2. Shared state table and utility helpers.
3. Player, target, toy, guard, and defensive helper functions.
4. Cleanup/unload implementation.
5. Rayfield loader and window creation.
6. Movement/QoL tab.
7. Protection and Gucci Guard tab.
8. Visual ESP tab.
9. Chat overlay tab.
10. Toy/helper tools tab.
11. Authorized target and defensive response tab.
12. Vehicle/UFO debug tab.
13. Respawn reapply and settings tab.

## Module and bundle strategy

Runtime code is now split conceptually into maintainable source/reference modules under `src`, but `NomNom.lua` remains the runnable bundled build. This keeps Xeno-style private-test usage paste-and-run compatible while making future edits easier to reason about.

Current source/reference split:

- `src/CoreStateCleanup.lua` for shared state, cleanup, tracking, and rate-limit patterns.
- `src/GucciGuard.lua` for Gucci Guard, Extreme Map Patrol / Map Orbit Guard, ChildAdded spawn wait, spawnPending/backoff, Fast Verify, and recovery lock strategy.
- `src/Defense.lua` for anti-loopkill/death recovery, suspect persistence, Authorized Guard Cleanup, and Authorized Counter Response gates.
- `src/UI.lua` for Rayfield sections, module/build info, and user-facing controls.
- `src/ToysVehiclesVisualsChat.lua` for toy helpers, visuals, chat, and vehicle/UFO local debug controls.
- `src/SourceInsights.lua` plus `SOURCE_INSIGHTS.md` for source-mining notes.

Build rule: treat `NomNom.lua` as the generated/manual bundle. If source modules are edited, manually sync or run a future bundler before release. Do not require runtime module loading unless a loader-compatible environment is explicitly introduced.

## Git and authentication notes

- GitHub remote target: `https://github.com/NomNomNemNie/NomNomFTAP-alt`.
- Repository commits should use git email `gta34v@gmail.com`.
- No GitHub token, password, credential helper data, or machine-specific absolute workspace path is stored in the repository.
- Push authentication is expected to be handled by the user's existing GitHub credential manager or token setup.
- If push authentication fails, the repository should remain committed locally with `origin` configured so the user can retry after fixing credentials.

## Gucci Guard hardening notes

- Extreme Map Patrol / Map Orbit Guard moves guard toys through bounded high map waypoints and clamps all patrol positions above Safe Minimum Y.
- The guard no longer intentionally sends toys into the void; recovery stores a safe recovery waypoint and patrols from it.
- Spawn uses existing guard scan plus ChildAdded wait with spawnPending, timeout, cooldown, and backoff.
- Fast Verify briefly increases bounded protection checks after spawn/recovery or vulnerable windows, then returns to normal cadence.
- Recovery lock preserves intent through death/respawn and starts as soon as CharacterAdded/root acquisition allows.
- Ported The Wourld Gucci Protect patterns into NomNom only: anti-steal-seat watches each guard seat occupant change, anti-destroy watches model/seat ancestry, and protection loss triggers local recovery lock.
- Verified protected now requires coherent local humanoid/seat/model state, expected toy-folder/plot ancestry, optional owner markers not stolen from the local player, and safe patrol-area placement.
- Authorized Guard Cleanup and Authorized Counter Response are off by default and require authorized/suspected targets.

## Maintenance notes

- Preserve the standalone entrypoint contract for `NomNom.lua`.
- Keep private-test and authorization notes visible when adding targeted features.
- Prefer tracked connections/instances and bounded loops for any new runtime behavior.
- Keep generated or reference modules optional unless a bundling step is introduced.
