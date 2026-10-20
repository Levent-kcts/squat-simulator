---
name: roblox-owner-design-feedback
description: "Squat Simulator owner's UI/design likes and dislikes (what NOT to add again, how to use their reference screenshots)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: eb377534-0dfc-4b77-ad04-af0c19dec369
---

The owner judges everything against screenshots of a reference "Punch Simulator"-style game and iterates visually (sends Studio screenshots, says "çok kalın", "çok büyük", "kötü duruyor").

Do: measure from the reference screenshot using the character's height (~5.3 studs) as a ruler instead of guessing; keep UI soft (gradient, rounded, shine via `UIStyle.soften`); verify uploaded asset IDs with the Roblox economy API; keep README.md/CLAUDE.md updated ("ara ara not tut").

Do NOT re-add (owner rejected): top player-progress bar, 3D FREE REWARD chest in the lobby, glowing "next goal" pad, neon-red unaffordable pads, screen-wide bloom / glaring ceiling panels, teleport buttons, single Sounds button, daily reward, promo codes (CODES), squat/muscle-gain sounds, the lobby quest board and the lobby Pet Fusion machine (removed 2026-10-06: quests only via the top-right scroll button, pet merging only inside the Pets menu).

For the Pets menu the owner sent a reference screenshot and asked to copy it as closely as possible: semi-transparent black window (world visible behind), left detail panel, Pet Team row, merge progress button. Pet sizes are named Small/Normal/Big/Boss (Boss = Big size + extra effect).

**Why:** each of these was built, shown, and rejected as "kötü/çok fazla" in Studio screenshots.
**How to apply:** before adding a new visible feature, compare with the reference first; prefer the smaller/quieter version; Robux work stays postponed until after the Blender models. Related: [[roblox-workflow-preferences]], [[roblox-blender-models-last]].

**2026-10-09 icon style:** owner rejected emoji icons on Shop cards AND my 3D Blender-rendered icons; wants ALL generated UI icons in one 2D 'game icon set' style (soft gradients, glossy highlights, thin dark-tone outline; reference game-icon-set_107791-33185.avif). Pipeline: tools/icons/make_icons.py (SVG -> Chrome headless -> transparent PNG). Owner uploads PNGs and gives IDs -> Config.Icons. Own supplied icons (menu icons, leg, click, trails, auras) are not redrawn.

**2026-10-09 (later):** owner disliked my own 2D SVG icons too and had Gemini draw all icons from my prompts (assets/icons/AI_PROMPTS.md, style ref assets/icons/reference/game-icon-set.png). I cut the white backgrounds out with tools/icons/cutout.py (Blender python) -> assets/icons/*.png, wired Config.Icons everywhere (shop cards, wheel, gifts, pops, HUD). Owner uploaded all 14 and the IDs are in Config.Icons (2026-10-09, verified Image type); waiting for his Studio check. Don't redraw icons myself again; ask the owner to have the AI redo any he dislikes.

**2026-10-09 worn shoe models REVERTED:** owner asked for modeled shoes on the character's feet instead of neon-painted feet; I built server/ShoeWear (Weld shoe_<id> meshes, fitted to foot size) but he said twice it 'does not sit on the foot exactly' and told me to restore the old state (neon-painted feet). Do NOT re-add worn shoe meshes unless he asks again; if he does, first get real in-game rig measurements (Output) and a precise description of what looks wrong. Code is in git history (commits 0010ed6, c77af24).

**2026-10-09 lobby reference (other game's hall):** owner sent 3 screenshots of another Roblox game's lobby ("Worlds" arch behind a stepped egg terrace, lego brick walls with studded pilasters, coffered ceiling with rectangular lights, path lines on the floor) and said "make our map layout like this". I asked which parts; he picked ONLY wall look + ceiling/floor look (done in server/LobbyDetail). He did NOT pick: swapping sides (training left / shoes right) or making the hall narrower. Do not do those unasked. Also: Worlds arch must stay dim (he said 'çok parlak' once), and the 'SQUAT SIMULATOR' back-wall sign was removed at his request.

**2026-10-09 loading screen bricks:** owner rejected flat Frame-drawn bricks ('çok kötü'), then my 3D ViewportFrame bricks ('çok yukarda, 3 boyutlu yapmışsın, 2d fotoğrafını çek o hareket etsin'). Final: Blender-rendered transparent 2D photo of a 2x2 (4-stud) brick (assets/loading/brick.png, tools/loading/make_brick.py), tinted per brick with ImageColor3, animated as bobbing ImageLabels; he must upload it and give the ID for Config.Icons.LoadingBrick (empty = no bricks). Never go back to Frame-drawn or 3D bricks. Blender -- output path must be absolute.
