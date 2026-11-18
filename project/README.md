# Orb Loop Prototype

Gameplay loop only. Every piece of art is a placeholder drawn with Godot code; there are no image files.
Built for Godot **4.7.2**, GDScript, Compatibility renderer, portrait 1080×1920, stretch mode `canvas_items` with aspect `expand`.

## Godot version used

Godot **4.7.2.stable.official.ed1daf0bf**, Standard build, Windows 64-bit. The download was SHA512-checked against the official release file.

Install folder:

```
C:\Users\User\AppData\Local\Programs\Godot\4.7.2\
    Godot_v4.7.2-stable_win64.exe          <- the editor (double-click this)
    Godot_v4.7.2-stable_win64_console.exe  <- same, but also shows a log window
```

## How to run it

1. Double-click `Godot_v4.7.2-stable_win64.exe` in the folder above.
2. In the Project Manager, click **Import**, choose `orb-loop-prototype\project.godot`, then click **Import & Edit**. If the project is already in the list, just double-click it.
3. Press **F5**, or the ▶ button at the top right.

**What you should see first:** a 540×960 window (a half-size phone) with the **title screen**:
- Your title art, with **ORBSPIRE** in glowing cyan and gold that glitches every few seconds.
- The three story hunters (your art) bobbing on the terrace, and your orbs drifting up.
- A big **TAP TO START** button, with **NEW GAME** and **SETTINGS** underneath.

**The first time** you tap, the **Introduction** appears (tap to continue), then the Act 1 intro (2 lines, 10 s, skippable), then fight 1. **After that**, the big button says **CONTINUE** and puts you straight back at the fight you reached. NEW GAME asks "Are you sure? This wipes your save" first. The save is a tiny file, `user://save.json`; the full save system is Phase 8.

In a fight you'll see "ACT 1 · TEAM Lv1" in the top-left corner and "1/8 · EMBER DRONES" over the furnace arena. Under the title: the target's name, element and weakness, and "2 enemies · each attacks after your turn · tap one to target it".
- The story trio in glowing cards: **Fire Berserker** (greatsword, LEADER tag), **Water Biotech** (staff) and **Wood Titan** (tower shield). Each card has a round skill badge in its top-right corner showing turns until the skill is ready.
- A green HP bar with a heart reading **1060 / 1060**, and a dim timer bar reading "DRAG AN ORB · 5 s starts on pickup".
- A 6×5 board with **6 orb types**: fire (flame), water (droplet), wood (leaf), light (star), dark (moon), heart. No ready-made matches.

Your mouse works as a finger: click, hold and drag. **Click an enemy** to target it. **Click a hunter's card** to see its skills and use its active skill.

You play **Act 1 (Orbspire, Furnace District)**: 8 fights in a row. Win to get **Next Fight**. After the boss you see **ACT 1 CLEAR!**.

## Story (light, skippable)

The authority is **the Progenitors**, everywhere. The automated story test checks that the old faction name never appears in any data or script file.

| Where | Text | When |
|---|---|---|
| `data/story/story.tres` | The **Introduction**, word for word, and the 5 **Timeline** entries | Introduction once, after the first TAP TO START; Timeline in the codex |
| `data/acts/act_01.tres` | Act 1 intro (2 lines), boss taunt, outro, colony intel (3 lines, for the star map), Emberfang-9's codex entry | Intro before fight 1 (10 s), taunt when the boss fight starts (5 s), outro after the boss falls (10 s) |

- **Skipping:** every beat can be skipped by tapping or pressing SKIP. The board is locked while a beat is showing.
- **Codex:** after the boss you see **ACT 1 CLEAR!** with a **CODEX UNLOCKED: EMBERFANG-9** button. The codex has two pages:
  - **Singularity:** what it was spliced from, what it wanted and what it cost, with the boss art.
  - **Timeline.**
- **Act 2:** no story for Act 2 or later yet.

## Star map (home screen)

CONTINUE opens the star map, your Act select screen:
- **Background:** `bg_star_map.png`, cropped to fill the phone, never squashed.
- **Nodes:** your image has no planets, so the 10 nodes are drawn in code. Each is a planet dot with a thin ring in its element colour, and The Core's is the largest.
- **Node positions:** in `scripts/ui/star_map.gd`, `NODE_PCT`, as **percent of the area between the top bar and the bottom nav**. They're your starting positions, squeezed into that area so no node hides under a bar.
- **States:**
  - **Completed:** gold check mark, tap to replay.
  - **Current:** pulsing ring.
  - **Locked:** grey label and padlock; tapping says "Finish Act X to unlock".
  - An Act unlocks when the Act before it is cleared.
