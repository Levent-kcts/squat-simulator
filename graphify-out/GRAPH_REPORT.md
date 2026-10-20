# Graph Report - RobloxOyun  (2026-10-20)

## Corpus Check
- 258 files · ~344,352 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 4 file(s) not represented in the graph (top: (none) 2, .toml 2)

## Summary
- 1713 nodes · 3760 edges · 106 communities (83 shown, 23 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 330 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f7b6b717`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Blender pet and coach models
- Server support modules
- Module wiring (init scripts)
- Character appearance and shoes
- Walls, stages and rewards
- Sound and music
- Moves, kick and performance
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
- Lobby layout and lighting
- PlayerStats core
- Blender imports
- Blender model library
- Kick animation and gate preview
- Wall client and boost HUD
- Level and rebirth progression
- Dev tooling and Studio MCP
- Design analysis sprints
- Skins, training and policy
- Icon cutout tool
- Syntax check and mock testing
- Pet followers and models
- Trail effects
- Blender potion models
- Panel manager
- Marketing plan phases
- Discovery and growth research
- Competitor analysis
- Solo dev cases and World 2
- Mock test runner
- Client smoke test
- Egg sound generator
- Robux passes and IDs
- Stats panel and formatting
- Blender leg muscles
- Growth plan and HEP gate
- Event decor and mannequins
- HappyMoments (favorite, clips)
- Pets panel
- Loading screen
- Cosmetics and Pet Index panels
- Lobby grade preview
- Egg rules and passes
- Lego overlap checker
- Level-up sound generator
- Egg shop and hatch reveal
- Playtime gift state
- Settings
- Wheel image generator
- Marketing visuals research
- Short video and creators
- Spooky panel
- Offline earnings panel
- Right HUD circles
- Build helpers and Worlds gate
- Global feed
- Leaderboards
- Robux ID setter
- Daily quests panel
- Price cuts and trails
- Lua structure checker
- Gifts tests
- Lobby plan SVG
- README handover
- Overhead tags
- Preflight check
- Gifts panel
- Daily login panel
- Speech bubbles
- Barbell image
- Type checker
- Top games trends
- Aura service
- Reveal tests
- Shop panel
- Feed HUD
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
- `newPanel()` --calls--> `GiftsPanel.init()`  [INFERRED]
  tools/mocktest/tests/giftstest.luau → src/client/GiftsPanel.luau
- `Sfx.playMusicOverride()` --calls--> `tick()`  [INFERRED]
  src/client/Sfx.luau → tools/mocktest/tests/perftest.luau
- `Moves.play()` --calls--> `descendants()`  [INFERRED]
  src/client/Moves.luau → tools/mocktest/tests/giftstest.luau
- `Moves.play()` --calls--> `on()`  [INFERRED]
  src/client/Moves.luau → tools/mocktest/tests/perftest.luau
- `StatsPanel.init()` --calls--> `Progression.levelMultiplier()`  [INFERRED]
  src/client/StatsPanel.luau → src/shared/Progression.luau

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

## Communities (106 total, 23 thin omitted)

### Community 0 - "Blender pet and coach models"
Cohesion: 0.08
Nodes (66): aim(), blaze(), blush(), box_at(), brows(), ember(), eyes(), figure() (+58 more)

### Community 1 - "Server support modules"
Cohesion: 0.05
Nodes (32): create(), DevPanel.init(), LabelScaler.register(), LabelScaler.start(), update(), makeLabel(), ShelfClient.fmtMultiplier(), ShelfClient.init() (+24 more)

### Community 2 - "Module wiring (init scripts)"
Cohesion: 0.06
Nodes (14): addOutlinedIcon(), autoLocked(), create(), loadOptional(), makeGridButton(), makeMenuButton(), makeSquareButton(), makeStatChip() (+6 more)

### Community 3 - "Character appearance and shoes"
Cohesion: 0.08
Nodes (35): addShoeTrail(), AppearanceCleaner.init(), applyPants(), applyShirt(), applyShoes(), captureOriginals(), clean(), clearShoeGlow() (+27 more)

### Community 4 - "Walls, stages and rewards"
Cohesion: 0.09
Nodes (35): addLabel(), buildStageSigns(), newGui(), Purchases.init(), addLabel(), advanceFrontier(), createSign(), createWinButton() (+27 more)

### Community 5 - "Sound and music"
Cohesion: 0.10
Nodes (31): create(), MusicPlayer.init(), text(), triangle(), acquire(), applyMusicVolume(), musicMaxLevel(), newSound() (+23 more)

### Community 6 - "Moves, kick and performance"
Cohesion: 0.08
Nodes (23): apply(), currentBase(), getRig(), heightScaleOf(), isWalking(), Moves.play(), playAnimation(), ratioOf() (+15 more)

### Community 7 - "Balance simulation tools"
Cohesion: 0.08
Nodes (13): run(), block(), fmt(), ladder(), num(), Player, reward(), robux_value() (+5 more)

### Community 8 - "Guide tour and objectives"
Cohesion: 0.07
Nodes (7): buildArrow(), create(), label(), calloutText(), cardHas(), find(), hasText()

### Community 9 - "Blender shoe models"
Cohesion: 0.08
Nodes (12): build(), core(), Ctx, e_canvas(), e_cleats(), e_hightop(), e_thunder(), main() (+4 more)

### Community 10 - "Season event and retention research"
Cohesion: 0.12
Nodes (25): 04 Retention and Monetization Playbook, Creator Rewards, D1/D7/D30 benchmarks (GameAnalytics 2026), Fixed-order egg for restricted accounts, Live-ops seasonal event templates (Halloween/Winter), Roblox Subscriptions, Starter pack, What's New update log UX (+17 more)

### Community 11 - "Blender scene helpers"
Cohesion: 0.16
Nodes (24): main(), add_floor(), add_lights(), argv_after_dashes(), export_fbx(), material(), render_view(), reset() (+16 more)

### Community 12 - "Owner feedback memory"
Cohesion: 0.11
Nodes (16): Claude Memory Index, Blender Models Then Robux Last (memory), Pet Simulator 2 Style Box Pets, Each Pet Belongs To Exactly One Egg, Per-Click Leg Muscle, Kick Waits For Contact, Cancelled UI Items + Next Plan (memory), Game Balance Targets (end in 10-15 days at 1h/day), Growth Push 2026-10-14 (memory) (+8 more)

### Community 15 - "Cover image rendering"
Cohesion: 0.11
Nodes (13): cone(), cylinder(), finish(), rounded_box(), sphere(), tube(), arm(), attach() (+5 more)

### Community 16 - "UI style and old theme"
Cohesion: 0.14
Nodes (17): Keep the Old UI Theme (memory), UIStyle.Theme tokens (colors, fonts, radius, tween), drawEgg(), makeEggVisual(), dot(), loopSettle(), modelViewportIcon(), softenUnsafe() (+9 more)

### Community 17 - "Rising games and Faz B"
Cohesion: 0.10
Nodes (20): B1 Reward-free favorite prompt, B3 Milestone codes (100VISITS, 1KVISITS, WORLD2), B4 Group reward (dropped), B5 Owner is here hour (dropped), B6 First 3 minutes funnel check, Faz B: In-game growth features, 07a Rising Games Analysis, Admin Abuse / Owner is here event (+12 more)

### Community 18 - "Client test stubs"
Cohesion: 0.10
Nodes (9): walk(), collectNames(), imageCount(), newCharacter(), newLeg(), childText(), find(), countNamed() (+1 more)

### Community 19 - "Daily wheel and project status"
Cohesion: 0.13
Nodes (15): Project Status (memory), Rojo Live API Debugging Recipe, safeInit(loadOptional()) Guarded Module Loading, WheelController.init(), buildFace(), create(), makeText(), panel.open() (+7 more)

### Community 21 - "Blender egg models"
Cohesion: 0.27
Nodes (16): desert(), euler_align(), euler_from_axes(), forest(), FRONT_OF(), galaxy(), ice(), lava() (+8 more)

### Community 22 - "Power Hour music generator"
Cohesion: 0.19
Nodes (17): base_phase(), bass_note(), brass_chord(), clap(), crash(), env(), finish(), finish_loop() (+9 more)

### Community 23 - "UI redesign research (archived)"
Cohesion: 0.22
Nodes (20): 06 Modern UI Research, UI agents shared rules (00_shared), Design system (UIStyle) agent prompt, UIStyle modern helpers (Theme, panel, header, card, button, label, chip, badge, progressBar, tabs, input, press, pop, countTo, fadeScaleIn), Backpack Trails & Auras panel prompt, Daily login reward panel prompt, Egg pet-chance panel prompt, HUD redesign prompt (+12 more)

### Community 24 - "Pass icon renderer"
Cohesion: 0.14
Nodes (15): add_lights(), background(), box_blur(), build_text(), compose(), draw_ring(), lerp_color(), load_models() (+7 more)

### Community 25 - "Juice effects"
Cohesion: 0.18
Nodes (15): flushPop(), Juice.banner(), Juice.brickChunks(), Juice.burst(), Juice.celebrate(), Juice.evolve(), Juice.floatText(), Juice.screenPop() (+7 more)

### Community 26 - "Power Hour events"
Cohesion: 0.17
Nodes (16): calm(), clock(), create(), iconInto(), outlined(), PowerHourHud.init(), render(), applyPowerHour() (+8 more)

### Community 27 - "Lobby layout and lighting"
Cohesion: 0.14
Nodes (4): tint(), wallRuns(), block(), Shelf.rightWallFrame()

### Community 28 - "PlayerStats core"
Cohesion: 0.17
Nodes (16): refresh(), fuseOnce(), pickWheelPrize(), PlayerStats.buyAura(), PlayerStats.buyTrail(), PlayerStats.deletePet(), PlayerStats.equipAura(), PlayerStats.equipBestPets() (+8 more)

### Community 30 - "Blender model library"
Cohesion: 0.17
Nodes (3): apply_modifiers(), join(), Model

### Community 31 - "Kick animation and gate preview"
Cohesion: 0.20
Nodes (10): build(), cframe_xml(), matrix(), nref(), pose_xml(), front_view(), main(), poly() (+2 more)

### Community 32 - "Wall client and boost HUD"
Cohesion: 0.14
Nodes (4): BoostHud.init(), clock(), create(), WallClient.isNearWall()

### Community 33 - "Level and rebirth progression"
Cohesion: 0.15
Nodes (7): PlayerStats.dev(), Progression.cumulativeMuscle(), Progression.levelFromMuscle(), Progression.levelMultiplier(), Progression.maxLevel(), Progression.rebirthMultiplier(), Progression.tapsNeeded()

### Community 34 - "Dev tooling and Studio MCP"
Cohesion: 0.19
Nodes (8): Dev Tooling 2026-10-20 (memory), Free Dev Toolchain (Rokit, Selene, StyLua, luau-lsp, Studio MCP, OBS, CapCut), Roblox Studio Built-in MCP, Video Shoot 2026-10-19 (memory), Creator Hub Thumbnail Upload Via React Handlers, Promo Shoot Recipe (Studio MCP camera, ffmpeg gdigrab, H hides UI), get_json(), main()

### Community 36 - "Skins, training and policy"
Cohesion: 0.17
Nodes (4): AreaPasses.prompt(), buildDummy(), setActive(), TrainingArea.init()

### Community 37 - "Icon cutout tool"
Cohesion: 0.22
Nodes (10): background_mask(), bbox(), blur3(), cutout(), erode(), flood(), load_rgb(), main() (+2 more)

### Community 38 - "Syntax check and mock testing"
Cohesion: 0.19
Nodes (6): Mock Test Tool (memory), Syntax Check Lesson (memory), run_analyzer(), run_structure(), source_files(), main()

### Community 39 - "Pet followers and models"
Cohesion: 0.17
Nodes (10): PetFollowers.init(), buildEgg(), Shelf.leftWallFrame(), buildShoes(), ShoeShop.init(), SkinShop.init(), findSource(), ModelLibrary.cframe() (+2 more)

### Community 40 - "Trail effects"
Cohesion: 0.23
Nodes (12): apply(), bindMovement(), brickEmitters(), buildEmitter(), buildRibbon(), clear(), colorSeq(), flat() (+4 more)

### Community 41 - "Blender potion models"
Cohesion: 0.26
Nodes (9): badge(), boolean(), build(), cylinder(), mat(), rainbow_material(), sphere(), star_object() (+1 more)

### Community 42 - "Panel manager"
Cohesion: 0.30
Nodes (10): calm(), offscreen(), PanelManager.hide(), PanelManager.isOpen(), PanelManager.register(), PanelManager.show(), PanelManager.toggle(), create() (+2 more)

### Community 43 - "Marketing plan phases"
Cohesion: 0.18
Nodes (14): Marketing Plan 2026-10-20 (memory), Marketing Plan Phases A>B>C>D, Pumpkin Title Tag (remove Nov 9), 07 Marketing Execution Plan, Faz A: Creator Hub foundation, 07d Platform Levers 2026, Automatic translation (Use Translated Content), Events & Updates announcements (+6 more)

### Community 44 - "Discovery and growth research"
Cohesion: 0.16
Nodes (11): 02 Discovery and Growth Research, Ads Manager Engagement objective, First-play bounce rate (<60s, 61-180s), Gameplay video on game page, Highly Engaged Player (HEP), Recommended For You (RFY) signals, 16+ Audience Reach gate, Thumbnail Personalization (+3 more)

### Community 45 - "Competitor analysis"
Cohesion: 0.14
Nodes (11): 03 Competitor Analysis, Badge gap (rivals use Welcome badge), Cheap convenience passes (Auto Click 25-49 R$), Gym League, Muscle Legends, +1 Karate Evolution, +1 Muscle Evolution (name twin), +1 Muscle to Break Walls (closest competitor) (+3 more)

### Community 46 - "Solo dev cases and World 2"
Cohesion: 0.14
Nodes (13): Faz C: Content rhythm (weekly update, World 2), World 2 (5 stages / 25 walls), +1 Venom Evolution (direct rival), Same engine, new verb second game, 07b Solo Developer Case Studies, Balloon Pop Simulator (ad failure case), Checklocked (16+ era case), Fixed update cadence (Update Party) (+5 more)

### Community 47 - "Mock test runner"
Cohesion: 0.27
Nodes (7): build(), convert(), main(), module_names(), read(), write(), main()

### Community 48 - "Client smoke test"
Cohesion: 0.19
Nodes (8): activeCount(), allButtonsWith(), buttonNamed(), buttonWith(), countText(), hasPattern(), textsUnder(), wallGui()

### Community 49 - "Egg sound generator"
Cohesion: 0.29
Nodes (9): build_dum(), build_puf(), finish(), report(), save(), soft_attack(), spectral_filter(), t_axis() (+1 more)

### Community 51 - "Robux passes and IDs"
Cohesion: 0.23
Nodes (6): Robux product/game pass ID file, Robux products list (ROBUX_URUNLERI), AreaPasses.init(), attributeName(), paidAreas(), publish()

### Community 52 - "Stats panel and formatting"
Cohesion: 0.28
Nodes (10): GiftsPanel.rewardInfo(), refreshSpooky(), create(), mult(), StatsPanel.init(), text(), Format.compact(), Format.multiplier() (+2 more)

### Community 53 - "Blender leg muscles"
Cohesion: 0.21
Nodes (7): calf(), dummy_leg(), ell(), glute(), preview(), rot_x_about(), thigh()

### Community 55 - "Event decor and mannequins"
Cohesion: 0.32
Nodes (9): ball(), buildGhost(), buildPumpkin(), offset(), part(), addExtraFx(), band(), emitter() (+1 more)

### Community 56 - "HappyMoments (favorite, clips)"
Cohesion: 0.38
Nodes (11): askFavorite(), create(), HappyMoments.init(), HappyMoments.trigger(), hideCard(), offerClip(), player(), saveCapture() (+3 more)

### Community 57 - "Pets panel"
Cohesion: 0.24
Nodes (6): addSparkles(), addTrashIcon(), bonus(), create(), makeButton(), makeText()

### Community 58 - "Loading screen"
Cohesion: 0.24
Nodes (5): addText(), LoadingScreen.build(), LoadingScreen.collectAssets(), LoadingScreen.dots(), LoadingScreen.iconImage()

### Community 60 - "Cosmetics and Pet Index panels"
Cohesion: 0.25
Nodes (5): button(), create(), makeText(), create(), text()

### Community 61 - "Lobby grade preview"
Cohesion: 0.36
Nodes (7): grade(), hsv_to_rgb(), load(), luma_of(), rgb_to_hsv(), save(), smooth()

### Community 62 - "Egg rules and passes"
Cohesion: 0.25
Nodes (9): cycleMulti(), EggShop.checkPasses(), EggShop.init(), Shelf.backWallFrame(), EggRules.autoPass(), EggRules.owns(), EggRules.pass(), EggRules.passForCount() (+1 more)

### Community 63 - "Lego overlap checker"
Cohesion: 0.31
Nodes (8): axes(), brick(), build(), corners(), gap(), obb(), tower(), wheel()

### Community 64 - "Level-up sound generator"
Cohesion: 0.24
Nodes (5): build(), mix(), note(), report(), save()

### Community 65 - "Egg shop and hatch reveal"
Cohesion: 0.29
Nodes (3): create(), EggShop.init(), makeText()

### Community 66 - "Playtime gift state"
Cohesion: 0.24
Nodes (4): Gifts / Playtime Rewards panel prompt, GiftState.elapsed(), GiftState.nextRemaining(), GiftState.ready()

### Community 67 - "Settings"
Cohesion: 0.33
Nodes (5): PlayerSettings.get(), PlayerSettings.set(), create(), SettingsPanel.init(), text()

### Community 68 - "Wheel image generator"
Cohesion: 0.33
Nodes (4): main(), prize_colors(), render(), write_png()

### Community 69 - "Marketing visuals research"
Cohesion: 0.20
Nodes (9): 05 Marketing Visuals Zero-Budget Plan, Captures API, Estimated HEP conversion funnel model, 15 short video ideas, Thumbnail gallery audit, Gemini asset prompts (icons, thumbnails), Roblox Moments, B2 Moments clip prompt (Save this moment!) (+1 more)

### Community 70 - "Short video and creators"
Cohesion: 0.20
Nodes (8): Faz D: After gate opens (YouTuber outreach, notifications), 07c Short Video and Creators, Creator email/DM template, 'Every Second +1 X' long video format, 10 hook sentences, Level 1 vs MAX Shorts format, Quaaacks (creator; +1 STRENGTH to Smash Walls), Solo devlog story (TyLen)

### Community 72 - "Spooky panel"
Cohesion: 0.22
Nodes (4): create(), text(), countNamed(), findText()

### Community 73 - "Offline earnings panel"
Cohesion: 0.31
Nodes (5): bigButton(), create(), duration(), show(), text()

### Community 74 - "Right HUD circles"
Cohesion: 0.31
Nodes (4): create(), RightHud.init(), text(), UIStyle.soften()

### Community 75 - "Build helpers and Worlds gate"
Cohesion: 0.36
Nodes (5): Build.block(), glowPart(), place(), stone(), textPlate()

### Community 76 - "Global feed"
Cohesion: 0.39
Nodes (5): clean(), deliver(), GlobalFeed.announce(), GlobalFeed.receive(), underLimit()

### Community 77 - "Leaderboards"
Cohesion: 0.39
Nodes (6): boardValue(), buildBoard(), iconLabel(), Leaderboards.init(), pillar(), textLabel()

### Community 78 - "Robux ID setter"
Cohesion: 0.33
Nodes (4): apply_ids(), block(), read_products(), write_template()

### Community 79 - "Daily quests panel"
Cohesion: 0.39
Nodes (6): create(), makeText(), QuestPanel.claimable(), QuestPanel.read(), QuestPanel.readStarter(), QuestPanel.starterClaimable()

### Community 81 - "Lua structure checker"
Cohesion: 0.36
Nodes (5): check(), check_tokens(), run(), tokenize(), read_interp()

### Community 82 - "Gifts tests"
Cohesion: 0.32
Nodes (7): click(), countNamed(), descendants(), findButton(), findFirst(), newPanel(), textsIn()

### Community 83 - "Lobby plan SVG"
Cohesion: 0.54
Nodes (6): arrow(), circle(), px(), pz(), rect(), text()

### Community 85 - "Overhead tags"
Cohesion: 0.38
Nodes (4): attach(), OverheadTags.init(), styledLabel(), track()

### Community 87 - "Gifts panel"
Cohesion: 0.48
Nodes (5): create(), describe(), GiftsPanel.init(), makeText(), UIStyle.safePetIcon()

### Community 88 - "Daily login panel"
Cohesion: 0.33
Nodes (4): create(), text(), countNamed(), findText()

### Community 90 - "Barbell image"
Cohesion: 0.38
Nodes (3): cylinder(), smooth(), torus()

### Community 92 - "Type checker"
Cohesion: 0.48
Nodes (5): ensure_types(), luau_lsp(), run(), selene(), tool()

### Community 94 - "Top games trends"
Cohesion: 0.33
Nodes (5): 01 Top Games Trend Report, Format cloning speed (Steal An Egg clones), +1 / for Eggs genre cluster, Short average session length (8-19 min), The Hollow platform Halloween event

### Community 95 - "Aura service"
Cohesion: 0.53
Nodes (4): apply(), build(), clear(), watch()

### Community 97 - "Shop panel"
Cohesion: 0.70
Nodes (4): create(), ShopPanel.init(), text(), UIStyle.headerIcon()

### Community 98 - "Feed HUD"
Cohesion: 0.83
Nodes (3): accent(), create(), FeedHud.init()

## Ambiguous Edges - Review These
- `Evolution 'Form-Up' moment` → `Game theory reading (reinforcement schedules, SDT, Bartle, Hooked)`  [AMBIGUOUS]
  OYUN_TASARIM_ANALIZI.md · relation: conceptually_related_to
- `Run check.py and mocktest after edits` → `Server authoritative economy`  [AMBIGUOUS]
  CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **47 isolated node(s):** `cmd.exe`, `Creator Rewards`, `D1/D7/D30 benchmarks (GameAnalytics 2026)`, `Roblox Subscriptions`, `Claude Memory Copy README` (+42 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 421 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **23 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Blender Models Then Robux Last (memory)` connect `Owner feedback memory` to `Wall client and boost HUD`, `Blender pet and coach models`, `Skins, training and policy`, `Moves, kick and performance`, `Blender potion models`, `UI style and old theme`, `Daily wheel and project status`, `README handover`, `Integer multipliers and catalog`, `Blender egg models`, `Event decor and mannequins`, `Blender leg muscles`, `Blender imports`?**
  _High betweenness centrality (0.252) - this node is a cross-community bridge._
- **What connects `cmd.exe`, `Creator Rewards`, `D1/D7/D30 benchmarks (GameAnalytics 2026)` to the rest of the system?**
  _47 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Blender pet and coach models` be split into smaller, more focused modules?**
  _Cohesion score 0.07825507825507826 - nodes in this community are weakly interconnected._
- **Why does `CLAUDE.md project instructions` connect `Project rules (CLAUDE.md)` to `Server support modules`, `Character appearance and shoes`, `Walls, stages and rewards`, `Sound and music`, `Moves, kick and performance`, `Guide tour and objectives`, `Owner feedback memory`, `UI style and old theme`, `Rising games and Faz B`, `Daily wheel and project status`, `Integer multipliers and catalog`, `UI redesign research (archived)`, `Lobby layout and lighting`, `Design analysis sprints`, `Skins, training and policy`, `Panel manager`, `Analytics, friends and referrals`, `Robux passes and IDs`, `Growth plan and HEP gate`, `Loading screen`, `Monetization features`, `Cosmetics and Pet Index panels`, `Egg shop and hatch reveal`, `Playtime gift state`, `Settings`, `Offline earnings panel`, `Right HUD circles`, `Daily quests panel`, `Price cuts and trails`, `README handover`, `Overhead tags`?**
  _High betweenness centrality (0.153) - this node is a cross-community bridge._
- **Should `Server support modules` be split into smaller, more focused modules?**
  _Cohesion score 0.05137844611528822 - nodes in this community are weakly interconnected._

### Low-confidence Hints
_AMBIGUOUS edges — the extractor was unsure. Verify before acting on these._

- **What is the exact relationship between `Evolution 'Form-Up' moment` and `Game theory reading (reinforcement schedules, SDT, Bartle, Hooked)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Run check.py and mocktest after edits` and `Server authoritative economy`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._