# Graph Report - RobloxOyun  (2026-10-20)

## Corpus Check
- 260 files · ~348,537 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 4 file(s) not represented in the graph (top: (none) 2, .toml 2)

## Summary
- 1711 nodes · 3743 edges · 106 communities (78 shown, 28 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 322 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f5600cb7`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- coaches.py
- Server support modules
- Module wiring (init scripts)
- Character appearance and shoes
- WallService.luau
- Sound and music
- Moves.luau
- Balance simulation tools
- Guide tour and objectives
- Blender shoe models
- Season event and retention research
- Blender scene helpers
- Owner feedback memory
- Mock test stubs
- Project rules (CLAUDE.md)
- Cover image rendering
- UI style and old theme
- Rising games and Faz B
- Client test stubs
- Daily wheel and project status
- Blender egg models
- Power Hour music generator
- UI redesign research (archived)
- Pass icon renderer
- Juice effects
- Power Hour events
- pets.py
- PlayerStats core
- pets_more.py
- Blender model library
- Kick animation and gate preview
- WallClient.luau
- Progression.luau
- Dev tooling and Studio MCP
- Design analysis (OYUN_TASARIM_ANALIZI)
- client/EggShop.luau
- Icon cutout tool
- Syntax check and mock testing
- PetFollowers.luau
- Trail effects
- Blender potion models
- Panel manager
- 07d Platform Levers 2026
- Discovery and growth research
- Competitor analysis
- 07c Short Video and Creators
- Mock test runner
- Client smoke test
- Egg sound generator
- Analytics, friends and referrals
- Robux passes and IDs
- Stats panel and formatting
- Blender leg muscles
- Growth plan and HEP gate
- Project Status (memory)
- HappyMoments (favorite, clips)
- Pets panel
- Loading screen
- Cosmetics and Pet Index panels
- Lobby grade preview
- Performance.luau
- Lego overlap checker
- Level-up sound generator
- AutoClickPass.luau
- GiftsPanel.luau
- Settings
- Wheel image generator
- Marketing visuals research
- Spooky panel
- Offline earnings panel
- Right HUD circles
- make_kick.py
- Global feed
- Faz A: Creator Hub foundation
- Robux ID setter
- Daily quests panel
- Price cuts and trails
- Lua structure checker
- WhatsNewCard.luau
- Lobby plan SVG
- README handover
- OverheadTags.luau
- GroupReward.luau
- loginpaneltest.luau
- Speech bubbles
- Barbell image
- Analytics.luau
- Layout.luau
- Top games trends
- shared_waitforchild
- Reveal tests
- perftest.luau
- Referral tests
- MCP config
- Auto pass tests
- Memory copy README

## God Nodes (most connected - your core abstractions)
1. `CLAUDE.md project instructions` - 84 edges
2. `darker()` - 30 edges
3. `lighter()` - 29 edges
4. `Model` - 28 edges
5. `refresh()` - 26 edges
6. `Project Status (memory)` - 26 edges
7. `Blender Models Then Robux Last (memory)` - 24 edges
8. `Design analysis (OYUN_TASARIM_ANALIZI)` - 23 edges
9. `UI agents shared rules (00_shared)` - 21 edges
10. `06 Modern UI Research` - 20 edges

## Surprising Connections (you probably didn't know these)
- `Moves.play()` --calls--> `on()`  [INFERRED]
  src/client/Moves.luau → tools/mocktest/tests/perftest.luau
- `Sfx.playMusicOverride()` --calls--> `tick()`  [INFERRED]
  src/client/Sfx.luau → tools/mocktest/tests/perftest.luau
- `newPanel()` --calls--> `GiftsPanel.init()`  [INFERRED]
  tools/mocktest/tests/giftstest.luau → src/client/GiftsPanel.luau
- `Moves.play()` --calls--> `descendants()`  [INFERRED]
  src/client/Moves.luau → tools/mocktest/tests/giftstest.luau
- `PetFollowers.init()` --calls--> `ModelLibrary.cframe()`  [INFERRED]
  src/client/PetFollowers.luau → src/shared/ModelLibrary.luau

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Faz B in-game growth features** — research_07_pazarlama_plani_b1_favorite_prompt, research_07_pazarlama_plani_b2_moments_clip_prompt, research_07_pazarlama_plani_b3_milestone_codes, research_07_pazarlama_plani_b6_funnel_check, src_client_happymoments, src_shared_config [EXTRACTED 1.00]
- **Growth sprint 1 features** — oyun_buyume_plani_sprint1_living_world, claude_global_feed, claude_friend_referral, claude_training_egg, claude_analytics_events, claude_whats_new_card, claude_map_color_zones [EXTRACTED 1.00]
- **Rejected Soft Dark Candy UI redesign prompt set** — research_ui_prompts_00_shared, research_ui_prompts_01_design_system, research_ui_prompts_00_shared_soft_dark_candy, research_ui_prompts_cosmetics, research_ui_prompts_daily, research_ui_prompts_eggpanel, research_ui_prompts_gifts, research_ui_prompts_hud, research_ui_prompts_index, research_ui_prompts_offline, research_ui_prompts_pets, research_ui_prompts_quests, research_ui_prompts_rebirth, research_ui_prompts_settings, research_ui_prompts_shop, research_ui_prompts_spooky, research_ui_prompts_stats, research_ui_prompts_whatsnew, research_ui_prompts_wheel [EXTRACTED 1.00]
- **Owner-rejected visual approaches** — docs_claude_memory_roblox_ui_keep_old_theme_soft_dark_candy, docs_claude_memory_roblox_owner_design_feedback_worn_shoe_revert, docs_claude_memory_roblox_owner_design_feedback_loading_2d_brick, docs_claude_memory_roblox_cancelled_ui_items_cancelled_ui_items, docs_claude_memory_roblox_owner_design_feedback_rejected_features [INFERRED 0.75]
- **Growth and marketing push** — docs_claude_memory_roblox_growth_push_2026_10_14_growth_guardrails, docs_claude_memory_roblox_owner_approvals_2026_10_14_approval_reversal, docs_claude_memory_roblox_marketing_plan_2026_10_20_marketing_phases, docs_claude_memory_roblox_video_shoot_2026_10_19_shoot_recipe, docs_claude_memory_roblox_marketing_plan_2026_10_20_hep_threshold [INFERRED 0.85]
- **New player onboarding flow** — claude_guide_tour_objective, claude_starter_quests, claude_auto_click_game_pass, claude_potions_auto_click_potion, oyun_tasarim_analizi_onboarding_funnel [INFERRED 0.85]
- **Paid random item compliance mechanisms** — claude_paid_random_items_policy, claude_training_egg, claude_spooky_gym_event, claude_starter_pack, claude_egg_passes_hidden_price [INFERRED 0.85]
- **RFY retention signals** — research_02_discovery_growth_recommended_for_you, research_02_discovery_growth_first_play_bounce, research_04_retention_monetization_coplay_and_spend_days, research_04_retention_monetization_d1_benchmarks, research_05_marketing_visuals_promise_play_match [INFERRED 0.85]
- **16+ gate and HEP threshold mechanics** — research_02_discovery_growth_sixteen_plus_gate, research_02_discovery_growth_highly_engaged_player, research_07_pazarlama_plani_hep_threshold_100, research_07d_platform_kaldiraclari_2026_gate_crossing_reports, research_02_discovery_growth_ads_manager_engagement [INFERRED 0.85]
- **Static + mock + Studio verification toolchain** — docs_claude_memory_roblox_syntax_check_lesson_syntax_check_rule, docs_claude_memory_roblox_mocktest_tool_mock_roblox_testing, docs_claude_memory_roblox_dev_tooling_2026_10_20_studio_mcp, tools_typecheck [INFERRED 0.85]

## Communities (106 total, 28 thin omitted)

### Community 0 - "coaches.py"
Cohesion: 0.17
Nodes (22): aim(), blaze(), blush(), box_at(), brows(), ember(), eyes(), figure() (+14 more)

### Community 1 - "Server support modules"
Cohesion: 0.06
Nodes (28): create(), DevPanel.init(), LabelScaler.register(), LabelScaler.start(), update(), makeLabel(), ShelfClient.fmtMultiplier(), ShelfClient.init() (+20 more)

### Community 2 - "Module wiring (init scripts)"
Cohesion: 0.06
Nodes (13): addOutlinedIcon(), autoLocked(), create(), loadOptional(), makeGridButton(), makeMenuButton(), makeSquareButton(), makeStatChip() (+5 more)

### Community 3 - "Character appearance and shoes"
Cohesion: 0.12
Nodes (24): addShoeTrail(), AppearanceCleaner.init(), applyPants(), applyShirt(), applyShoes(), captureOriginals(), clean(), clearShoeGlow() (+16 more)

### Community 4 - "WallService.luau"
Cohesion: 0.06
Nodes (34): refreshAll(), refreshGate(), unlockedSet(), WorldsGateClient.init(), Build.block(), EggShop.init(), addLabel(), buildStageSigns() (+26 more)

### Community 5 - "Sound and music"
Cohesion: 0.10
Nodes (31): create(), MusicPlayer.init(), text(), triangle(), acquire(), applyMusicVolume(), musicMaxLevel(), newSound() (+23 more)

### Community 6 - "Moves.luau"
Cohesion: 0.29
Nodes (12): apply(), currentBase(), getRig(), heightScaleOf(), isWalking(), Moves.play(), playAnimation(), ratioOf() (+4 more)

### Community 7 - "Balance simulation tools"
Cohesion: 0.08
Nodes (14): Game Balance Targets (end in 10-15 days at 1h/day), run(), block(), fmt(), ladder(), num(), Player, reward() (+6 more)

### Community 8 - "Guide tour and objectives"
Cohesion: 0.07
Nodes (7): buildArrow(), create(), label(), calloutText(), cardHas(), find(), hasText()

### Community 9 - "Blender shoe models"
Cohesion: 0.09
Nodes (8): Ctx, e_canvas(), e_cleats(), e_hightop(), e_thunder(), side(), slab(), smoothstep()

### Community 10 - "Season event and retention research"
Cohesion: 0.17
Nodes (20): 04 Retention and Monetization Playbook, Creator Rewards, D1/D7/D30 benchmarks (GameAnalytics 2026), Fixed-order egg for restricted accounts, Live-ops seasonal event templates (Halloween/Winter), Roblox Subscriptions, Starter pack, What's New update log UX (+12 more)

### Community 11 - "Blender scene helpers"
Cohesion: 0.12
Nodes (30): main(), add_floor(), add_lights(), apply_modifiers(), argv_after_dashes(), export_fbx(), join(), material() (+22 more)

### Community 12 - "Owner feedback memory"
Cohesion: 0.11
Nodes (18): Claude Memory Index, Cancelled UI Items + Next Plan (memory), Dev Tooling 2026-10-20 (memory), Free Dev Toolchain (Rokit, Selene, StyLua, luau-lsp, Studio MCP, OBS, CapCut), Roblox Studio Built-in MCP, Growth Push 2026-10-14 (memory), Marketing Plan 2026-10-20 (memory), Highly Engaged Players (HEP) Threshold (+10 more)

### Community 15 - "Cover image rendering"
Cohesion: 0.11
Nodes (13): cone(), cylinder(), finish(), rounded_box(), sphere(), tube(), arm(), attach() (+5 more)

### Community 16 - "UI style and old theme"
Cohesion: 0.17
Nodes (14): Keep the Old UI Theme (memory), dot(), loopSettle(), modelViewportIcon(), softenUnsafe(), UIStyle.calm(), UIStyle.darken(), UIStyle.eggModelIcon() (+6 more)

### Community 17 - "Rising games and Faz B"
Cohesion: 0.12
Nodes (18): +1 Karate Evolution, B1 Reward-free favorite prompt, B3 Milestone codes (100VISITS, 1KVISITS, WORLD2), B5 Owner is here hour (dropped), B6 First 3 minutes funnel check, Faz B: In-game growth features, World 2 (5 stages / 25 walls), 07a Rising Games Analysis (+10 more)

### Community 18 - "Client test stubs"
Cohesion: 0.09
Nodes (11): walk(), collectNames(), imageCount(), newCharacter(), newLeg(), childText(), find(), countNamed() (+3 more)

### Community 19 - "Daily wheel and project status"
Cohesion: 0.15
Nodes (12): WheelController.init(), buildFace(), create(), makeText(), panel.open(), panel.place(), textLabel(), WheelService.init() (+4 more)

### Community 21 - "Blender egg models"
Cohesion: 0.27
Nodes (16): desert(), euler_align(), euler_from_axes(), forest(), FRONT_OF(), galaxy(), ice(), lava() (+8 more)

### Community 22 - "Power Hour music generator"
Cohesion: 0.19
Nodes (17): base_phase(), bass_note(), brass_chord(), clap(), crash(), env(), finish(), finish_loop() (+9 more)

### Community 23 - "UI redesign research (archived)"
Cohesion: 0.18
Nodes (15): 06 Modern UI Research, UIStyle.Theme tokens (colors, fonts, radius, tween), UI agents shared rules (00_shared), Design system (UIStyle) agent prompt, UIStyle modern helpers (Theme, panel, header, card, button, label, chip, badge, progressBar, tabs, input, press, pop, countTo, fadeScaleIn), Daily login reward panel prompt, Egg pet-chance panel prompt, Offline Earnings window prompt (+7 more)

### Community 24 - "Pass icon renderer"
Cohesion: 0.14
Nodes (15): add_lights(), background(), box_blur(), build_text(), compose(), draw_ring(), lerp_color(), load_models() (+7 more)

### Community 25 - "Juice effects"
Cohesion: 0.18
Nodes (15): flushPop(), Juice.banner(), Juice.brickChunks(), Juice.burst(), Juice.celebrate(), Juice.evolve(), Juice.floatText(), Juice.screenPop() (+7 more)

### Community 26 - "Power Hour events"
Cohesion: 0.17
Nodes (16): calm(), clock(), create(), iconInto(), outlined(), PowerHourHud.init(), render(), applyPowerHour() (+8 more)

### Community 27 - "pets.py"
Cohesion: 0.26
Nodes (25): Pet Simulator 2 Style Box Pets, base(), bunny(), cat(), cheeks(), dog(), dragon(), ears_point() (+17 more)

### Community 28 - "PlayerStats core"
Cohesion: 0.15
Nodes (16): refresh(), fuseOnce(), pickWheelPrize(), PlayerStats.buyAura(), PlayerStats.buyTrail(), PlayerStats.deletePet(), PlayerStats.equipAura(), PlayerStats.equipBestPets() (+8 more)

### Community 29 - "pets_more.py"
Cohesion: 0.15
Nodes (20): darker(), lighter(), mix(), alien(), camel(), chick(), deer(), frog() (+12 more)

### Community 31 - "Kick animation and gate preview"
Cohesion: 0.42
Nodes (5): front_view(), main(), poly(), rect(), side_view()

### Community 32 - "WallClient.luau"
Cohesion: 0.24
Nodes (3): addFrame(), darker(), decorateBrick()

### Community 33 - "Progression.luau"
Cohesion: 0.12
Nodes (18): addMuscle(), addMuscleModel(), addShortsPart(), apply(), applyBodyScale(), buildMuscles(), buildShorts(), levelOf() (+10 more)

### Community 34 - "Dev tooling and Studio MCP"
Cohesion: 0.19
Nodes (4): get_json(), read(), run(), main()

### Community 35 - "Design analysis (OYUN_TASARIM_ANALIZI)"
Cohesion: 0.15
Nodes (3): Design analysis (OYUN_TASARIM_ANALIZI), tint(), wallRuns()

### Community 36 - "client/EggShop.luau"
Cohesion: 0.05
Nodes (37): create(), cycleMulti(), EggShop.init(), makeText(), AreaPasses.init(), AreaPasses.prompt(), attributeName(), paidAreas() (+29 more)

### Community 37 - "Icon cutout tool"
Cohesion: 0.22
Nodes (10): background_mask(), bbox(), blur3(), cutout(), erode(), flood(), load_rgb(), main() (+2 more)

### Community 38 - "Syntax check and mock testing"
Cohesion: 0.18
Nodes (9): run_analyzer(), run_structure(), source_files(), main(), ensure_types(), luau_lsp(), run(), selene() (+1 more)

### Community 40 - "Trail effects"
Cohesion: 0.23
Nodes (12): apply(), bindMovement(), brickEmitters(), buildEmitter(), buildRibbon(), clear(), colorSeq(), flat() (+4 more)

### Community 41 - "Blender potion models"
Cohesion: 0.16
Nodes (11): badge(), boolean(), build(), cylinder(), main(), mat(), rainbow_material(), render_one() (+3 more)

### Community 42 - "Panel manager"
Cohesion: 0.19
Nodes (16): Rebirth confirm screen prompt, Shop panel prompt, calm(), offscreen(), PanelManager.hide(), PanelManager.isOpen(), PanelManager.register(), PanelManager.show() (+8 more)

### Community 43 - "07d Platform Levers 2026"
Cohesion: 0.22
Nodes (9): Highly Engaged Player (HEP), 16+ Audience Reach gate, HEP threshold drops to 100 (Nov 2026), 07d Platform Levers 2026, Events & Updates announcements, Late 2026 free pass trials / Home pass showcase, 16+ gate crossing reports (Aug-Oct 2026), Missed settings checklist (+1 more)

### Community 44 - "Discovery and growth research"
Cohesion: 0.22
Nodes (7): 02 Discovery and Growth Research, Ads Manager Engagement objective, First-play bounce rate (<60s, 61-180s), Gameplay video on game page, Recommended For You (RFY) signals, Thumbnail Personalization, Co-play days and spend days signals

### Community 45 - "Competitor analysis"
Cohesion: 0.17
Nodes (9): 03 Competitor Analysis, Badge gap (rivals use Welcome badge), Cheap convenience passes (Auto Click 25-49 R$), Gym League, Muscle Legends, +1 Muscle Evolution (name twin), +1 Muscle to Break Walls (closest competitor), +1 Strength for Eggs (+1 more)

### Community 46 - "07c Short Video and Creators"
Cohesion: 0.10
Nodes (17): Faz C: Content rhythm (weekly update, World 2), Faz D: After gate opens (YouTuber outreach, notifications), 07b Solo Developer Case Studies, Balloon Pop Simulator (ad failure case), Checklocked (16+ era case), Fixed update cadence (Update Party), Grow a Garden (solo case), 99 Nights in the Forest (+9 more)

### Community 47 - "Mock test runner"
Cohesion: 0.27
Nodes (7): build(), convert(), main(), module_names(), read(), write(), main()

### Community 48 - "Client smoke test"
Cohesion: 0.19
Nodes (8): activeCount(), allButtonsWith(), buttonNamed(), buttonWith(), countText(), hasPattern(), textsUnder(), wallGui()

### Community 49 - "Egg sound generator"
Cohesion: 0.29
Nodes (9): build_dum(), build_puf(), finish(), report(), save(), soft_attack(), spectral_filter(), t_axis() (+1 more)

### Community 52 - "Stats panel and formatting"
Cohesion: 0.28
Nodes (10): GiftsPanel.rewardInfo(), refreshSpooky(), create(), mult(), StatsPanel.init(), text(), Format.compact(), Format.multiplier() (+2 more)

### Community 53 - "Blender leg muscles"
Cohesion: 0.15
Nodes (10): Blender Models Then Robux Last (memory), Each Pet Belongs To Exactly One Egg, Per-Click Leg Muscle, Kick Waits For Contact, calf(), dummy_leg(), ell(), glute(), preview() (+2 more)

### Community 55 - "Project Status (memory)"
Cohesion: 0.17
Nodes (8): Mock Test Tool (memory), Project Status (memory), Rojo Live API Debugging Recipe, safeInit(loadOptional()) Guarded Module Loading, Studio Turkish UI (memory), Syntax Check Lesson (memory), Roblox Workflow Preferences (memory), Turkish Chat, English Game Text, Turkish Comments

### Community 56 - "HappyMoments (favorite, clips)"
Cohesion: 0.38
Nodes (11): askFavorite(), create(), HappyMoments.init(), HappyMoments.trigger(), hideCard(), offerClip(), player(), saveCapture() (+3 more)

### Community 57 - "Pets panel"
Cohesion: 0.22
Nodes (7): Pets inventory/team/merge panel prompt, addSparkles(), addTrashIcon(), bonus(), create(), makeButton(), makeText()

### Community 58 - "Loading screen"
Cohesion: 0.24
Nodes (5): addText(), LoadingScreen.build(), LoadingScreen.collectAssets(), LoadingScreen.dots(), LoadingScreen.iconImage()

### Community 60 - "Cosmetics and Pet Index panels"
Cohesion: 0.16
Nodes (9): Backpack Trails & Auras panel prompt, Pet Index panel prompt, button(), create(), makeText(), create(), text(), create() (+1 more)

### Community 61 - "Lobby grade preview"
Cohesion: 0.36
Nodes (7): grade(), hsv_to_rgb(), load(), luma_of(), rgb_to_hsv(), save(), smooth()

### Community 62 - "Performance.luau"
Cohesion: 0.30
Nodes (9): anchorPart(), applyLow(), cull(), kindOf(), Performance.init(), Performance.setLow(), scan(), track() (+1 more)

### Community 63 - "Lego overlap checker"
Cohesion: 0.31
Nodes (8): axes(), brick(), build(), corners(), gap(), obb(), tower(), wheel()

### Community 64 - "Level-up sound generator"
Cohesion: 0.24
Nodes (5): build(), mix(), note(), report(), save()

### Community 66 - "GiftsPanel.luau"
Cohesion: 0.13
Nodes (16): Gifts / Playtime Rewards panel prompt, create(), describe(), GiftsPanel.init(), makeText(), GiftState.elapsed(), GiftState.nextRemaining(), GiftState.ready() (+8 more)

### Community 67 - "Settings"
Cohesion: 0.29
Nodes (6): Settings panel prompt, PlayerSettings.get(), PlayerSettings.set(), create(), SettingsPanel.init(), text()

### Community 68 - "Wheel image generator"
Cohesion: 0.33
Nodes (4): main(), prize_colors(), render(), write_png()

### Community 69 - "Marketing visuals research"
Cohesion: 0.20
Nodes (9): 05 Marketing Visuals Zero-Budget Plan, Captures API, Estimated HEP conversion funnel model, 15 short video ideas, Thumbnail gallery audit, Gemini asset prompts (icons, thumbnails), Roblox Moments, B2 Moments clip prompt (Save this moment!) (+1 more)

### Community 72 - "Spooky panel"
Cohesion: 0.29
Nodes (3): Spooky Gym event panel prompt, create(), text()

### Community 73 - "Offline earnings panel"
Cohesion: 0.31
Nodes (5): bigButton(), create(), duration(), show(), text()

### Community 74 - "Right HUD circles"
Cohesion: 0.31
Nodes (4): create(), RightHud.init(), text(), UIStyle.soften()

### Community 75 - "make_kick.py"
Cohesion: 0.43
Nodes (5): build(), cframe_xml(), matrix(), nref(), pose_xml()

### Community 76 - "Global feed"
Cohesion: 0.39
Nodes (5): clean(), deliver(), GlobalFeed.announce(), GlobalFeed.receive(), underLimit()

### Community 77 - "Faz A: Creator Hub foundation"
Cohesion: 0.29
Nodes (6): Faz A: Creator Hub foundation, Seasonal title prefix [pumpkin]/[W2], Automatic translation (Use Translated Content), Share Links per Channel, Per-channel Share Links (TikTok, YouTube, Group, DevForum, Reddit, Chat Server, Reels), Text filter rejects platform names in campaign names

### Community 78 - "Robux ID setter"
Cohesion: 0.33
Nodes (4): apply_ids(), block(), read_products(), write_template()

### Community 79 - "Daily quests panel"
Cohesion: 0.39
Nodes (6): create(), makeText(), QuestPanel.claimable(), QuestPanel.read(), QuestPanel.readStarter(), QuestPanel.starterClaimable()

### Community 81 - "Lua structure checker"
Cohesion: 0.36
Nodes (5): check(), check_tokens(), run(), tokenize(), read_interp()

### Community 82 - "WhatsNewCard.luau"
Cohesion: 0.43
Nodes (5): create(), text(), WhatsNewCard.init(), countNamed(), findNamed()

### Community 83 - "Lobby plan SVG"
Cohesion: 0.54
Nodes (6): arrow(), circle(), px(), pz(), rect(), text()

### Community 84 - "README handover"
Cohesion: 0.20
Nodes (3): README project handover notes, Purchases.init(), add()

### Community 85 - "OverheadTags.luau"
Cohesion: 0.16
Nodes (4): attach(), OverheadTags.init(), styledLabel(), track()

### Community 86 - "GroupReward.luau"
Cohesion: 0.40
Nodes (4): B4 Group reward (dropped), Climb For Animals Eggs, check(), GroupReward.init()

### Community 90 - "Barbell image"
Cohesion: 0.38
Nodes (3): cylinder(), smooth(), torus()

### Community 92 - "Analytics.luau"
Cohesion: 0.83
Nodes (3): allow(), Analytics.economy(), Analytics.event()

### Community 94 - "Top games trends"
Cohesion: 0.33
Nodes (5): 01 Top Games Trend Report, Format cloning speed (Steal An Egg clones), +1 / for Eggs genre cluster, Short average session length (8-19 min), The Hollow platform Halloween event

### Community 95 - "shared_waitforchild"
Cohesion: 0.18
Nodes (11): HUD redesign prompt, BoostHud.init(), clock(), create(), accent(), create(), FeedHud.init(), apply() (+3 more)

## Ambiguous Edges - Review These
- `Evolution 'Form-Up' moment` → `Game theory reading (reinforcement schedules, SDT, Bartle, Hooked)`  [AMBIGUOUS]
  OYUN_TASARIM_ANALIZI.md · relation: conceptually_related_to
- `Run check.py and mocktest after edits` → `Server authoritative economy`  [AMBIGUOUS]
  CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **47 isolated node(s):** `cmd.exe`, `Creator Rewards`, `D1/D7/D30 benchmarks (GameAnalytics 2026)`, `Roblox Subscriptions`, `Claude Memory Copy README` (+42 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 427 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **28 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Blender Models Then Robux Last (memory)` connect `Blender leg muscles` to `coaches.py`, `client/EggShop.luau`, `Moves.luau`, `Balance simulation tools`, `Blender potion models`, `Owner feedback memory`, `UI style and old theme`, `README handover`, `Integer multipliers and catalog`, `Blender egg models`, `Project Status (memory)`, `pets.py`, `pets_more.py`, `shared_waitforchild`?**
  _High betweenness centrality (0.242) - this node is a cross-community bridge._
- **What connects `cmd.exe`, `Creator Rewards`, `D1/D7/D30 benchmarks (GameAnalytics 2026)` to the rest of the system?**
  _47 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Server support modules` be split into smaller, more focused modules?**
  _Cohesion score 0.06294326241134751 - nodes in this community are weakly interconnected._
- **Why does `CLAUDE.md project instructions` connect `Project rules (CLAUDE.md)` to `Server support modules`, `Character appearance and shoes`, `WallService.luau`, `Sound and music`, `Moves.luau`, `Guide tour and objectives`, `UI style and old theme`, `Daily wheel and project status`, `Integer multipliers and catalog`, `UI redesign research (archived)`, `Progression.luau`, `Design analysis (OYUN_TASARIM_ANALIZI)`, `client/EggShop.luau`, `Panel manager`, `Analytics, friends and referrals`, `Robux passes and IDs`, `Growth plan and HEP gate`, `Project Status (memory)`, `Loading screen`, `Monetization features`, `Cosmetics and Pet Index panels`, `AutoClickPass.luau`, `Settings`, `TapFilter.luau`, `Offline earnings panel`, `Right HUD circles`, `Daily quests panel`, `Price cuts and trails`, `README handover`, `OverheadTags.luau`, `GroupReward.luau`, `Layout.luau`?**
  _High betweenness centrality (0.137) - this node is a cross-community bridge._
- **Should `Module wiring (init scripts)` be split into smaller, more focused modules?**
  _Cohesion score 0.05550416281221091 - nodes in this community are weakly interconnected._

### Low-confidence Hints
_AMBIGUOUS edges — the extractor was unsure. Verify before acting on these._

- **What is the exact relationship between `Evolution 'Form-Up' moment` and `Game theory reading (reinforcement schedules, SDT, Bartle, Hooked)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Run check.py and mocktest after edits` and `Server authoritative economy`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._