- **Route:** a dotted line, drawn only up to the current Act.
- **Tapping an Act:** opens 3 lines of colony intel, a PLAY button, and a greyed-out "Side Rift · coming soon" slot. Acts 2–10 say "COMING NEXT" until they're built.
- **Top bar:** Credits, Training Cores, level and Settings (placeholders until the characters stage).
- **Bottom nav:** Play, Team, Roster, Recruit and Quests. Play is this screen; the others say they're coming.
- **Test state** (Act 1 completed, Act 2 unlocked): run the game with `-- --map-test-state` at the end of the command.

## Characters, levels and drops

**Every number on this page** (prices, chances, rates, rarity stats) is in `data/economy.tres`, which you can edit in the Inspector. Level XP and stat growth are in `data/progression.tres`.

- **Characters:** all 20 PNGs are collectable, 5 per type and one per element.
  - Each has a **name** and a **title**, from your roster list (proposals, not locked), e.g. **KAELA RYNN · Fire Berserker** and **VEX MARLOWE · Dark Spectre**.
  - To change one, edit `display_name` / `title` in its `.tres` file.
  - The story team: Kaela Rynn (Fire Berserker), Mira Solace (Water Biotech), Bram Stone (Wood Titan), then Vex Marlowe (Dark Spectre) from Act 2.
  - Each one uses its type's approved stats and skill set.
  - The 4 story characters stay in `data/team/` and the other 16 are in `data/characters/`.
- **You start with** the story trio, Forged rarity, Lv1. **The Dark Spectre joins** the first time you play Act 2.
- **Real levels:** every character has its own level and XP, up to Lv30.
  - A WIN gives full XP to everyone in the team.
  - Catch-up XP: ×1.5 for characters 3–5 levels below your highest, ×2 for 6+ below.
  - **Passive 1 unlocks at Lv10.** Passives 2 and 3 need evolution, which needs your stage 2 and 3 art, so it isn't built yet.
  - The "Lv preview" is gone from real play; only the automated battle tests still use it.
- **Rarity:** Scrap, Alloy, Forged, Prime, Ascendant, Singularity give stats ×0.85, 0.92, 1.0, 1.08, 1.16, 1.25. The card border shows the rarity colour.
- **Credits:**
  - A WIN pays 20 + 10 × the Act number, ×2 for a mini-boss and ×4 for a boss. A LOSE pays 25% of that.
  - Your first clear of an Act adds 300 × the Act number, plus **1 Key**.
- **Digital Essence:** every enemy drops Essence for one specific character, of the same element, with a type that fits the enemy (for example Furnace Worker → Fire Titan).
  - Regular enemies drop 1 with a 15% chance, mini-bosses always drop 1–2, and bosses always drop 3.
  - **10 Essence = CRAFT** that character in the **Lab** (Roster → LAB) at Lv1.
- **Recruit:** costs Credits; any of the 20 characters can appear, so the type and affinity are random. Odds by rarity (the screen shows these too):

  | Tier | Cost | Scrap | Alloy | Forged | Prime | Ascendant | Singularity |
  |---|---|---|---|---|---|---|---|
  | Basic | 300 | 50% | 35% | 12% | 3% | – | – |
  | Advanced | 1,000 | 15% | 35% | 30% | 15% | 4% | 1% |
  | Elite | 3,000 | – | 10% | 35% | 35% | 15% | 5% |
  | Key | 1 Key | – | – | – | – | 80% | 20% |

  Duplicates are allowed.
