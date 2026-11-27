# N.Y.A.T (Not Your Average Tycoon) — Development Handoff

- **Version:** 0.49 (Economy Guardrails + Walk & Fish Slice Started)
- **Last Updated:** November 27, 2026
- **Target Platform:** Cross-platform 2.5D top-down pixel art (iOS/Android phones, iPad/tablets, Desktop/Steam)
- **Repo:** github.com/kinglyarab/nyat — playable web build at kinglyarab.github.io/NYAT
- **Workflow:** Claude builds in Godot 4.3 (GDScript); every push to `main` auto-exports a web build to GitHub Pages; the owner plays it on iPad.

> **Maintenance rule:** This file is the single source of truth. Update it on every change: version number, the Elevator Pitch (if features change), the Decision Log, the Build Status section and the Changelog.

---

## 0. Build Status (what actually exists in the repo right now)

**Current milestone: Walk & Fish Slice** — the first playable build. Goal: prove that walking around and fishing feel good before any tycoon systems are added.

| System | Status | Where |
|---|---|---|
| Godot project + Pages auto-deploy | Done | `project.godot`, `.github/workflows/web.yml`, `export_presets.cfg` |
| Adaptive input (touch / keyboard / controller, last device wins) | Done | `scripts/input_manager.gd`, `scripts/touch_controls.gd` |
| Sanctuary room (starter room, warm lighting, y-sort) | Done (placeholder art) | `scenes/sanctuary.tscn`, `scripts/sanctuary.gd` |
| Avatar (4-way, walk, proportionate) | Done (placeholder art, single layer) | `scripts/player.gd` |
| Pond portal → Tier 1 pond (Sunlit Park Pond) | Done | `scripts/pond.gd` |
| 3-pulse fishing with big pulsing button | Done | `scripts/fishing.gd` |
| Collection Log (per-pond tab, T1 only) | Done | `scripts/collection_log_ui.gd` |
| Tackle Bag (temporary catch storage) | Done (basic) | `scripts/game_state.gd` |
| Save / load (versioned JSON) | Done | `scripts/save_system.gd` |
| Data-driven fish table | Done | `data/fishing_drops.json` |
| Stations, gardens, archetypes, prestige, trading, gacha, audio | Not started | — |

**Art status:** all art in the slice is procedurally drawn placeholder pixel art (generated at runtime in `scripts/pixel_art.gd`) so the build has no external asset dependencies. It will be replaced with real sprite sheets.

**Controls in the slice:**
- Touch: left thumb = floating joystick; right side = big **ACTION** button (interact / cast / reel) and **LOG** button.
- Keyboard: Arrows or WASD move; **Space** (or Enter/E) = action; **L** (or Tab) = Collection Log; **Esc** = close.
- Controller: Left stick / D-pad move; **A** = action; **Y** = Collection Log; **B** = close.

---

## Elevator Pitch & Quick Summary (Living Overview)

