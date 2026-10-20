# Graph Report - RobloxOyun  (2026-10-20)

## Corpus Check
- 261 files · ~349,791 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 4 file(s) not represented in the graph (top: (none) 2, .toml 2)

## Summary
- 1715 nodes · 3755 edges · 119 communities (94 shown, 25 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 327 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `966dad59`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- coaches.py
- DevTools.luau
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
- Claude Memory Index
- Mock test stubs
- Project rules (CLAUDE.md)
- Cover image rendering
- UIStyle.luau
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
- make_kick.py
- shared_waitforchild
- Progression.luau
- Dev tooling and Studio MCP
- Design analysis (OYUN_TASARIM_ANALIZI)
- TrainingArea.luau
- Icon cutout tool
- Syntax check and mock testing
- server/EggShop.luau
- Trail effects
- Blender potion models
- Panel manager
- 07 Marketing Execution Plan
- Discovery and growth research
- Competitor analysis
- 07c Short Video and Creators
- Mock test runner
- Progression.luau
- Egg sound generator
- Robux passes and IDs
- Stats panel and formatting
- muscles.py
- Growth plan and HEP gate
- EventDecor.luau
- HappyMoments (favorite, clips)
- Pets panel
- Loading screen
- Cosmetics and Pet Index panels
- Lobby grade preview
- client/EggShop.luau
- Lego overlap checker
- Level-up sound generator
- AutoClickPass.luau
- GiftsPanel.luau
- Settings
- Wheel image generator
- Marketing visuals research
- Blender Models Then Robux Last (memory)
- Spooky panel
- Offline earnings panel
- Right HUD circles
- replicatedstorage_waitforchild
- Global feed
- Faz A: Creator Hub foundation
- Robux ID setter
- ServerEvents.luau
- Price cuts and trails
- Lua structure checker
- GiftState.luau
- Lobby plan SVG
- README handover
- OverheadTags.luau
- GroupReward.luau
- script_parent_playerstats
- Speech bubbles
- EggRules.luau
- WheelPanel.luau
- Layout.luau
- Top games trends
- AuraService.luau
- Reveal tests
- Layout.world
- Leaderboards.luau
- Referral tests
- MCP config
- Referrals.luau
- Memory copy README
- LabelScaler.register
- preflight.py
- StarterOffer.luau
- Hub.luau
- typecheck.py
- Bright ambient lighting, no bloom
- Reveal.luau
- AreaPasses.luau
- WorldsGate.luau
- WorldsGateClient.luau
- shoetrailtest.luau
- FeedHud.luau

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

## Communities (119 total, 25 thin omitted)

### Community 0 - "coaches.py"
Cohesion: 0.17
Nodes (22): aim(), blaze(), blush(), box_at(), brows(), ember(), eyes(), figure() (+14 more)

### Community 1 - "DevTools.luau"
Cohesion: 0.22
Nodes (5): create(), DevPanel.init(), update(), isAllowed(), mark()

### Community 2 - "Module wiring (init scripts)"
Cohesion: 0.06
Nodes (13): addOutlinedIcon(), autoLocked(), create(), loadOptional(), makeGridButton(), makeMenuButton(), makeSquareButton(), makeStatChip() (+5 more)

### Community 3 - "Character appearance and shoes"
Cohesion: 0.16
Nodes (21): addShoeTrail(), AppearanceCleaner.init(), applyPants(), applyShirt(), applyShoes(), captureOriginals(), clean(), clearShoeGlow() (+13 more)

### Community 4 - "WallService.luau"
Cohesion: 0.27
Nodes (9): addLabel(), createWinButton(), isVip(), newRun(), playerWorld(), resetRun(), teleportToSpawn(), vipEnabled() (+1 more)

### Community 5 - "Sound and music"
Cohesion: 0.10
Nodes (31): create(), MusicPlayer.init(), text(), triangle(), acquire(), applyMusicVolume(), musicMaxLevel(), newSound() (+23 more)

### Community 6 - "Moves.luau"
Cohesion: 0.08
Nodes (23): apply(), currentBase(), getRig(), heightScaleOf(), isWalking(), Moves.play(), playAnimation(), ratioOf() (+15 more)

### Community 7 - "Balance simulation tools"
Cohesion: 0.08
Nodes (13): run(), block(), fmt(), ladder(), num(), Player, reward(), robux_value() (+5 more)

### Community 8 - "Guide tour and objectives"
Cohesion: 0.06
Nodes (13): buildArrow(), create(), label(), create(), makeText(), QuestPanel.claimable(), QuestPanel.read(), QuestPanel.readStarter() (+5 more)

### Community 9 - "Blender shoe models"
Cohesion: 0.09
Nodes (8): Ctx, e_canvas(), e_cleats(), e_hightop(), e_thunder(), side(), slab(), smoothstep()

### Community 10 - "Season event and retention research"
Cohesion: 0.12
Nodes (25): 04 Retention and Monetization Playbook, Creator Rewards, D1/D7/D30 benchmarks (GameAnalytics 2026), Fixed-order egg for restricted accounts, Live-ops seasonal event templates (Halloween/Winter), Roblox Subscriptions, Starter pack, What's New update log UX (+17 more)

### Community 11 - "Blender scene helpers"
Cohesion: 0.18
Nodes (22): main(), add_floor(), add_lights(), apply_modifiers(), argv_after_dashes(), export_fbx(), join(), reset() (+14 more)

### Community 12 - "Claude Memory Index"
Cohesion: 0.18
Nodes (8): Claude Memory Index, Growth Push 2026-10-14 (memory), Owner Approvals 2026-10-14 (memory), Owner Design Feedback (memory), Measure From Reference Screenshots, Studio Turkish UI (memory), Roblox Workflow Preferences (memory), Turkish Chat, English Game Text, Turkish Comments

### Community 13 - "Mock test stubs"
Cohesion: 0.07
Nodes (4): blank(), encode(), fakePlayer(), join()

### Community 15 - "Cover image rendering"
Cohesion: 0.10
Nodes (10): save_blend(), sphere(), arm(), attach(), empty(), leg(), load(), place() (+2 more)

### Community 16 - "UIStyle.luau"
Cohesion: 0.06
Nodes (28): Keep the Old UI Theme (memory), BoostHud.init(), clock(), create(), dot(), loopSettle(), modelViewportIcon(), softenUnsafe() (+20 more)

### Community 17 - "Rising games and Faz B"
Cohesion: 0.11
Nodes (19): B1 Reward-free favorite prompt, B3 Milestone codes (100VISITS, 1KVISITS, WORLD2), B5 Owner is here hour (dropped), B6 First 3 minutes funnel check, Faz B: In-game growth features, World 2 (5 stages / 25 walls), 07a Rising Games Analysis, Admin Abuse / Owner is here event (+11 more)

### Community 18 - "Client test stubs"
Cohesion: 0.10
Nodes (9): walk(), collectNames(), imageCount(), newCharacter(), newLeg(), childText(), find(), countNamed() (+1 more)

### Community 19 - "Daily wheel and project status"
Cohesion: 0.22
Nodes (9): Project Status (memory), Rojo Live API Debugging Recipe, safeInit(loadOptional()) Guarded Module Loading, textLabel(), WheelService.init(), Catalog.iconImage(), create(), text() (+1 more)

### Community 21 - "Blender egg models"
Cohesion: 0.27
Nodes (16): desert(), euler_align(), euler_from_axes(), forest(), FRONT_OF(), galaxy(), ice(), lava() (+8 more)

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

### Community 27 - "pets.py"
Cohesion: 0.28
Nodes (24): base(), bunny(), cat(), cheeks(), dog(), dragon(), ears_point(), ears_round() (+16 more)

### Community 28 - "PlayerStats core"
Cohesion: 0.14
Nodes (17): refresh(), fuseOnce(), pickWheelPrize(), PlayerStats.buyAura(), PlayerStats.buyTrail(), PlayerStats.deletePet(), PlayerStats.dev(), PlayerStats.equipAura() (+9 more)

### Community 29 - "pets_more.py"
Cohesion: 0.19
Nodes (20): darker(), lighter(), mix(), alien(), camel(), chick(), deer(), frog() (+12 more)

### Community 31 - "make_kick.py"
Cohesion: 0.13
Nodes (13): build(), cframe_xml(), matrix(), nref(), pose_xml(), cylinder(), smooth(), torus() (+5 more)

### Community 32 - "shared_waitforchild"
Cohesion: 0.16
Nodes (4): tint(), wallRuns(), block(), Shelf.rightWallFrame()

### Community 33 - "Progression.luau"
Cohesion: 0.23
Nodes (11): addMuscle(), addMuscleModel(), addShortsPart(), apply(), applyBodyScale(), buildMuscles(), buildShorts(), levelOf() (+3 more)

### Community 34 - "Dev tooling and Studio MCP"
Cohesion: 0.19
Nodes (8): Dev Tooling 2026-10-20 (memory), Free Dev Toolchain (Rokit, Selene, StyLua, luau-lsp, Studio MCP, OBS, CapCut), Roblox Studio Built-in MCP, Video Shoot 2026-10-19 (memory), Creator Hub Thumbnail Upload Via React Handlers, Promo Shoot Recipe (Studio MCP camera, ffmpeg gdigrab, H hides UI), get_json(), main()

### Community 36 - "TrainingArea.luau"
Cohesion: 0.16
Nodes (7): AreaPasses.prompt(), Shelf.leftWallFrame(), ShoeShop.init(), buildDummy(), SkinShop.init(), setActive(), TrainingArea.init()

### Community 37 - "Icon cutout tool"
Cohesion: 0.22
Nodes (10): background_mask(), bbox(), blur3(), cutout(), erode(), flood(), load_rgb(), main() (+2 more)

### Community 38 - "Syntax check and mock testing"
Cohesion: 0.19
Nodes (6): Mock Test Tool (memory), Syntax Check Lesson (memory), run_analyzer(), run_structure(), source_files(), main()

### Community 39 - "server/EggShop.luau"
Cohesion: 0.21
Nodes (7): PetFollowers.init(), buildEgg(), buildShoes(), findSource(), ModelLibrary.cframe(), ModelLibrary.create(), ModelLibrary.has()

### Community 40 - "Trail effects"
Cohesion: 0.23
Nodes (12): apply(), bindMovement(), brickEmitters(), buildEmitter(), buildRibbon(), clear(), colorSeq(), flat() (+4 more)

### Community 41 - "Blender potion models"
Cohesion: 0.21
Nodes (10): srgb(), badge(), boolean(), build(), cylinder(), mat(), rainbow_material(), sphere() (+2 more)

### Community 42 - "Panel manager"
Cohesion: 0.24
Nodes (13): calm(), offscreen(), PanelManager.hide(), PanelManager.isOpen(), PanelManager.register(), PanelManager.show(), PanelManager.toggle(), create() (+5 more)

### Community 43 - "07 Marketing Execution Plan"
Cohesion: 0.15
Nodes (12): Marketing Plan 2026-10-20 (memory), Highly Engaged Players (HEP) Threshold, Marketing Plan Phases A>B>C>D, Milestone Promo Codes (100VISITS, 1KVISITS), Pumpkin Title Tag (remove Nov 9), 07 Marketing Execution Plan, 07b Solo Developer Case Studies, Balloon Pop Simulator (ad failure case) (+4 more)

### Community 44 - "Discovery and growth research"
Cohesion: 0.16
Nodes (11): 02 Discovery and Growth Research, Ads Manager Engagement objective, First-play bounce rate (<60s, 61-180s), Gameplay video on game page, Highly Engaged Player (HEP), Recommended For You (RFY) signals, 16+ Audience Reach gate, Thumbnail Personalization (+3 more)

### Community 45 - "Competitor analysis"
Cohesion: 0.14
Nodes (11): 03 Competitor Analysis, Badge gap (rivals use Welcome badge), Cheap convenience passes (Auto Click 25-49 R$), Gym League, Muscle Legends, +1 Karate Evolution, +1 Muscle Evolution (name twin), +1 Muscle to Break Walls (closest competitor) (+3 more)

### Community 46 - "07c Short Video and Creators"
Cohesion: 0.15
Nodes (11): Faz C: Content rhythm (weekly update, World 2), Faz D: After gate opens (YouTuber outreach, notifications), Fixed update cadence (Update Party), 07c Short Video and Creators, 14-day content calendar (21 Oct - 3 Nov), Creator email/DM template, 'Every Second +1 X' long video format, 10 hook sentences (+3 more)

### Community 47 - "Mock test runner"
Cohesion: 0.27
Nodes (7): build(), convert(), main(), module_names(), read(), write(), main()

### Community 48 - "Progression.luau"
Cohesion: 0.15
Nodes (6): Progression.cumulativeMuscle(), Progression.levelFromMuscle(), Progression.levelMultiplier(), Progression.maxLevel(), Progression.rebirthMultiplier(), Progression.tapsNeeded()

### Community 49 - "Egg sound generator"
Cohesion: 0.29
Nodes (9): build_dum(), build_puf(), finish(), report(), save(), soft_attack(), spectral_filter(), t_axis() (+1 more)

### Community 51 - "Robux passes and IDs"
Cohesion: 0.25
Nodes (4): Robux product/game pass ID file, Robux products list (ROBUX_URUNLERI), EggPasses.init(), publish()

### Community 52 - "Stats panel and formatting"
Cohesion: 0.28
Nodes (10): GiftsPanel.rewardInfo(), refreshSpooky(), create(), mult(), StatsPanel.init(), text(), Format.compact(), Format.multiplier() (+2 more)

### Community 53 - "muscles.py"
Cohesion: 0.11
Nodes (18): cone(), cylinder(), finish(), material(), render_view(), rounded_box(), mat(), by_name_of() (+10 more)

### Community 55 - "EventDecor.luau"
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
Cohesion: 0.15
Nodes (9): button(), create(), makeText(), create(), text(), create(), text(), countNamed() (+1 more)

### Community 61 - "Lobby grade preview"
Cohesion: 0.36
Nodes (7): grade(), hsv_to_rgb(), load(), luma_of(), rgb_to_hsv(), save(), smooth()

### Community 62 - "client/EggShop.luau"
Cohesion: 0.29
Nodes (3): create(), EggShop.init(), makeText()

### Community 63 - "Lego overlap checker"
Cohesion: 0.31
Nodes (8): axes(), brick(), build(), corners(), gap(), obb(), tower(), wheel()

### Community 64 - "Level-up sound generator"
Cohesion: 0.24
Nodes (5): build(), mix(), note(), report(), save()

### Community 66 - "GiftsPanel.luau"
Cohesion: 0.20
Nodes (12): create(), describe(), GiftsPanel.init(), makeText(), UIStyle.safePetIcon(), click(), countNamed(), descendants() (+4 more)

### Community 67 - "Settings"
Cohesion: 0.29
Nodes (6): PlayerSettings.get(), PlayerSettings.set(), create(), SettingsPanel.init(), text(), UIStyle.headerIcon()

### Community 68 - "Wheel image generator"
Cohesion: 0.33
Nodes (4): main(), prize_colors(), render(), write_png()

### Community 69 - "Marketing visuals research"
Cohesion: 0.20
Nodes (9): 05 Marketing Visuals Zero-Budget Plan, Captures API, Estimated HEP conversion funnel model, 15 short video ideas, Thumbnail gallery audit, Gemini asset prompts (icons, thumbnails), Roblox Moments, B2 Moments clip prompt (Save this moment!) (+1 more)

### Community 70 - "Blender Models Then Robux Last (memory)"
Cohesion: 0.22
Nodes (6): Blender Models Then Robux Last (memory), Pet Simulator 2 Style Box Pets, Each Pet Belongs To Exactly One Egg, Per-Click Leg Muscle, Kick Waits For Contact, Cancelled UI Items + Next Plan (memory), Game Balance Targets (end in 10-15 days at 1h/day)

### Community 72 - "Spooky panel"
Cohesion: 0.22
Nodes (4): create(), text(), countNamed(), findText()

### Community 73 - "Offline earnings panel"
Cohesion: 0.31
Nodes (5): bigButton(), create(), duration(), show(), text()

### Community 74 - "Right HUD circles"
Cohesion: 0.31
Nodes (4): create(), RightHud.init(), text(), UIStyle.soften()

### Community 75 - "replicatedstorage_waitforchild"
Cohesion: 0.29
Nodes (5): makeLabel(), ShelfClient.fmtMultiplier(), ShelfClient.init(), ShoeShop.init(), SkinShop.init()

### Community 76 - "Global feed"
Cohesion: 0.39
Nodes (5): clean(), deliver(), GlobalFeed.announce(), GlobalFeed.receive(), underLimit()

### Community 77 - "Faz A: Creator Hub foundation"
Cohesion: 0.17
Nodes (11): Faz A: Creator Hub foundation, Seasonal title prefix [pumpkin]/[W2], 07d Platform Levers 2026, Automatic translation (Use Translated Content), Events & Updates announcements, Late 2026 free pass trials / Home pass showcase, Missed settings checklist, OpenCloud personal notifications (+3 more)

### Community 78 - "Robux ID setter"
Cohesion: 0.33
Nodes (4): apply_ids(), block(), read_products(), write_template()

### Community 79 - "ServerEvents.luau"
Cohesion: 0.42
Nodes (7): applyPowerHour(), ServerEvents.currentState(), ServerEvents.devToggle(), ServerEvents.init(), ServerEvents.powerHourState(), ServerEvents.seasonActive(), serverNow()

### Community 81 - "Lua structure checker"
Cohesion: 0.36
Nodes (5): check(), check_tokens(), run(), tokenize(), read_interp()

### Community 82 - "GiftState.luau"
Cohesion: 0.28
Nodes (3): GiftState.elapsed(), GiftState.nextRemaining(), GiftState.ready()

### Community 83 - "Lobby plan SVG"
Cohesion: 0.54
Nodes (6): arrow(), circle(), px(), pz(), rect(), text()

### Community 85 - "OverheadTags.luau"
Cohesion: 0.38
Nodes (4): attach(), OverheadTags.init(), styledLabel(), track()

### Community 86 - "GroupReward.luau"
Cohesion: 0.40
Nodes (4): B4 Group reward (dropped), Climb For Animals Eggs, check(), GroupReward.init()

### Community 88 - "script_parent_playerstats"
Cohesion: 0.25
Nodes (4): areFriends(), pairKey(), Purchases.init(), add()

### Community 90 - "EggRules.luau"
Cohesion: 0.33
Nodes (7): cycleMulti(), EggShop.checkPasses(), EggRules.autoPass(), EggRules.owns(), EggRules.pass(), EggRules.passForCount(), EggRules.step()

### Community 92 - "WheelPanel.luau"
Cohesion: 0.28
Nodes (6): WheelController.init(), buildFace(), create(), makeText(), panel.open(), panel.place()

### Community 94 - "Top games trends"
Cohesion: 0.33
Nodes (5): 01 Top Games Trend Report, Format cloning speed (Steal An Egg clones), +1 / for Eggs genre cluster, Short average session length (8-19 min), The Hollow platform Halloween event

### Community 95 - "AuraService.luau"
Cohesion: 0.53
Nodes (4): apply(), build(), clear(), watch()

### Community 97 - "Layout.world"
Cohesion: 0.28
Nodes (8): EggShop.init(), Shelf.backWallFrame(), World2Lobby.bounds(), World2Lobby.init(), onEnter(), WorldsGate.init(), Layout.forPlayer(), Layout.world()

### Community 98 - "Leaderboards.luau"
Cohesion: 0.39
Nodes (6): boardValue(), buildBoard(), iconLabel(), Leaderboards.init(), pillar(), textLabel()

### Community 104 - "Referrals.luau"
Cohesion: 0.47
Nodes (8): addPending(), key(), Referrals.addPlaytime(), Referrals.claimForInviter(), Referrals.init(), Referrals.onLoaded(), Referrals.payOut(), takePending()

### Community 106 - "LabelScaler.register"
Cohesion: 0.33
Nodes (3): LabelScaler.register(), LabelScaler.start(), titleColor()

### Community 108 - "StarterOffer.luau"
Cohesion: 0.48
Nodes (5): create(), findProduct(), outlined(), StarterOffer.init(), findNamed()

### Community 109 - "Hub.luau"
Cohesion: 0.43
Nodes (4): addLabel(), buildStageSigns(), buildWorldSigns(), newGui()

### Community 110 - "typecheck.py"
Cohesion: 0.48
Nodes (5): ensure_types(), luau_lsp(), run(), selene(), tool()

### Community 112 - "Reveal.luau"
Cohesion: 0.40
Nodes (3): Egg pet-chance panel prompt, drawEgg(), makeEggVisual()

### Community 113 - "AreaPasses.luau"
Cohesion: 0.53
Nodes (4): AreaPasses.init(), attributeName(), paidAreas(), publish()

### Community 114 - "WorldsGate.luau"
Cohesion: 0.67
Nodes (5): Build.block(), glowPart(), place(), stone(), textPlate()

### Community 115 - "WorldsGateClient.luau"
Cohesion: 0.80
Nodes (4): refreshAll(), refreshGate(), unlockedSet(), WorldsGateClient.init()

### Community 116 - "shoetrailtest.luau"
Cohesion: 0.60
Nodes (3): child(), makeCharacter(), setup()

### Community 117 - "FeedHud.luau"
Cohesion: 0.83
Nodes (3): accent(), create(), FeedHud.init()

## Ambiguous Edges - Review These
- `Evolution 'Form-Up' moment` → `Game theory reading (reinforcement schedules, SDT, Bartle, Hooked)`  [AMBIGUOUS]
  OYUN_TASARIM_ANALIZI.md · relation: conceptually_related_to
- `Run check.py and mocktest after edits` → `Server authoritative economy`  [AMBIGUOUS]
  CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **47 isolated node(s):** `cmd.exe`, `Creator Rewards`, `D1/D7/D30 benchmarks (GameAnalytics 2026)`, `Roblox Subscriptions`, `Claude Memory Copy README` (+42 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 426 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **25 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Blender Models Then Robux Last (memory)` connect `Blender Models Then Robux Last (memory)` to `coaches.py`, `TrainingArea.luau`, `Moves.luau`, `Blender potion models`, `Claude Memory Index`, `Cover image rendering`, `UIStyle.luau`, `Daily wheel and project status`, `README handover`, `Integer multipliers and catalog`, `Blender egg models`, `EventDecor.luau`, `muscles.py`, `pets.py`, `pets_more.py`?**
  _High betweenness centrality (0.237) - this node is a cross-community bridge._
- **What connects `cmd.exe`, `Creator Rewards`, `D1/D7/D30 benchmarks (GameAnalytics 2026)` to the rest of the system?**
  _47 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Module wiring (init scripts)` be split into smaller, more focused modules?**
  _Cohesion score 0.05550416281221091 - nodes in this community are weakly interconnected._
- **Why does `CLAUDE.md project instructions` connect `Project rules (CLAUDE.md)` to `DevTools.luau`, `Character appearance and shoes`, `Sound and music`, `Moves.luau`, `Guide tour and objectives`, `Claude Memory Index`, `Daily wheel and project status`, `Integer multipliers and catalog`, `UI redesign research (archived)`, `shared_waitforchild`, `Progression.luau`, `Design analysis (OYUN_TASARIM_ANALIZI)`, `TrainingArea.luau`, `Panel manager`, `Analytics, friends and referrals`, `Robux passes and IDs`, `Growth plan and HEP gate`, `Loading screen`, `Monetization features`, `Cosmetics and Pet Index panels`, `client/EggShop.luau`, `Settings`, `Offline earnings panel`, `Right HUD circles`, `Price cuts and trails`, `GiftState.luau`, `README handover`, `OverheadTags.luau`, `GroupReward.luau`, `Layout.luau`, `LabelScaler.register`, `Bright ambient lighting, no bloom`?**
  _High betweenness centrality (0.155) - this node is a cross-community bridge._
- **Should `Sound and music` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._

### Low-confidence Hints
_AMBIGUOUS edges — the extractor was unsure. Verify before acting on these._

- **What is the exact relationship between `Evolution 'Form-Up' moment` and `Game theory reading (reinforcement schedules, SDT, Bartle, Hooked)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Run check.py and mocktest after edits` and `Server authoritative economy`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._