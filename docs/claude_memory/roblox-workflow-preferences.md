---
name: roblox-workflow-preferences
description: "How to work on the Squat Simulator Roblox project (languages, README upkeep, testing limits, design rules)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: eb377534-0dfc-4b77-ad04-af0c19dec369
  modified: 2026-10-04T15:20:29.438Z
---

Chat with the user in Turkish; ALL in-game text in English; code comments in Turkish.

Keep `README.md` (hand-off doc) and `CLAUDE.md` updated after every meaningful change: add new things, remove outdated ones.
**Why:** the user explicitly asked for README to be the hand-off file after context resets.
**How to apply:** finish each feature by editing both files (file map, game rules, TODO), then summarise how to test in Studio.

The user is the only tester (Studio, sends screenshots/Output errors); Claude cannot run Studio and `rojo build` does not check Luau syntax, so review edits by hand and give "how to verify" plus the tunable constants.

Shelf/stand visuals were rebuilt many times for being "too big": reference proportions are torso ~2 studs, pedestal 4, spacing 6.5, lane depth 8, tiers 0.4/3.4/6.4 (see `server/Shelf.luau`). Match references 1:1 and avoid oversizing.

Skins use only fantasy colours (never realistic human skin tones) so tones are not ranked by price/power. Child-safety rules: black shorts always stay on (see [[roblox-game-rules-shorts]] if written).
