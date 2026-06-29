# NomNom FTAP Roo Clone

NomNom FTAP Roo Clone is a consolidated standalone Luau script for owned/private FTAP testing. The repository keeps `NomNom.lua` as the single paste-and-run entrypoint for Xeno-style executor use.

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
- Gucci Guard / Auto Gucci private-test guard anchor with high-vault strategies, spawn cooldowns, recovery lock, status display, and cleanup options.
- Defensive monitor and optional private-test response modes with authorized target gating.
- Local debug ESP with name, distance, color, rainbow, and refresh controls.
- Local chat overlay with bounded history and F8 toggle.
- Toy helpers for selected toy spawning, massless grab tuning, and super-fling-on-release testing.
- UFO hitbox debug controls for follow/spin visualization.
- Respawn reapply handling for movement, monitors, guard recovery, and ESP refresh.

## Clone layout

| Path | Purpose |
|---|---|
| `NomNom.lua` | Standalone Xeno-style runnable entrypoint. Keep this file paste-and-run compatible. |
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

## Module-splitting decision

This clone currently does not split runtime code into required modules because Xeno-style private-test usage benefits from a single standalone script that can be pasted and run without a module loader or external files.

If future maintenance requires modules, keep `NomNom.lua` as the generated standalone bundle and add optional source/reference modules beside it, for example:

- `modules/state.lua` for default state and constants.
- `modules/services.lua` for service lookups and safe path helpers.
- `modules/cleanup.lua` for connection/instance tracking.
- `modules/guard.lua` for Gucci Guard helpers.
- `modules/ui.lua` for Rayfield tab construction.

After any split, rebuild or manually sync the standalone `NomNom.lua` so executor use is not broken.

## Git and authentication notes

- GitHub remote target: `https://github.com/NomNomNemNie/NomNomFTAP-alt`.
- Repository commits should use git email `gta34v@gmail.com`.
- No GitHub token, password, credential helper data, or machine-specific absolute workspace path is stored in the repository.
- Push authentication is expected to be handled by the user's existing GitHub credential manager or token setup.
- If push authentication fails, the repository should remain committed locally with `origin` configured so the user can retry after fixing credentials.

## Maintenance notes

- Preserve the standalone entrypoint contract for `NomNom.lua`.
- Keep private-test and authorization notes visible when adding targeted features.
- Prefer tracked connections/instances and bounded loops for any new runtime behavior.
- Keep generated or reference modules optional unless a bundling step is introduced.
