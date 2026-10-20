---
name: roblox-cancelled-ui-items
description: UI fixes the owner explicitly cancelled (coach label overlap, redundant potion bottles) and the plan for the next session
metadata:
  type: feedback
---

On 2026-10-08 the owner cancelled two pending UI items and said they will NEVER do them: (1) coach billboard labels overlapping when close, (2) redundant potion bottles shown together when the Rainbow Potion is active. Do not suggest or implement them again.

**Why:** the owner finished the day and chose to drop them for good.

**How to apply:** do not list them as pending options. Next session (2026-10-09) the owner will continue with the Robux phase (Developer Product / game pass IDs, Shop, quick-buy +1K/+10K/+100K Power, potions, Pet Space, VIP, trail/aura, Rebirth SKIP, DOUBLE IT!) and with GAME BALANCING: manual clicking is now up to 12/s (Auto Click 10/s), egg luck was lowered and potions added, so tools/simulate.py must be updated for these before tuning wall HP, level costs and prices. See [[roblox-blender-models-last]] for the history of this phase and [[roblox-owner-design-feedback]] for other rejected items.

**Update (2026-10-09, Robux phase started):** cheap pricing rule: NO Robux price above 150 anywhere (Shop, potions, trails/auras, skip, gifts unlock, VIP game pass) - pricetest enforces it. Potions: wheel/gifts/quest-bonus/DEV potions go to a saved inventory and show as 'USE xN' in Shop > Potions (price shown when none owned); Robux-bought potions are drunk immediately; active potion time is saved. Gift-a-friend button from the reference photo was NOT built. Still to do: balance pass (simulate.py with fast clicking, potions, lower egg luck).

**Update (2026-10-09, balance pass done):** simulate.py now models click speed (cps default 10 = Auto Click). Retuned CostPower 4.9, BaseMaxLevel 25 (anchors level1=10 / level10=22 kept), Wall.HealthGrowthAfter 5; click-denominated rewards (quests, wheel muscle, offline gain) scaled x5. Targets (Auto Click player): r1 ~5 min, r5 ~1.6h, r12 ~11h, r20 ~1.2d, r45 ~4d. Next: wait for owner Studio feedback on pace; Robux Power-pack amounts (+1K/10K/100K = click counts) lost 5x value, flagged to owner.

**Update (2026-10-09, fast game + strong walls):** owner wants the game END (stage 20 / 100th wall) reachable in 10-15 days at 1h/day (~10-14 active hours), then a portal to world 2 later. Tuned Wall.HealthGrowthAfter 3.5 with simulate.py max_hits=40 (walls felt too weak at 12 hits/stage), Legs.StageLevels 5,20,50,90,140,200 + Body.MaxLevel 200 so max muscular form shows from r18. Sim: S5 5min, S10 52min, S15 4.8h, S20 10.6h (r22).

**Update (2026-10-09, Auto Click pass):** owner wants Auto Click sold as a Robux game pass (badge "ONLY R$ x" on the button, price default 99 in Config.AutoClick.Robux). Implemented but INERT until he creates the pass and gives the ID (autoclick= in robux_ids.txt); all other 32 Robux IDs are wired already. Free (no-pass) players are 1.5-4x slower than the 10-15 day target; told him.
