---
name: roblox-syntax-check-lesson
description: rojo build does not check Luau syntax; a stray brace in Config once blanked the whole game - always run tools/luacheck.py after edits
metadata:
  node_type: memory
  type: feedback
  originSessionId: eb377534-0dfc-4b77-ad04-af0c19dec369
  modified: 2026-10-04T18:31:09.779Z
---

After every code change run `python tools/check.py` (project root): official `luau-analyze` (installed at `%USERPROFILE%/.luau/luau-analyze.exe`, user approved the download) plus `tools/luacheck.py`; do not call work done until it reports 0 problems. `rojo build` alone is not enough.
**Why:** a stray `},` left in `shared/Config.luau` (from a scripted text replacement) made the Config module fail to load, so the server never started and the user saw an empty baseplate. `rojo build` still passed.
**How to apply:** also re-read the area around any scripted/regex replacement in Python (balanced braces, indentation). Pass RELATIVE paths to the analyzer (the folder name contains non-ASCII `Masaüstü`). If the user reports "nothing shows up", read the newest Studio log (`%LOCALAPPDATA%\Roblox\logs`, search for `Expected`, `Error:`, `Script`). The analyzer has no Roblox type definitions, so it only catches syntax errors and truly unknown names. See [[roblox-workflow-preferences]].
