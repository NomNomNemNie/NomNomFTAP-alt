# Strong source comparison

This document records the comparison used for the modular `NomNom.lua`/`Loader.lua` build. `Source/Strong/The Wourld` is the canonical base script, UI standard, and naming model. `Source/Strong/NoName`, `Source/Strong/XOCO`, and `Source/Strong/NoName-Apple` are comparison sources only; stronger or missing ideas are integrated directly into Wourld-style NomNom sections, not treated as equal packs and not exposed as source-pack loader buttons.

## Source roles

| Source | Role | UI style | Stronger or missing features found | Integrated outcome |
| --- | --- | --- | --- | --- |
| `Source/Strong/The Wourld` | Canonical base | Obsidian-style UI and Wourld UX conventions | Defense/protection, Gucci flow, target/server sections, keybind/settings structure, rerun cleanup marker | Kept as the final UX standard, tab model, and naming model. Loader/modules are Wourld-style. |
| `Source/Strong/NoName` | Comparison source | Orion tabs: Defense, Grabs, Player, Target, Keybinds, Visual, Misc, Owner, Settings | Anti-grab, AntiKick shuriken/item, AntiBlob, AntiPaint, AntiBurn, AntiVoid, super strength, infinity line extend, grab modifiers, auras, player movement, ESP/PCLD ESP, map points, anti-explosion pattern | Feature concepts reimplemented inside matching Wourld/Obsidian tabs with shared helpers and tracked connections. |
| `Source/Strong/XOCO` | Comparison source | Solaris tabs: defense, target, grab, player, misc, keybinds, visuals | Multiple AntiGrab versions, AntiBlob aura/drop logic, Gucci/invisible Gucci/watchdogs, platform TP, input-lag item loops, auto reset/correction handlers, paint cleanup, delete legs, stronger anti-burn, anti-explosion, shuriken anti-kick | Stronger Gucci/protection and utility ideas integrated cleanly without copying generated top-level blocks. |
| `Source/Strong/NoName-Apple` | Comparison source | Obsidian Apple/Russian localization layout | Obsidian-compatible grouping, AntiExplosion, stronger anti-burn fire-part cleanup, shuriken anti-kick anchor loop, KillGrab concept, Russian labels | Only safe/maintainable features were integrated: AntiExplosion, improved AntiBurn cleanup, and shuriken anti-kick anchor. Apple/Russian UI and KillGrab were not adopted because Wourld remains canonical and the build avoids destructive target-health controls. |

## Feature comparison

### UI structure

- Wourld is the canonical standard for the final UX because it already follows an Obsidian-style window/tab/groupbox model and matches the intended Wourld flow.
- NoName, XOCO, and NoName-Apple feature families were mapped into: Home, Protection / Gucci, Combat / Grab, Player, Visuals, Toys / Utility, Teleports / Map, and Settings.
- The final build has no lazy source-pack buttons, encoded chunk table, base64 source payloads, lazy pack execution buttons, or equal-source pack selection.

### Protection / Gucci

- Wourld contributes the base protection/Gucci concept and Obsidian interaction style.
- NoName contributes AntiGrab, AntiKick item/shuriken concepts, AntiBlob, AntiPaint, AntiBurn, AntiVoid, AntiBarrier, anti-explosion, anti-loop-kill map recovery, and delete-legs recovery.
- XOCO contributes verified-style anti-grab loops, anti-blob aura/drop, platform/high safety concepts, invisible/auto Gucci watchdog ideas, correction reset, anti-explosion, and stronger cleanup around Gucci toys.
- NoName-Apple confirms the Obsidian-compatible shuriken anti-kick and anti-explosion approaches and adds stronger fire-part cleanup for AntiBurn.
- Final synthesis includes verified protection, anti steal-seat, anti massless/blob physics, recovery lock, anti blob/drop aura, anti paint, anti burn/extinguish cleanup, anti explosion, no void despawn, bind Gucci, auto Gucci watchdog, anti-destroy stabilizer, high/safe patrol, anti-kick item attach, shuriken anti-kick anchor, and delete legs.

### Combat / grab / target

- NoName has the richest grab set: super strength, infinity line extend, responsiveness/massless grab, spin/ragdoll grab, RGB/invisible line, fling/click aura, blob bring/drop.
- XOCO overlaps on target/grab and adds aura-oriented blob pressure.
- Final synthesis reimplements these concepts with one set of remotes and connection guards instead of concatenating source chunks.

### Movement / player

- NoName contributes WalkSpeed multiplier, infinite jump, ocean walk, barrier toggles, preserve/respawn concepts.
- XOCO contributes correction reset and high/platform safety.
- Final synthesis includes WalkSpeed, Infinity Jump, stop velocity, ragdoll pulse, ocean walk, anti barrier, and correction reset.

### Visuals

- NoName contributes icon ESP, PCLD ESP, FOV, and third-person handling.
- XOCO contributes visuals tab organization.
- Final synthesis includes third person, FOV, player ESP, PCLD ESP, fullbright, low graphics, and camera reset.

### Toys / utility

- NoName and XOCO both contain toy-spawn workflows for protection and input-lag mitigation.
- Final synthesis uses a shared `spawnToy` helper, input guard toy cycle, blobman/tractor spawns, NomNom toy cleanup, line color pulse, invisible line, and base line restore.

### Teleport / map

- NoName map points were preserved and renamed to readable house labels.
- XOCO platform/high safety ideas were moved into keybind/settings and patrol controls.
- Final synthesis includes selected house teleport, loop selected teleport, random house patrol, teleport to nearest, and nearest network bring.

### Settings / cleanup / recovery

- Wourld canonical loader/runtime markers are preserved while the implementation remains modular.
- Final runtime tracks connections, tasks, and instances, cleans a previous run before mounting, refreshes character state on respawn, and uses low-noise notification cooldowns.
- No automatic public-chat APIs or startup public chat sends are used.

## Source fixes applied

- Wourld: retained as canonical UI/base; public chat announcement remains disabled.
- NoName: retained stronger feature concepts; public chat service removal, `character` raycast typo, `shi`/`HRP` typo, shuriken name typo, and untracked PCLD ESP connection are not carried into the modular implementation.
- XOCO: retained stronger Gucci/protection concepts; startup loaded-message auto call, `MouseMouseBehavior` typo, callback `Value` vs `v` mistakes, and malformed notification call are not carried into the modular implementation.
- NoName-Apple: retained AntiExplosion, enhanced AntiBurn cleanup, and shuriken anti-kick anchor; Apple/Russian UI, global reset sweep, and destructive KillGrab target-health logic are not carried into the Wourld canonical build.

## Final integration strategy

The final `NomNom.lua` is not a concatenation and not a pack switcher. It loads the Wourld-style modular runtime through `Loader.lua`, extracts comparison-source feature concepts, and reimplements them through shared helpers for remotes, character refresh, toy spawn, notifications, cleanup, loops, and Obsidian controls. This keeps top-level local/register pressure low and makes the script paste-run compatible without losing the Wourld base.
