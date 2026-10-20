# Graph Report - gracious-gagarin-a4500c  (2026-10-20)

## Corpus Check
- 262 files · ~356,547 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 5 file(s) not represented in the graph (top: (none) 3, .toml 2)

## Summary
- 1810 nodes · 4075 edges · 117 communities (91 shown, 26 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 395 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f5600cb7`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- coaches.py
- replicatedstorage_waitforchild
- Module wiring (init scripts)
- Character appearance and shoes
- Walls, stages and rewards
- Sound and music
- Moves, kick and performance
- Balance simulation tools
- GuideTour.luau
- Blender shoe models
- SeasonEvent.luau
- Blender scene helpers
- Claude Memory Index
- Mock test stubs
- Project rules (CLAUDE.md)
- pets_space.py
- UI style and old theme
- Rising games and Faz B
- Client test stubs
- Daily wheel and project status
- Integer multipliers and catalog
- math
- Power Hour music generator
- UI redesign research (archived)
- Pass icon renderer
- Juice effects
- Power Hour events
- Lobby layout and lighting
- PlayerStats core
- sys
- Blender model library
- pets.py
- WallClient.luau
- Level and rebirth progression
- Mock Test Tool (memory)
- Design analysis sprints
- Skins, training and policy
- Icon cutout tool
- subprocess
- Pet followers and models
- Trail effects
- Blender potion models
- Panel manager
- Marketing plan phases
- Discovery and growth research
- Competitor analysis
- Solo dev cases and World 2
- Mock test runner
- shoes_space.py
- Egg sound generator
- Robux passes and IDs
- Stats panel and formatting
- common.py
- Growth plan and HEP gate
- Event decor and mannequins
- HappyMoments (favorite, clips)
- Pets panel
- Loading screen
- guidetourtest.luau
- Cosmetics and Pet Index panels
- Lobby grade preview
- Egg rules and passes
- LegGrowth.luau
- Level-up sound generator
- Egg shop and hatch reveal
- Playtime gift state
- Settings
- Wheel image generator
- Marketing visuals research
- 04 Retention and Monetization Playbook
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
- README project handover notes
- Overhead tags
- Blender Models Then Robux Last (memory)
- ServerEvents.luau
- script_parent_playerstats
- Speech bubbles
- Barbell image
- Referrals.luau
- Type checker
- Top games trends
- Aura service
- Reveal tests
- WhatsNewCard.luau
- Feed HUD
- LabelScaler.register
- Referral tests
- MCP config
- Auto pass tests
- Memory copy README
- DevTools.luau
- StarterOffer.luau
- GroupReward.luau
- DEV test panel and screenshot mode
- BoostHud.luau
- Analytics.luau
- AutoClickPass.luau
- EggPasses.luau
- shopbadgetest.luau

## God Nodes (most connected - your core abstractions)
1. `CLAUDE.md project instructions` - 84 edges
2. `lighter()` - 53 edges
3. `darker()` - 51 edges
4. `Model` - 34 edges
5. `refresh()` - 26 edges
6. `Project Status (memory)` - 26 edges
7. `Blender Models Then Robux Last (memory)` - 24 edges
8. `Design analysis (OYUN_TASARIM_ANALIZI)` - 23 edges
9. `UI agents shared rules (00_shared)` - 21 edges
10. `06 Modern UI Research` - 20 edges

## Surprising Connections (you probably didn't know these)
- `Sfx.playMusicOverride()` --calls--> `tick()`  [INFERRED]
  src/client/Sfx.luau → tools/mocktest/tests/perftest.luau
- `newPanel()` --calls--> `GiftsPanel.init()`  [INFERRED]
  tools/mocktest/tests/giftstest.luau → src/client/GiftsPanel.luau
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

## Communities (117 total, 26 thin omitted)

### Community 0 - "coaches.py"
Cohesion: 0.17
Nodes (22): aim(), blaze(), blush(), box_at(), brows(), ember(), eyes(), figure() (+14 more)

### Community 1 - "replicatedstorage_waitforchild"
Cohesion: 0.29
Nodes (5): makeLabel(), ShelfClient.fmtMultiplier(), ShelfClient.init(), ShoeShop.init(), SkinShop.init()

### Community 2 - "Module wiring (init scripts)"
Cohesion: 0.06
Nodes (14): addOutlinedIcon(), autoLocked(), create(), loadOptional(), makeGridButton(), makeMenuButton(), makeSquareButton(), makeStatChip() (+6 more)

### Community 3 - "Character appearance and shoes"
Cohesion: 0.13
Nodes (24): addShoeTrail(), AppearanceCleaner.init(), applyPants(), applyShirt(), applyShoes(), captureOriginals(), clean(), clearShoeGlow() (+16 more)

### Community 4 - "Walls, stages and rewards"
Cohesion: 0.09
Nodes (35): addLabel(), buildStageSigns(), newGui(), Purchases.init(), addLabel(), advanceFrontier(), createSign(), createWinButton() (+27 more)

### Community 5 - "Sound and music"
Cohesion: 0.10
Nodes (31): create(), MusicPlayer.init(), text(), triangle(), acquire(), applyMusicVolume(), musicMaxLevel(), newSound() (+23 more)

### Community 6 - "Moves, kick and performance"
Cohesion: 0.06
Nodes (31): apply(), currentBase(), getRig(), heightScaleOf(), isWalking(), Moves.play(), playAnimation(), ratioOf() (+23 more)

### Community 7 - "Balance simulation tools"
Cohesion: 0.16
Nodes (3): run(), Player, run()

### Community 8 - "GuideTour.luau"
Cohesion: 0.15
Nodes (3): buildArrow(), create(), label()

### Community 9 - "Blender shoe models"
Cohesion: 0.08
Nodes (11): build(), core(), Ctx, e_canvas(), e_cleats(), e_hightop(), e_thunder(), side() (+3 more)

### Community 10 - "SeasonEvent.luau"
Cohesion: 0.55
Nodes (10): ensure(), itemById(), keysToString(), publish(), SeasonEvent.active(), SeasonEvent.addCandy(), SeasonEvent.buy(), SeasonEvent.claim() (+2 more)

### Community 11 - "Blender scene helpers"
Cohesion: 0.26
Nodes (24): main(), add_floor(), add_lights(), argv_after_dashes(), export_fbx(), render_view(), reset(), save_blend() (+16 more)

### Community 12 - "Claude Memory Index"
Cohesion: 0.16
Nodes (8): Claude Memory Index, Growth Push 2026-10-14 (memory), Highly Engaged Players (HEP) Threshold, Milestone Promo Codes (100VISITS, 1KVISITS), Owner Approvals 2026-10-14 (memory), Owner Design Feedback (memory), Measure From Reference Screenshots, Keep the Old UI Theme (memory)

### Community 15 - "pets_space.py"
Cohesion: 0.06
Nodes (61): darker(), lighter(), mix(), alien(), camel(), chick(), deer(), frog() (+53 more)

### Community 16 - "UI style and old theme"
Cohesion: 0.16
Nodes (15): drawEgg(), makeEggVisual(), dot(), loopSettle(), modelViewportIcon(), softenUnsafe(), UIStyle.calm(), UIStyle.darken() (+7 more)

### Community 17 - "Rising games and Faz B"
Cohesion: 0.18
Nodes (12): B1 Reward-free favorite prompt, B3 Milestone codes (100VISITS, 1KVISITS, WORLD2), B5 Owner is here hour (dropped), B6 First 3 minutes funnel check, Faz B: In-game growth features, 07a Rising Games Analysis, Admin Abuse / Owner is here event, Code listing sites and codes YouTube channels (+4 more)

### Community 18 - "Client test stubs"
Cohesion: 0.10
Nodes (7): walk(), collectNames(), imageCount(), newCharacter(), newLeg(), countNamed(), countFx()

### Community 19 - "Daily wheel and project status"
Cohesion: 0.14
Nodes (14): Project Status (memory), Rojo Live API Debugging Recipe, safeInit(loadOptional()) Guarded Module Loading, WheelController.init(), buildFace(), create(), makeText(), panel.open() (+6 more)

### Community 21 - "math"
Cohesion: 0.06
Nodes (52): build(), cframe_xml(), matrix(), nref(), pose_xml(), arm(), attach(), empty() (+44 more)

### Community 22 - "Power Hour music generator"
Cohesion: 0.19
Nodes (17): base_phase(), bass_note(), brass_chord(), clap(), crash(), env(), finish(), finish_loop() (+9 more)

### Community 23 - "UI redesign research (archived)"
Cohesion: 0.20
Nodes (21): 06 Modern UI Research, UIStyle.Theme tokens (colors, fonts, radius, tween), UI agents shared rules (00_shared), Design system (UIStyle) agent prompt, UIStyle modern helpers (Theme, panel, header, card, button, label, chip, badge, progressBar, tabs, input, press, pop, countTo, fadeScaleIn), Backpack Trails & Auras panel prompt, Daily login reward panel prompt, Gifts / Playtime Rewards panel prompt (+13 more)

### Community 24 - "Pass icon renderer"
Cohesion: 0.14
Nodes (15): add_lights(), background(), box_blur(), build_text(), compose(), draw_ring(), lerp_color(), load_models() (+7 more)

### Community 25 - "Juice effects"
Cohesion: 0.18
Nodes (15): flushPop(), Juice.banner(), Juice.brickChunks(), Juice.burst(), Juice.celebrate(), Juice.evolve(), Juice.floatText(), Juice.screenPop() (+7 more)

### Community 26 - "Power Hour events"
Cohesion: 0.27
Nodes (9): calm(), clock(), create(), iconInto(), outlined(), PowerHourHud.init(), render(), findNamed() (+1 more)

### Community 27 - "Lobby layout and lighting"
Cohesion: 0.14
Nodes (4): tint(), wallRuns(), block(), Shelf.rightWallFrame()

### Community 28 - "PlayerStats core"
Cohesion: 0.14
Nodes (17): refresh(), fuseOnce(), pickWheelPrize(), PlayerStats.buyAura(), PlayerStats.buyTrail(), PlayerStats.deletePet(), PlayerStats.dev(), PlayerStats.equipAura() (+9 more)

### Community 29 - "sys"
Cohesion: 0.14
Nodes (10): block(), fmt(), ladder(), num(), reward(), robux_value(), stage_hp(), taps_needed() (+2 more)

### Community 31 - "pets.py"
Cohesion: 0.28
Nodes (24): base(), bunny(), cat(), cheeks(), dog(), dragon(), ears_point(), ears_round() (+16 more)

### Community 33 - "Level and rebirth progression"
Cohesion: 0.15
Nodes (6): Progression.cumulativeMuscle(), Progression.levelFromMuscle(), Progression.levelMultiplier(), Progression.maxLevel(), Progression.rebirthMultiplier(), Progression.tapsNeeded()

### Community 34 - "Mock Test Tool (memory)"
Cohesion: 0.20
Nodes (8): Dev Tooling 2026-10-20 (memory), Free Dev Toolchain (Rokit, Selene, StyLua, luau-lsp, Studio MCP, OBS, CapCut), Roblox Studio Built-in MCP, Mock Test Tool (memory), Syntax Check Lesson (memory), Video Shoot 2026-10-19 (memory), Creator Hub Thumbnail Upload Via React Handlers, Promo Shoot Recipe (Studio MCP camera, ffmpeg gdigrab, H hides UI)

### Community 36 - "Skins, training and policy"
Cohesion: 0.15
Nodes (7): AreaPasses.prompt(), Shelf.leftWallFrame(), ShoeShop.init(), buildDummy(), SkinShop.init(), setActive(), TrainingArea.init()

### Community 37 - "Icon cutout tool"
Cohesion: 0.22
Nodes (10): background_mask(), bbox(), blur3(), cutout(), erode(), flood(), load_rgb(), main() (+2 more)

### Community 38 - "subprocess"
Cohesion: 0.13
Nodes (7): run_analyzer(), run_structure(), main(), get_json(), read(), run(), main()

### Community 39 - "Pet followers and models"
Cohesion: 0.23
Nodes (7): PetFollowers.init(), buildEgg(), buildShoes(), findSource(), ModelLibrary.cframe(), ModelLibrary.create(), ModelLibrary.has()

### Community 40 - "Trail effects"
Cohesion: 0.23
Nodes (12): apply(), bindMovement(), brickEmitters(), buildEmitter(), buildRibbon(), clear(), colorSeq(), flat() (+4 more)

### Community 41 - "Blender potion models"
Cohesion: 0.17
Nodes (12): apply_modifiers(), join(), srgb(), badge(), boolean(), build(), cylinder(), mat() (+4 more)

### Community 42 - "Panel manager"
Cohesion: 0.22
Nodes (14): calm(), offscreen(), PanelManager.hide(), PanelManager.isOpen(), PanelManager.register(), PanelManager.show(), PanelManager.toggle(), create() (+6 more)

### Community 43 - "Marketing plan phases"
Cohesion: 0.20
Nodes (10): Faz A: Creator Hub foundation, 07d Platform Levers 2026, Automatic translation (Use Translated Content), Events & Updates announcements, Late 2026 free pass trials / Home pass showcase, Missed settings checklist, OpenCloud personal notifications, Share Links per Channel (+2 more)

### Community 44 - "Discovery and growth research"
Cohesion: 0.22
Nodes (8): 02 Discovery and Growth Research, Ads Manager Engagement objective, Gameplay video on game page, Highly Engaged Player (HEP), 16+ Audience Reach gate, Thumbnail Personalization, HEP threshold drops to 100 (Nov 2026), 16+ gate crossing reports (Aug-Oct 2026)

### Community 45 - "Competitor analysis"
Cohesion: 0.15
Nodes (11): 03 Competitor Analysis, Cheap convenience passes (Auto Click 25-49 R$), Gym League, Muscle Legends, +1 Karate Evolution, +1 Muscle Evolution (name twin), +1 Muscle to Break Walls (closest competitor), +1 Strength for Eggs (+3 more)

### Community 46 - "Solo dev cases and World 2"
Cohesion: 0.09
Nodes (25): Marketing Plan 2026-10-20 (memory), Marketing Plan Phases A>B>C>D, Pumpkin Title Tag (remove Nov 9), 07 Marketing Execution Plan, Faz C: Content rhythm (weekly update, World 2), Faz D: After gate opens (YouTuber outreach, notifications), World 2 (5 stages / 25 walls), +1 Venom Evolution (direct rival) (+17 more)

### Community 47 - "Mock test runner"
Cohesion: 0.21
Nodes (8): source_files(), build(), convert(), main(), module_names(), read(), write(), main()

### Community 48 - "shoes_space.py"
Cohesion: 0.19
Nodes (14): e_bigbang(), e_comet(), e_darkmatter(), e_galaxy(), e_moon(), e_nebula(), e_nova(), e_pulsar() (+6 more)

### Community 49 - "Egg sound generator"
Cohesion: 0.29
Nodes (9): build_dum(), build_puf(), finish(), report(), save(), soft_attack(), spectral_filter(), t_axis() (+1 more)

### Community 51 - "Robux passes and IDs"
Cohesion: 0.23
Nodes (6): Robux product/game pass ID file, Robux products list (ROBUX_URUNLERI), AreaPasses.init(), attributeName(), paidAreas(), publish()

### Community 52 - "Stats panel and formatting"
Cohesion: 0.25
Nodes (11): GiftsPanel.rewardInfo(), refreshSpooky(), bonus(), create(), mult(), StatsPanel.init(), text(), Format.compact() (+3 more)

### Community 53 - "common.py"
Cohesion: 0.07
Nodes (21): cone(), cylinder(), finish(), material(), rounded_box(), sphere(), tube(), mat() (+13 more)

### Community 55 - "Event decor and mannequins"
Cohesion: 0.32
Nodes (9): ball(), buildGhost(), buildPumpkin(), offset(), part(), addExtraFx(), band(), emitter() (+1 more)

### Community 56 - "HappyMoments (favorite, clips)"
Cohesion: 0.38
Nodes (11): askFavorite(), create(), HappyMoments.init(), HappyMoments.trigger(), hideCard(), offerClip(), player(), saveCapture() (+3 more)

### Community 57 - "Pets panel"
Cohesion: 0.27
Nodes (5): addSparkles(), addTrashIcon(), create(), makeButton(), makeText()

### Community 58 - "Loading screen"
Cohesion: 0.24
Nodes (5): addText(), LoadingScreen.build(), LoadingScreen.collectAssets(), LoadingScreen.dots(), LoadingScreen.iconImage()

### Community 59 - "guidetourtest.luau"
Cohesion: 0.15
Nodes (4): calloutText(), cardHas(), find(), hasText()

### Community 60 - "Cosmetics and Pet Index panels"
Cohesion: 0.15
Nodes (9): button(), create(), makeText(), create(), text(), create(), text(), countNamed() (+1 more)

### Community 61 - "Lobby grade preview"
Cohesion: 0.36
Nodes (7): grade(), hsv_to_rgb(), load(), luma_of(), rgb_to_hsv(), save(), smooth()

### Community 62 - "Egg rules and passes"
Cohesion: 0.20
Nodes (12): Fixed-order egg for restricted accounts, cycleMulti(), EggShop.checkPasses(), EggShop.init(), PaidRandomPolicy.check(), PaidRandomPolicy.isRestricted(), Shelf.backWallFrame(), EggRules.autoPass() (+4 more)

### Community 63 - "LegGrowth.luau"
Cohesion: 0.23
Nodes (11): addMuscle(), addMuscleModel(), addShortsPart(), apply(), applyBodyScale(), buildMuscles(), buildShorts(), levelOf() (+3 more)

### Community 64 - "Level-up sound generator"
Cohesion: 0.24
Nodes (5): build(), mix(), note(), report(), save()

### Community 65 - "Egg shop and hatch reveal"
Cohesion: 0.20
Nodes (4): Egg pet-chance panel prompt, create(), EggShop.init(), makeText()

### Community 66 - "Playtime gift state"
Cohesion: 0.38
Nodes (3): GiftState.elapsed(), GiftState.nextRemaining(), GiftState.ready()

### Community 67 - "Settings"
Cohesion: 0.33
Nodes (5): PlayerSettings.get(), PlayerSettings.set(), create(), SettingsPanel.init(), text()

### Community 68 - "Wheel image generator"
Cohesion: 0.36
Nodes (4): main(), prize_colors(), render(), write_png()

### Community 69 - "Marketing visuals research"
Cohesion: 0.20
Nodes (9): 05 Marketing Visuals Zero-Budget Plan, Captures API, Estimated HEP conversion funnel model, 15 short video ideas, Thumbnail gallery audit, Gemini asset prompts (icons, thumbnails), Roblox Moments, B2 Moments clip prompt (Save this moment!) (+1 more)

### Community 70 - "04 Retention and Monetization Playbook"
Cohesion: 0.18
Nodes (9): First-play bounce rate (<60s, 61-180s), Recommended For You (RFY) signals, 04 Retention and Monetization Playbook, Co-play days and spend days signals, Creator Rewards, D1/D7/D30 benchmarks (GameAnalytics 2026), Live-ops seasonal event templates (Halloween/Winter), Roblox Subscriptions (+1 more)

### Community 72 - "Spooky panel"
Cohesion: 0.22
Nodes (4): create(), text(), countNamed(), findText()

### Community 73 - "Offline earnings panel"
Cohesion: 0.31
Nodes (5): bigButton(), create(), duration(), show(), text()

### Community 74 - "Right HUD circles"
Cohesion: 0.17
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
Cohesion: 0.47
Nodes (5): check(), check_tokens(), run(), tokenize(), read_interp()

### Community 82 - "Gifts tests"
Cohesion: 0.20
Nodes (12): create(), describe(), GiftsPanel.init(), makeText(), UIStyle.safePetIcon(), click(), countNamed(), descendants() (+4 more)

### Community 83 - "Lobby plan SVG"
Cohesion: 0.54
Nodes (6): arrow(), circle(), px(), pz(), rect(), text()

### Community 84 - "README project handover notes"
Cohesion: 0.24
Nodes (4): Studio Turkish UI (memory), Roblox Workflow Preferences (memory), Turkish Chat, English Game Text, Turkish Comments, README project handover notes

### Community 85 - "Overhead tags"
Cohesion: 0.18
Nodes (5): Badge gap (rivals use Welcome badge), attach(), OverheadTags.init(), styledLabel(), track()

### Community 86 - "Blender Models Then Robux Last (memory)"
Cohesion: 0.22
Nodes (6): Blender Models Then Robux Last (memory), Pet Simulator 2 Style Box Pets, Each Pet Belongs To Exactly One Egg, Per-Click Leg Muscle, Kick Waits For Contact, Cancelled UI Items + Next Plan (memory), Game Balance Targets (end in 10-15 days at 1h/day)

### Community 87 - "ServerEvents.luau"
Cohesion: 0.42
Nodes (7): applyPowerHour(), ServerEvents.currentState(), ServerEvents.devToggle(), ServerEvents.init(), ServerEvents.powerHourState(), ServerEvents.seasonActive(), serverNow()

### Community 90 - "Barbell image"
Cohesion: 0.38
Nodes (3): cylinder(), smooth(), torus()

### Community 91 - "Referrals.luau"
Cohesion: 0.47
Nodes (8): addPending(), key(), Referrals.addPlaytime(), Referrals.claimForInviter(), Referrals.init(), Referrals.onLoaded(), Referrals.payOut(), takePending()

### Community 92 - "Type checker"
Cohesion: 0.39
Nodes (5): ensure_types(), luau_lsp(), run(), selene(), tool()

### Community 94 - "Top games trends"
Cohesion: 0.33
Nodes (5): 01 Top Games Trend Report, Format cloning speed (Steal An Egg clones), +1 / for Eggs genre cluster, Short average session length (8-19 min), The Hollow platform Halloween event

### Community 95 - "Aura service"
Cohesion: 0.53
Nodes (4): apply(), build(), clear(), watch()

### Community 97 - "WhatsNewCard.luau"
Cohesion: 0.36
Nodes (6): What's New update log UX, create(), text(), WhatsNewCard.init(), countNamed(), findNamed()

### Community 98 - "Feed HUD"
Cohesion: 0.83
Nodes (3): accent(), create(), FeedHud.init()

### Community 100 - "LabelScaler.register"
Cohesion: 0.33
Nodes (3): LabelScaler.register(), LabelScaler.start(), titleColor()

### Community 107 - "StarterOffer.luau"
Cohesion: 0.48
Nodes (5): create(), findProduct(), outlined(), StarterOffer.init(), findNamed()

### Community 108 - "GroupReward.luau"
Cohesion: 0.40
Nodes (4): B4 Group reward (dropped), Climb For Animals Eggs, check(), GroupReward.init()

### Community 109 - "DEV test panel and screenshot mode"
Cohesion: 0.50
Nodes (3): create(), DevPanel.init(), update()

### Community 111 - "BoostHud.luau"
Cohesion: 0.83
Nodes (3): BoostHud.init(), clock(), create()

### Community 112 - "Analytics.luau"
Cohesion: 0.83
Nodes (3): allow(), Analytics.economy(), Analytics.event()

## Ambiguous Edges - Review These
- `Evolution 'Form-Up' moment` → `Game theory reading (reinforcement schedules, SDT, Bartle, Hooked)`  [AMBIGUOUS]
  OYUN_TASARIM_ANALIZI.md · relation: conceptually_related_to
- `Run check.py and mocktest after edits` → `Server authoritative economy`  [AMBIGUOUS]
  CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **47 isolated node(s):** `cmd.exe`, `Creator Rewards`, `D1/D7/D30 benchmarks (GameAnalytics 2026)`, `Roblox Subscriptions`, `Claude Memory Copy README` (+42 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 442 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **26 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Blender Models Then Robux Last (memory)` connect `Blender Models Then Robux Last (memory)` to `coaches.py`, `Skins, training and policy`, `Moves, kick and performance`, `Blender potion models`, `Claude Memory Index`, `BoostHud.luau`, `UI style and old theme`, `pets_space.py`, `Daily wheel and project status`, `README project handover notes`, `Integer multipliers and catalog`, `math`, `Event decor and mannequins`, `common.py`, `pets.py`?**
  _High betweenness centrality (0.282) - this node is a cross-community bridge._
- **What connects `cmd.exe`, `Creator Rewards`, `D1/D7/D30 benchmarks (GameAnalytics 2026)` to the rest of the system?**
  _47 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Module wiring (init scripts)` be split into smaller, more focused modules?**
  _Cohesion score 0.05550416281221091 - nodes in this community are weakly interconnected._
- **Why does `CLAUDE.md project instructions` connect `Project rules (CLAUDE.md)` to `Walls, stages and rewards`, `Sound and music`, `Moves, kick and performance`, `GuideTour.luau`, `UI style and old theme`, `Daily wheel and project status`, `Integer multipliers and catalog`, `UI redesign research (archived)`, `Lobby layout and lighting`, `WallClient.luau`, `Design analysis sprints`, `Skins, training and policy`, `Panel manager`, `Analytics, friends and referrals`, `Robux passes and IDs`, `Growth plan and HEP gate`, `Loading screen`, `Cosmetics and Pet Index panels`, `LegGrowth.luau`, `Egg shop and hatch reveal`, `Settings`, `Offline earnings panel`, `Right HUD circles`, `Daily quests panel`, `Price cuts and trails`, `README project handover notes`, `Overhead tags`, `script_parent_playerstats`, `LabelScaler.register`, `GroupReward.luau`, `DEV test panel and screenshot mode`?**
  _High betweenness centrality (0.134) - this node is a cross-community bridge._
- **Should `Character appearance and shoes` be split into smaller, more focused modules?**
  _Cohesion score 0.1330049261083744 - nodes in this community are weakly interconnected._

### Low-confidence Hints
_AMBIGUOUS edges — the extractor was unsure. Verify before acting on these._

- **What is the exact relationship between `Evolution 'Form-Up' moment` and `Game theory reading (reinforcement schedules, SDT, Bartle, Hooked)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Run check.py and mocktest after edits` and `Server authoritative economy`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._