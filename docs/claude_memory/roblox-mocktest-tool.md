---
name: roblox-mocktest-tool
description: "tools/mocktest.py runs the game's Luau logic with mock Roblox (luau.exe); what it catches and the shell/heredoc pitfalls found while building it"
metadata:
  node_type: memory
  type: reference
  originSessionId: eb377534-0dfc-4b77-ad04-af0c19dec369
  modified: 2026-10-06T01:16:39.843Z
---

`python tools/mocktest.py` (added 2026-10-06) copies every src module into a temp dir, swaps Roblox globals for mocks in `tools/mocktest/stubs.luau` (server) and `cstubs.luau` (client, permissive proxies) and runs `tools/mocktest/tests/*.luau` with `%USERPROFILE%/.luau/luau.exe`: PlayerStats flows, full server boot (init.server + a join), full client boot (init.client), Hub/Environment/Wall setup, wall damage, flow test through the real Click/Shop handlers, panels, trainer outfits. 11/11 passed at the end of that round.

**Why:** the owner is the only Studio tester and `luau-analyze` only checks syntax/types; the mocks catch runtime logic bugs (nil indexing, wrong fields) before the owner sees them. It cannot catch invalid Roblox property/enum names or how things look.
**How to apply:** after changing server logic, quests, pets, walls or any HUD/panel code run `python tools/check.py` AND `python tools/mocktest.py`; when adding a module or flow, add a test in `tools/mocktest/tests`. Known mock gaps are filtered in mocktest.py (UIStyle UDim, Sfx/GiftsPanel/EggShop loops).

Pitfalls found: (1) inside bash heredocs (`python - <<'EOF'`) a double backslash `\\n` arrived as a single `\n` and broke generated Python/Lua string literals, so write any file or patch that needs backslashes with the Write/Edit tools, not heredocs; (2) globals assigned in a luau.exe main script are not visible in required modules (each module needs its own prelude), `os` is read-only there (cannot override os.clock; busy-wait instead); (3) the Bash tool's working directory can drift into `tools/` after a `cd`, always `cd` to the project root first. See [[roblox-syntax-check-lesson]] and [[roblox-project-status]].
