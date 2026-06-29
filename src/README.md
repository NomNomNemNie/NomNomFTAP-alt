# Source module reference

These [`src`](README.md:1) files are maintainable source/reference modules for the bundled standalone [`NomNom.lua`](../NomNom.lua:1). They are intentionally not required at runtime by default because Xeno-style private-test use benefits from a single paste-and-run script.

## Bundle strategy

- Edit/maintain concepts in the source modules when doing larger changes.
- Sync the runnable implementation into [`NomNom.lua`](../NomNom.lua:1).
- Keep [`NomNom.lua`](../NomNom.lua:1) standalone until a loader or bundler is explicitly added.
- Keep target-affecting behavior gated to authorized/private-test targets and off-by-default toggles.
- The GucciGuard reference now documents The Wourld-inspired anti-steal-seat, anti-destroy, seat occupant, protection loss, and verified protected checks; runtime changes must remain synced into [`NomNom.lua`](../NomNom.lua:1).