**10-second pitch:** A cozy, high-detail 2.5D top-down pixel-art tycoon with warm dynamic lighting, set in a Habbo Hotel-style creative sandbox. Players choose an establishment **Tycoon Archetype** (Cozy Storefront/Cafe, Nightclub/Arcade Lounge, Cosmic Casino & Resort, Chaos Management Agency, or Botanical Conservatory), run grounded tycoon stations (Coins), build with hundreds of decor pieces and interactive playable furniture (arcade cabinets, slots, roulette, table games, multi-seat Connect 4, Billiards, 4+ player Mini Poker using Coins/table chips — never Crowns — and the 2nd-rarest-tier **Cosmic Fishing Rift** for private sanctuary fishing). They earn Visitor Hype and "house" Coins from guests playing in their Casino, buy exotic seeds from visiting cosmic traders to tend tiered-growth botanical gardens (up to 1-week Exotics and 1-month Mythics), grind RNG **Cosmic Fishing** across tier-scaled rotating themes (T1 weekly up to 1-in-500, T2 biweekly up to 1-in-5,000, T3 monthly up to 1-in-50,000, Cosmic pulls 1-in-100,000 with global announcements; tiers unlocked by Collection Log entries, thresholds TBD), open or trade Mystery Chests / Cosmic Giftboxes, spin Gacha Machines (Crowns Gacha + two rotating Premium Capsules at $1 and $2; the #1 Cosmic tier is never buyable), mix-and-match 5 cosmetic slots, and trade with friends live in the Social Nexus or via an automated Trade Plaza Booth Plot — with no fake idle-game octillion-dollar inflation, and an economy built to keep trading feeling valuable.

**Vibe mashup:** The room-building sandbox, playable furniture and social lounge of Habbo Hotel + the Collection Log dopamine and RNG hunting of Old School RuneScape + the hangout plazas, flex chairs and outfits of MapleStory, wrapped around a cozy 2.5D top-down pixel-art sanctuary with warm dynamic lighting.

### Core Pillars at a Glance
- **Choose your archetype & build your sanctuary:** pick an archetype in a Habbo-style sandbox with hundreds of decor items and playable furniture (Coins or non-tradeable table chips only — never Crowns). Earn grounded "house edge" Coins (rates TBD), Visitor Hype, walk your avatar around the estate running stations, toggling Overdrive, doing 1-tap fixes, arranging synergies, tending gardens, displaying trophies, prestiging ("Pivot & Rebrand") while keeping all decor and grown plants, hosting visitors, and reading the "Sanctuary Gazette" login recap.
- **Unlock pond tiers via Collection Log & fish rotating themes:** see Section 2.
- **The three-way drop choice:** every rare drop stamps the Collection Log permanently; then sell for Coins, display for prestige, or trade (including sealed Mystery Chests / Cosmic Giftboxes for Crowns).
- **Flex & trade in the Plaza:** Coins can't buy the player market. Players trade catches, seeds, grown plants, furniture, pets, sit chairs, outfit pieces, premium capsule items and unbuyable Cosmic pulls for Crowns — live (items + Crowns, 3-second anti-scam countdown) or through automated booth plots.

---

## 1. High-Level Concept & Hook
- **5-slot modular cosmetics & F2P gacha economy:** Head, Torso, Legs, Feet, Back. Monetization through tradeable cosmetic Gacha Capsules that feed the Trade Plaza.
- **Walkable avatar tycoon:** the player controls a physical avatar walking around their space (virtual joystick / tap-to-move on mobile), managing automated stations while gathering, decorating and showcasing rares.
- **Habbo-style creative sandbox & selectable archetypes:** 5 archetypes, switchable on prestige; big furniture catalog, wall/floor customization, playable furniture so visitors actually hang out.

## 2. Core Gameplay Loop & Mechanics

### Day-to-day loop
0. **Onboarding (first 5 minutes):** body type (Male/Female), skin, hair colour/style, 1 of 5 starter outfits; pick 1 of 5 archetypes (rebrand possible on prestige); starter room with 1 station, 1 garden plot, free Rickety Wooden Chair; 30-second Tier 1 fishing tutorial.
1. **Estate & station management:** collect Coins, toggle Overdrive, 1-tap fixes, grid synergies, pop-up dilemmas, property upgrades, Sanctuary Gazette.
2. **Sanctuary curation:** buy exotic seeds from visiting traders, tend/cross-breed plots, keep grown plants as decor or trade them.
3. **Social Nexus & gathering runs:** portals to Clog-unlocked fishing ponds, visit friends, sit in flex chairs, spin gacha.
4. **Trade Plaza & salvage:** salvage unwanted drops for Crowns at the Salvage NPC (daily-capped), or trade/barter in the Plaza.

### Portals & tier-scaled pond themes
- **Social Nexus:** shared public plaza with the Trade Plaza, Fishing Pond Portals and Seasonal Event Portals.
- **Clog gating:** higher tiers unlock at Collection Log entry milestones (thresholds TBD). Keeps the player base concentrated in 3 core hubs. Themes rotate on staggered schedules within each tier's visual bracket; per-pond logs are permanent, so no permanent FOMO.
- **Tier 1 (Basic fish, ceiling 1-in-500, weekly):** from the start. Simple grounded themes — Sunlit Park Pond, Neighborhood Fishing Pier, Quiet Forest Stream.
- **Tier 2 (Basic + Exotic, ceiling 1-in-5,000, biweekly):** Clog milestone. Stylized themes — Crystal Grotto, Lantern-Lit Midnight Canal, Sunken Rooftop Pool.
- **Tier 3 (Basic, Exotic, Legendary, Cosmic; ceiling 1-in-50,000, Cosmic 1-in-100,000; monthly):** higher Clog milestone. Spectacle themes — Celestial Cloud Sea, floating island over a nebula pond, Volcanic Caldera Rim with themed fish variants.
- **Broadcasts:** Cosmic pulls trigger a global announcement (player name, pull name, odds). Rare/Exotic/Legendary pulls can show instance notifications in shared hubs.
- **Anti-boredom:** surge days (Solar Flare Surge, Astral Eclipse, Meteor Shower) and "Cosmic Frenzy" hotspots.
- **Seasonal 4th portal:** holidays (Halloween, Winter, Lunar New Year…) with event fishing, a holiday seed trader, temporary event currency (Spooky Candy, Frostflakes) for tradeable items, and recurring event logs.

### Cosmic Fishing mechanic
- **Design goal:** relaxed, chat-friendly grinding; a missed timing check never loses a rare.
- **Primary control — the big pulsing button:** when fishing, a large on-screen button is the main input. On a bite it pulses through 3 steady beats at a randomized tempo (slow / medium / fast) with ring and colour indicators; tap on each beat. Spacebar / click / controller A do the same on desktop and controller. Missing a beat just restarts the 3-pulse sequence on the same hooked fish.
- **Haptics are a bonus layer, not required:** synced vibration on native mobile builds for eyes-free play. The game must be fully playable from visuals + audio alone (Safari web builds have no vibration).
- **Auto-Fish:** slower AFK mode with a daily time budget (TBD) that resets daily on server time.

### Three-way drop dilemma, storage & collectibles
- **Permanent Clog stamp** on acquisition of any rare catch, mutated plant or artifact.
- **Sell vs. display vs. trade:** sell for Coins, display for prestige/foot traffic, or trade / salvage for Crowns.
- **Storage split:** unlimited Main Storage Vault (cosmetics, chairs, pets, furniture, seeds, display specimens) + Temporary Catch Storage (Tackle Bag/Cooler, Coins-upgradeable, capacity TBD) for fresh catches during runs.
- **Tradeable container catches:** Mystery Sunken Chests / Cosmic Giftboxes — open for pond-specific furniture/cosmetic rolls, or trade sealed.
- **Botanical gardens:** expand plots via Coins; rotating trader seeds from fast starters to 7-day Exotics and 28–30-day Mythics; daily tending (water, weed, clear spores) shaves flat time (TBD) and never kills neglected plants. Seeds and grown plants are tradeable.
- **5-slot cosmetics, pets & flex chairs:** proportionate 2.5D sprites (no chibi), optional light thematic buffs (TBD), Rare+ follower pets with VFX (e.g. Baby Cerberus fire footprints), MapleStory-style "Sit" anywhere.

### Sanctuary chaos, prestige & offline recap
- **Station chaos:** offline-safe (pauses offline and in the Nexus), no destruction or theft. Chill Mode (100% baseline, no upkeep) vs. Overdrive (bonus % and chaos cadence TBD); walk-up 1-tap fixes give bonus Coins + "Smooth Sailing"; adjacency synergies + patrolling Quirk-Technician NPCs.
- **Dynamic events & special visitors:** temporary boosts and Hype surges; never inject Crowns.
- **Prestige ("Pivot & Rebrand"):** resets stations, garden plot slots/levels and unspent Coins; grants permanent Meta-Perks; keep or change archetype. Preserves decor, furniture, trophies, grown plants, seeds, Crowns, cosmetics, chairs, pets and Clogs. Hard-blocks if unharvested grown plants remain; warns if seeds are mid-growth.
- **Sanctuary Gazette:** login recap of offline Coins with quirky headlines, friend co-op maintenance & outfit buffs, garden readiness, booth sales and trader alerts.

### Interactive furniture, social visiting & trading
- **Playable furniture, Coins-only stakes:** arcade cabinets (local high scores), slots, roulette, Chess (match-history plaque), Connect 4, Billiards, 4+ player Mini Poker. Coins or non-tradeable chips only. Casino owners earn house-edge Coins; hosts gain Room Hype (caps/edge TBD).
- **Cosmic Fishing Rift:** placeable portal; host and visitors fish privately, each from their own highest unlocked tier's active theme, plus 4 Rift-exclusive Clog catches (TBD).
- **Quick-inspect, Navigator & co-op:** tap an avatar to Add Friend / Visit (privacy: Open-to-Strangers vs. Friends-Only) / Invite to Trade. Navigator tabs: Featured/Top Hype, Cosmic Rift Open, Arcade & Casino Lounges, Friends & Mutuals; custom room titles + up to 2 tags. Strangers are view-only but can play furniture and use a Rift; mutual friends can water plants, do 1-tap fixes and share outfit buffs.
- **Live trade window & booth plots:** dual-pane (items + Crowns), dual Ready lock-in that resets on any change, 3-second countdown before Accept. Booth plots post automated Crowns / barter / WTB offers with the avatar seated in their flex chair.

## 3. Game Rules & Economy Design

**Guiding principle (owner priority):** a *healthy-feeling* economy comes first, because it is what makes social trading satisfying. Rare items should keep their value; Crowns should feel earned. Every economy change is judged against this.

- **Grounded, non-exponential economy:** no billions/trillions. Exact yields, costs, payouts and stake ranges are TBD for a balance pass. Coins are non-tradeable and can never buy into the trade economy.
- **Active-play rewards:** modest passive baseline + RNG windfalls from active play. Clog progression unlocks higher tiers.
- **Currency split:**
  - **Coins:** non-tradeable tycoon currency (stations, gardens, Coins-only games).
  - **Crowns:** the player-trade currency.
    - **Single faucet:** Crowns are created *only* by the Salvage NPC. They can never be bought with real money and never come from events, visitors or stations.
    - **Indirect real money is fine:** a player may buy a premium capsule and sell the item for Crowns; this moves existing Crowns, it never creates new ones.
    - **Salvage pays well below market value** so trading with players is always the better deal.
    - **Daily salvage limit** (amount TBD, resets on server time): stops bot/Auto-Fish farming of the only faucet and rewards daily check-ins.
  - **Crown sinks (remove Crowns from the game to prevent long-term price inflation):**
    - **2% trade tax** on Crowns in completed trades (tunable).
    - **Crowns Gacha** spins.
    - **Booth Plot rental fee** in Crowns (proposed; tunable).
- **Real-money monetization integrity:** IAP never sells Coins or Crowns and never boosts Cosmic odds (Cosmic tier is gameplay-RNG-only, equal odds). Two pure-RNG Premium Capsules ($1 weekly rotation, $2 biweekly; 5 sets × 5 slots = 25 items each; no pity / duplicate knockout) plus optional Booth Plot convenience. Manual trading stays free.
- **Anti-RMT (planned):** trade restrictions on brand-new accounts (exact rules TBD).
- **Non-linear upgrades:** every 5th/10th station upgrade changes behaviour/synergies. Offline Chill Mode cap (hours TBD).
- **Server time:** every timed system (pond rotations, plant growth, daily Auto-Fish budget, daily salvage limit, capsule rotations) runs on server UTC time in the live game. Phase 1 single-player uses the device clock as a stand-in behind one time function (`GameState.now_unix()`) so swapping in server time is a one-place change.
- **Legal check before Phase 3:** paid capsules and casino-style furniture affect store age ratings and are restricted in some regions (e.g. Belgium treats paid loot boxes as gambling). Review before live monetization.

## 4. Technical Guidelines, Repository Layout & Roadmap

- **Engine:** Godot 4.3, GDScript, GL Compatibility renderer (required for web).
- **Tiles:** **32×32** (decided). Nearest-neighbour filtering, pixel snapping on.
- **Projection:** 2.5D top-down three-quarter oblique, `y_sort_enabled`.
- **Avatar:** proportionate (not chibi), roughly 1 tile wide × 1.5–2 tiles tall, so 5 cosmetic layers + chairs read clearly.
- **Lighting:** dark-ish CanvasModulate + warm PointLight2D pools (lamps), cooler glows for cosmic accents.
- **Audio:** cozy lo-fi / ambient synth & Rhodes loops, retro SFX, escalating rarity jingles (not in slice yet).
- **Data:** JSON configs in `data/`. Central state autoload (`GameState`) with UTC timestamps, ready for server-authoritative sync (Supabase/Firebase) in Phases 2–3.
- **Web build:** single-threaded export (`variant/thread_support=false`) so it runs on GitHub Pages without special headers.
- **Reference images:** store in `docs/references/` (e.g. `docs/references/t3_celestial_cloud_sea.png`).

### Repository layout
```
project.godot, export_presets.cfg, icon.svg
.github/workflows/web.yml     # push to main -> web export -> GitHub Pages
data/fishing_drops.json        # fish tables, tiers, odds
scenes/main.tscn               # root: switches between sanctuary and pond
scripts/
  game_state.gd    (autoload GameState)  coins, crowns, tackle bag, collection log, time
  save_system.gd   (autoload SaveSystem) versioned JSON save
  input_manager.gd (autoload InputMgr)   adaptive input, InputMap setup
  pixel_art.gd     (autoload PixelArt)   placeholder pixel art generated at runtime
  main.gd           scene switching + HUD
  world_base.gd     shared room logic (tiles, walls, interactables)
  sanctuary.gd      starter room
  pond.gd           Tier 1 pond
  player.gd         avatar movement + facing
  fishing.gd        cast / bite / 3-pulse / catch flow
  touch_controls.gd joystick + ACTION + LOG buttons
  hud.gd            Coins/Crowns, prompts, toasts
  fishing_ui.gd     big pulsing fishing button + catch card
  collection_log_ui.gd
  ui_draw.gd        shared pixel-style panel/text/icon drawing
tools/              dev-only, excluded from export
  flow_test.tscn    headless test: cast, miss a beat, hit 3, catch, save/load
  shot.tscn         drives the slice and saves screenshots (needs a display / xvfb)
HANDOFF.md
```

### Phased roadmap
- **Phase 1 (MVP core, single-player):** tycoon stations, fishing RNG loop, Collection Log, displays/gardens, lighting, save/load.
  - 1a — **Walk & Fish Slice** (in progress): room, avatar, adaptive input, T1 pond, 3-pulse fishing, Clog, save.
  - 1b — first station + Chill/Overdrive + 1-tap fix; Coins and selling.
  - 1c — garden plot + seeds; display pedestals.
  - 1d — onboarding + archetypes; prestige.
- **Phase 2 (async social & cosmetics):** friend visiting, async trading, tiered outfits, VFX pets.
- **Phase 3 (live public zones):** multiplayer fishing / Trade Plaza, WTB/WTT boards, chat, rare-pull broadcasts.

## 5. Decision Log, Contradictions & Open Questions

### Settled
- **Fishing odds:** T1 up to 1-in-500, T2 up to 1-in-5,000, T3 up to 1-in-50,000, Cosmic 1-in-100,000 with global announcement; stepping-stone drops in every tier.
- **Rotations:** T1 weekly, T2 biweekly, T3 monthly.
- **Casino/tabletop stakes:** Coins or Coins-backed chips only. Older Crowns friendly-wager idea superseded.
- **Clog-gated tiers** with theme rotation inside each tier's bracket.
- **(v0.49) Crowns faucet:** Salvage NPC only; no real-money Crowns.
- **(v0.49) Crown sinks:** 2% trade tax (tunable), Crowns Gacha, Booth Plot fee (proposed).
- **(v0.49) Daily salvage limit**, resets on server time.
- **(v0.49) Server time** for all timed systems in the live game.
- **(v0.49) Fishing input:** big pulsing on-screen button is primary; haptics optional.
- **(v0.49) Tiles:** 32×32.
- **(v0.49) Engine/deploy:** Godot 4.3, GL Compatibility, auto web export to GitHub Pages; first build is the Walk & Fish Slice rather than the whole Phase 1 prompt at once.

### Deferred / TBD
- Economy numbers (payouts, costs, market values, stake caps, offline cap, tending reductions, salvage cap amount, booth fee).
- Collection Log thresholds for T2/T3.
- The 4 Rift-exclusive catches.
- New-account trade restriction rules.

### Notes
- Version/date collision: an imported PDF was titled v0.42 / Nov 28, 2026 while v0.42–v0.47 were already used; renumbered to v0.48 dated Nov 27, 2026.

## 6. Gotchas for Developers
- **Web export must stay single-threaded** (`thread_support=false`); threaded builds need COOP/COEP headers that GitHub Pages doesn't send.
- **Touch events also arrive as emulated mouse events.** `InputMgr` ignores those so touching the screen doesn't flip the game into keyboard mode.
- **All time goes through `GameState.now_unix()`.** Never call `Time.get_unix_time_from_system()` directly in gameplay code.
- **Odds live in `data/fishing_drops.json`**, not in code. Weights are "1 in N" values; the roller converts them.
- **Placeholder art is generated in code** (`pixel_art.gd`). When real sprites arrive, replace the texture getters there; scenes don't need to change.
- **Pages setting:** the repo's Settings → Pages → Source must be "GitHub Actions".

- **Testing locally:** `godot --headless --path . res://tools/flow_test.tscn` must print `FLOW TEST PASSED`. In tests, await `process_frame` before `Input.action_press`, or the press lands after nodes have processed and is missed.
- **Fishing timing lives in `fishing.gd`:** tempos (slow 0.95s / medium 0.72s / fast 0.55s per beat), hit window = 27% of the beat (0.15–0.22s), first beat 1.6 beats after the bite.

## 7. Changelog
- **v0.1 – v0.47 (Nov 26–27, 2026):** design evolution across prior threads and the merged PDF handoff (see sections above).
- **v0.48 (Nov 27, 2026):** marked the 4 Rift-exclusive catches TBD.
- **v0.49 (Nov 27, 2026):** moved the handoff into the repo as `HANDOFF.md`. Added economy guardrails (Salvage-only Crowns faucet, no real-money Crowns, 2% trade tax, Crowns Gacha + booth fee sinks, daily salvage limit, anti-RMT note, healthy-economy principle). Confirmed server time, 32×32 tiles, pulsing-button fishing with optional haptics. Added Build Status, repo layout, gotchas. Started the Walk & Fish Slice.

## 8. Original Phase 1 Starter Prompt (reference)
The full Phase 1 scope from the pre-Claude brainstorm, kept for reference. It is being built incrementally (see roadmap 1a–1d) rather than in one pass.

1. **Architecture & data:** `data/economy_config.json` (non-exponential scaling, TBD numbers, Coins-only stake caps), `data/archetypes.json` (5 archetypes × 3 stations + synergy rules), `data/fishing_drops.json` (tier pools, odds, Clog thresholds TBD, 4 Rift slots TBD, theme variants, container catches), `data/botanical_seeds.json` (timers up to 7-day / 30-day, care reductions TBD), and a decoupled state/action dispatcher with UTC timestamps.
2. **World, lighting & avatar:** oblique y-sorted tilemaps, CanvasModulate + PointLight2D, proportionate avatar with 4/8-way facing, 5 cosmetic layers, sit-chair and pet layers.
3. **Input & UI:** WASD/arrows + mouse on desktop; floating joystick + tap on mobile; responsive CanvasLayer HUD (Coins, Crowns, Room Hype, nav), Vault, Tackle Bag, Clog overlay, safe-area aware.
4. **Gameplay:** onboarding & archetypes; station chaos & maintenance; fishing (3-pulse, Clog milestones, rotations, Auto-Fish, Cosmic broadcast, containers); gardens; three-way drop loop; prestige with safety guards.
5. **Audio & save:** audio manager with rarity jingles; versioned JSON save with schema migrations.
