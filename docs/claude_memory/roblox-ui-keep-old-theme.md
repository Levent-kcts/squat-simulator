---
name: roblox-ui-keep-old-theme
description: "Owner rejected the 'modern' Soft Dark Candy UI redesign (2026-10-16) and wants the OLD thick-black-outline FredokaOne theme everywhere; new UI must imitate the old theme"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 240fbf36-2cef-4efe-b22b-a133dab67080
  modified: 2026-10-16T17:48:05.529Z
---

On 2026-10-14 I (via many subagents) redesigned every panel/HUD in a "Soft Dark Candy" style (dark navy, thin outlines, Gotham fonts, new UIStyle.panel/header/card/button API). The owner disliked it ("çok problemli") and on 2026-10-16 asked to restore the old look and make any newer-added buttons resemble the old theme.

**Why:** The original thick black outline + FredokaOne + soften gradient look is what the owner chose and approved over many iterations (see [[roblox-owner-design-feedback]]).

**How to apply:** Panels were reverted to commit 1fd16a0 versions. The unused new UIStyle API was deleted on 2026-10-16 at the owner's request (only calm/loopTween kept for the Calm UI setting). For any new panel/button use the old pattern (UIStyle.soften, thick black UIStroke, FredokaOne). Never propose "modernizing" the UI again without the owner asking. Daily is a top-right circle next to Quests; Mastery was permanently deleted on 2026-10-16 at the owner's request (restore from commit 476eab6 only if asked).