- **Roster:** holds up to 30 characters; EXPAND adds 5 slots for 1,000 Credits. When it's full you must expand or retire before you can recruit or craft.
- **Training Cores:** 50 Credits each, and each gives +100 XP (character detail → USE CORE).
- **Retire** (in a character's detail):
  - It asks twice, and gives back a base by rarity (2 / 5 / 15 / 30 / 60 / 150 Cores) plus 50% of the Cores used on that character.
  - You can't retire a locked character, a team member, or your only character of an element or type.
- **Team** (nav → TEAM): 4 slots, and slot 1 leads. Act 1 uses slots 1–3; Acts 2–10 use all 4. Tap a slot, then a character. Picking someone already in the team swaps the two.
- **Quests** (daily and weekly Credits): not built yet. The tab says "coming soon".

## Acts 2–10

All 10 Acts are playable from the star map. Each one unlocks when you beat the boss of the Act before it, and each uses its own arena art and boss art.

**Every Act has the same 8-fight shape as Act 1:**
1. 2 small enemies of the Act's element.
2. 3 enemies of the Act's element.
3. **Mini-boss** (armoured).
4. 3 enemies of another element.
5. 2 Light (or Dark) enemies.
6. 2 Dark (or Light) enemies.
7. **Mini-boss** (armoured).
8. **Boss** (armoured; your boss art).

| Act | Colony | Element | Boss | Team level |
|---|---|---|---|---|
| 2 | Drowned Metro | Water | Tidecoil-7 | Lv10 → 12 |
| 3 | Greenhouse Ruins | Wood | Thornwood Unit | Lv12 → 14 |
| 4 | Upper Spires | Light | Dawnwing | Lv14 → 16 |
| 5 | Void Quarter | Dark | Voidscale | Lv16 → 18 |
| 6 | Solar Farms | Fire | Ashen-01 | Lv18 → 20 |
| 7 | Data Abyss | Water | Kraken Mainframe | Lv20 → 22 |
| 8 | Gene Labs | Wood | Mossback Chimera | Lv22 → 24 |
| 9 | Core Sanctum | Light | Seraph Enforcer | Lv24 → 27 |
| 10 | The Core | Dark | Reaper-0 | Lv27 → 30 |

- **The Dark Spectre joins from Act 2,** so you fight as a team of 4. A one-time "NEW HUNTER" notice says so.
- **Generated, not hand-written:** the enemies, stats and XP for Acts 2–10 come from `tools/generate_acts.gd`. Its enemy line-up per Act is in `PLAN` at the top of the script.
- **Tuned by the balance simulation** to the same targets as Act 1:
  - Good play wins regular fights in 2–3 turns, mini-bosses in 5, and the boss in 6 (each Act's longest fight).
  - Doing nothing loses in 8–12 turns.
  - Average play survives every fight.
  - Mini-bosses and bosses survive one perfect 6-combo turn.
- **Results:** every fight's numbers are in `tools/act_generation_report.txt`.
- **To rebalance or change the line-up:** edit the script and rerun it with `--headless --path . -s res://tools/generate_acts.gd`. It never touches Act 1.
- **No story beats or codex text yet for Acts 2–10;** your lite storyline file wasn't found. Beating their bosses still adds them to the codex, with their art and a "coming with its Act's story" note.
- **Gimmick:** every Act still uses the Shield (armour) gimmick on its mini-bosses and boss, and DEF is 0 everywhere.

## Your art

The art comes from `Downloads\orbspire-art-organized\`. It was copied into `assets/` and resized: characters and enemies to 512 px, the boss to 768 px, orbs to 256 px, backgrounds to 1024 px. Your originals are unchanged.

| Used for | File |
|---|---|
| Title background | `Title_Screen.png` → `assets/backgrounds/bg_title_orbspire.png` |
| Story hunters | berserker_01_angel_fire, biotech_01_medic_water, titan_01_shield_wood, spectre_01_rogue_dark |
| Act 1 enemies | ember_drone, coolant_slime, furnace_worker, spore_sprout, solar_drone, shadow_thief, forge_brute. **Every enemy is named after its PNG,** except the 20 Light/Dark enemies, which use the proper names from your list with the PNG name as their title (e.g. **HELIOS** · Solar Drone, **SHADE** · Shadow Thief). All 50 enemy PNGs (10 per element) are in `assets/enemies/` |
| Boss | boss_01_emberfang9_plasma_wolf |
| Orbs | all 6: orb_fire, water, wood, light, dark, and RCV_Orb.png as the Heart orb |
| Act 1 arena | bg_act01_furnace_arena (cropped to fit, never stretched) |
| Star map | `Star_Map.png` → `assets/backgrounds/bg_star_map.png` |

- **To change a fighter's art:** set **Art** on its `.tres` file in the Inspector.

## Act 1: the 8 fights

| # | Fight | Enemies | Element | HP each | ATK each | DEF | Gimmick | XP | Team level |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Ember Drones (tutorial) | 2 | Fire | 260 | 45 | 0 | – | 60 | Lv1 |
| 2 | Coolant Slimes | 3 | Water | 230 | 40 | 0 | – | 80 | Lv2 |
| 3 | **Mini-boss:** Furnace Worker | 1 | Fire | 1,500 | 160 | 0 | Armour | 180 | Lv3 |
| 4 | Spore Sprouts | 3 | Wood | 360 | 50 | 0 | – | 110 | Lv4 |
| 5 | Solar Drones | 2 | Light | 450 | 75 | 0 | – | 130 | Lv5 |
| 6 | Shadow Thieves (human scavengers) | 2 | Dark | 480 | 85 | 0 | – | 150 | Lv6 |
| 7 | **Mini-boss:** Forge Brute | 1 | Fire | 2,000 | 175 | 0 | Armour | 260 | Lv7 |
| 8 | **Boss:** Emberfang-9 (plasma wolf) | 1 | Fire | 1,200 | 180 | 0 | Armour | 380 | Lv8 |

- **Each fight starts at full HP.** Skill charge carries over from fight to fight.
- **XP:** Act 1 gives 1,350 XP in total. With the XP curve in `data/progression.tres` (Lv1→2 needs 50, +25 more for each later level), the story trio reaches Lv2, 3, 4, 5, 6, 7, 8 after fights 1–7 and **Lv10 after the boss**, which unlocks Passive 1.
- **Team level preview:**
  - Real levelling arrives in Phase 6. Until then, each fight shows the team at the level a player would normally have by then, marked "(preview)".
  - Stats grow in a straight line from ×1 at Lv1 to ×3 at Lv30, so Lv8 is ×1.48.
  - To switch the preview off, untick `preview_expected_level` in `data/progression.tres`.
- **DEF:** every orb hit loses the enemy's DEF, but always does at least 1. Skills ignore DEF. Act 1 uses DEF 0 everywhere.
- **Files:** the enemies are in `data/enemies/act1/`, and the fights (with XP and team level) in `data/fights/act1/`.
- **Placeholders:** the old test fights are still in `data/fights/test_*.tres`, but only the automated test uses them.

## Screen sizes

`window/stretch/aspect = "expand"`, so phones taller than 9:16 have **no black bars**:
- The extra height goes into the enemy corridor.
- The team row, HP bar, timer and board slide down together, so the board always sits at the bottom of the screen in thumb reach.
- Wider screens, like tablets, keep the 1080-wide layout centred.
- Nothing is stretched, so orbs stay round.

This was checked at 1080×1920, 1080×2400 and 1440×1920. Screenshots are in `tests/screenshots/`.

## Team and test fights

| Hunter (data file) | Type | HP | ATK | RCV | Active skill | Leader skill (slot 1) |
|---|---|---|---|---|---|---|
| Fire Berserker (`data/team/fire_berserker.tres`) | Berserker | 320 | 95 | 10 | Overrun, CD 7 | 4+ own-element group: that element ATK ×2 |
| Water Biotech (`water_biotech.tres`) | Biotech | 320 | 55 | 40 | Mend, CD 5 | 3+ elements matched: ATK ×1.5 + heal 10% |
| Wood Titan (`wood_titan.tres`) | Titan | 420 | 65 | 22 | Bulwark, CD 8 | Team HP ×1.3; Hearts matched: next hit −25% |
| Dark Spectre (`dark_spectre.tres`, joins in Act 2) | Spectre | 230 | 130 | 8 | Execute, CD 8 | ×1.5 at 5 combos → ×2.5 at 7+ |

Story trio total: **1,060 HP, RCV 72**. New characters start at Lv1 with **0 passives unlocked** (Lv10 / Evolution 1 / Evolution 2 unlock them in Phase 6).

| Fight (`data/fights/`) | Enemies | HP | ATK |
|---|---|---|---|
| Test Fight 1 | Test Enemy 1, Wood | 800 | 120 |
| Test Fight 2 | Test Enemy 2, Fire | 1,200 | 150 |
| Test Fight 3 | Drone A Water, Drone B Light, Drone C Dark | 500 each | 60 each |
| Test Boss Fight | Test Boss, Fire, **armoured**, boss | 1,500 | 100 |

Change any number by double-clicking the `.tres` file in Godot and editing it in the Inspector. **All skill numbers** (cooldowns, multipliers, percentages) are in `data/skills/skill_tuning.tres`.

## The rules, exactly as coded

- **Damage per hunter** = ATK × (orbs of its element cleared ÷ 3) × combo multiplier × element multiplier × leader skill × passives. Rounded once, at the end, to the nearest whole number (.5 rounds up).
- **Combo multiplier** = 1 + 0.25 × (combos − 1).
- **Element multiplier:** Fire > Wood > Water > Fire (2× / 0.5×). **Light and Dark beat each other** (2× both ways). Light/Dark vs Fire/Water/Wood is 1×.
- **Who gets hit:**
  - Tap an enemy to target it (yellow spinning ring). Tap it again to clear the target. With no target, attacks go to the front enemy (the first one still alive, left to right).
  - **Berserker** hits **every** enemy when 4+ of its orbs match in one group; with only 3 it hits the target.
  - **Spectre** always hits one. Titan and Biotech hit the target.
- **Healing** = team RCV × (Hearts cleared ÷ 3), never above max HP.
- **Every enemy still alive attacks once** after your turn, one after another.
- **Armour (Act 1's Shield gimmick):** an armoured enemy takes half damage. A 4+ orb group or any active-skill hit breaks it, and that hit already does full damage.
- **Skills:**
  - Tap a card to open its pop-up, then press **USE** when the badge says **GO**. Using a skill does **not** end your turn.
  - Cooldowns charge by 1 only on turns where you make a match.
  - Charge **carries over** to the next fight in the Act. The first fight of an Act starts **half charged** (Mend 3, Overrun 4, Bulwark 4, Execute 4). **Retry** puts the charge back to what it was when that fight began.
  - The board is locked while the pop-up is open, so its buttons can never pick up an orb by accident.
- **Swaps:** the held orb swaps with every orb it passes over, diagonals included. Clipping the edge of a side cell on the way to a diagonal waits and swaps diagonally instead.

## How to test it yourself, in order

**1) Board and drag**
- Press an orb. It grows 15% and glows, and a coloured trail follows your mouse.
- Drag across other orbs, straight and diagonally. Each one swaps into the gap behind you.
- The timer bar lights up and counts down from 5.0 s. It turns yellow at half and red in the last quarter.
- Keep holding: at 0 the move ends by itself, and moving the mouse after that does nothing.

**2) Match, gravity and combos**
- Line up 3 of a kind and let go. They pop, the orbs above fall with a bounce, and new orbs drop in from the top.
- "COMBO 1", "COMBO 2"… pop up where each group cleared. Chains from falling orbs keep counting.

**3) Damage and enemy HP** (fight 1, Ember Drones, Fire)
- **3 Water:** a **big "110!"**, because Water beats Fire (Biotech 55 × 2).
- **3 Wood:** a **small "33"**, because Fire resists Wood (Titan 65 × 0.5 = 32.5, rounded up).
- **4 Fire in one group:** the Berserker hits **both** drones, ×2 from its leader skill.

**4) Enemy attack, team HP and WIN / LOSE**
- After your turn each drone hits for **45**, so the team loses 90.
- 3 Hearts heal +72, but never above max HP.
- Win to see **WIN!** and "+60 XP". Match nothing for 12 turns to see **LOSE**.

**5) Fight Again and Next Fight**
- **Fight Again** restarts the same fight at full HP.
- **Next Fight** goes on through the Act, and your skill charge comes with you.

**6) Skills, mini-bosses and the boss**
- When a card badge says **GO**, tap the card and press **USE**:
  - **Overrun**: all Wood orbs turn to Fire.
  - **Mend**: heals 30% and makes 3 Hearts.
  - **Bulwark**: halves the next 2 enemy attacks.
- **Armour** on the Furnace Worker, Forge Brute and Emberfang-9 (the blue shield badge): 3-orb hits do half damage. A 4+ group breaks the armour ("ARMOUR BROKEN!").

## Automated play-test (optional)

`tests/loop_test.tscn` plays the real game with simulated mouse presses and drags, then checks every number above. It's a developer tool, not part of the game.

From a terminal in this folder:

```
& "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --path . res://tests/loop_test.tscn
```

The full run takes about 15 minutes, because every check plays real turns. Results go to `tests/report.txt` and screenshots to `tests/screenshots/`.

- **Run only some sections** by adding `-- --only=G,A` at the end. Sections:
  - `L` layout, `1`–`5` the original loop tests, `G` groundwork.
  - `A` active skills, `K` leader skills, `P` passives, `S` stacking numbers.
  - `B` the Act 1 balance simulation (turns to win and lose for every fight; runs in seconds).
  - `F` the 5 loop tests on each of the 8 Act 1 fights.
  - `X` the 5 loop tests on each fight of Acts 2–10, at 6× animation speed (add `--acts=2,5` to pick Acts).
- **Levels, characters, drops, Recruit, Lab, retire and Team select:** run `res://tests/meta_test.tscn` (about 1 minute, results in `tests/report_meta.txt`). It uses its own save file.
- **Title screen, Introduction, story beats and codex:** run `res://tests/story_test.tscn` instead (about 1 minute, results in `tests/report_story.txt`). It uses its own save file, never yours.
- **Check the tall-phone layout (1080×2400):** add `--resolution 432x960` before `res://…`, and `-- --layout-only` at the end.
- **After adding new script files,** run Godot once with `--headless --import` (or open the editor) so it registers the new class names.

## Testing on an Android phone (target API 36)

1. Install OpenJDK 17 and Android Studio. In Android Studio's **SDK Manager**, install **Android SDK Platform 36** and **Build-Tools 36**.
2. In Godot, go to **Editor → Editor Settings → Export → Android** and set the Java SDK path and the Android SDK path.
3. Go to **Project → Install Android Build Template**, then **Project → Export → Add… → Android**.
4. In the export preset:
   - Turn on **Gradle Build → Use Gradle Build**.
   - Set **Target SDK = 36**. Google Play requires API 36.
5. Plug in the phone with USB debugging on, then press the Android "Remote Debug" button at the top of the editor.

## Where everything is

| File | What it does |
|---|---|
| `project.godot` | Engine settings: portrait, 1080×1920, canvas_items + expand, Compatibility renderer |
| `scenes/main.tscn` + `scripts/main.gd` | **The start scene:** title → Introduction → Act 1 → back to title; the tiny save file |
| `scenes/battle.tscn` | The fight screen. `battle.gd` builds it in code. |
| `scripts/ui/title_screen.gd`, `story_beat.gd`, `codex_screen.gd`, `menu_style.gd` | Title screen, story beats / Introduction, codex, menu button look |
| `scripts/data/act_data.gd`, `story_data.gd` + `data/acts`, `data/story` | Each Act's story and art; the Introduction and Timeline |
| `scripts/battle/art_figure.gd` + `assets/` | Draws your PNG art for fighters |
| `scripts/battle/battle.gd` | **The director.** Runs each turn, targeting, active skills, skill charge between fights, and the layout for any phone size. |
| `scripts/battle/combat_rules.gd` | Who gets hit, leader skills, passives, Execute maths, healing extras |
| `scripts/skills/skills.gd` | Skill names, cooldowns and the plain-English text in the pop-up |
| `scripts/skills/skill_tuning.gd` + `data/skills/skill_tuning.tres` | **Every skill number**, editable in the Inspector |
| `scripts/board/board.gd` | Drag, move timer, swaps (including forgiving diagonals), combos, gravity, refill, orb-changing for skills |
| `scripts/board/orb.gd` | One orb: draws itself, slides, pops, flashes when a skill changes it |
| `scripts/board/match_finder.gd` | Finds lines of 3+ and groups touching ones into combos |
| `scripts/core/damage_calculator.gd` | The core damage and heal maths |
| `scripts/core/element.gd`, `element_icons.gd` | The element wheel (including Light / Dark), colours and symbols |
| `scripts/data/fighter_data.gd`, `fight_data.gd` + `data/**/*.tres` | Stats, skills and passives per character; enemies (DEF, armour, look); fights (XP, team level) |
| `scripts/data/progression_tuning.gd` + `data/progression.tres` | XP curve, stat growth per level, and the level preview switch |
| `scripts/battle/team.gd`, `enemy.gd` | Shared team HP pool and skill charge; enemy HP and armour |
| `scripts/battle/fighter_view.gd`, `placeholder_figure.gd` | Cards (skill badge, LEADER tag), target ring, shape-drawn bodies |
| `scripts/anim/fighter_animator.gd` | **The one animator** for everyone (Tween only): idle, attack, hit, defeat |
| `scripts/battle/backdrop.gd` | The corridor and team panel (grows on tall screens) |
| `scripts/ui/*.gd` | HP bars, timer bar, popup numbers, skill pop-up, WIN / LOSE screen |
| `tests/loop_test.gd` | Automated play-test (developer tool) |
