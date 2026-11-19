# Universe update (built 2026-11-19)

Master prompts: "Universe Map Final" + "Art Location + Random Colouring for Galaxies /
Solar Systems / Planets". All three parts were built in this one update, in the order
the prompt asked: (1) Universe + Galaxy 1 + Systems 1-3 + counters + combat fix,
(2) Galaxies 2-10 generator, (3) recolour + dual affinity.

Code: `scripts/meta/cosmos.gd` (generator), `scripts/meta/journey.gd` (unlocks,
counters), `scripts/meta/map_art.gd` + `assets/shaders/map_recolor*.gdshader`
(art + colours), `scripts/ui/cosmos_map.gd` (the PLAY screen). The old Act-select
star map (with its dotted line between Acts) is deleted.
Generation table + XP table: `tools/cosmos_report.txt` (`tools/cosmos_report.gd`).
Tests: `tests/universe_test.tscn`. Calibration screenshots: `tests/map_gallery.tscn`.

## Seed
`Cosmos.SEED = 20261119`. Every position, colour, name, world count and fight comes
from it, so it is the same for every player and after every restart (tested).

## Art inventory (orbspire-art-organized/World_Building)
| Folder | Original file | Project file | Size | Pixels | Transparency |
|---|---|---|---|---|---|
| Universe | gpt-image-2_5-flare_massive_universe_..._c004e9a3....jpg | assets/maps/universe_01.jpg | 0.57 MB | 1024x1024 | RGB (none) |
| Galaxies | gpt-image-2_5-flare_vast_barred_spiral_galaxy_..._8fc75eca....jpg | galaxy_a_barred_spiral.jpg | 0.52 MB | 1024x1024 | RGB |
| Galaxies | gpt-image-2_5-flare_vast_spiral_galaxy_..._341a8cb3....jpg | galaxy_b_spiral.jpg | 0.54 MB | 1024x1024 | RGB |
| Solar_System | gpt-image-2_5-flare_solar_system_background_..._0b91ea6e....jpg | system_a.jpg | 0.44 MB | 1024x1024 | RGB |
| Solar_System | ..._97d3e096....jpg | system_b.jpg | 0.49 MB | 1024x1024 | RGB |
| Solar_System | ..._f589b37f....jpg | system_c.jpg | 0.39 MB | 1024x1024 | RGB |
| Worlds | ..._desert_planet_..._6884a120....jpg | world_desert.jpg | 0.41 MB | 1024x1024 | RGB, fake checkerboard behind the planet |
| Worlds | ..._forest_planet_..._f9beb83c....jpg | world_forest.jpg | 0.58 MB | 1024x1024 | RGB, fake checkerboard |
| Worlds | ..._ice_planet_..._276fdb92....jpg | world_ice.jpg | 0.50 MB | 1024x1024 | RGB, fake checkerboard |
| Worlds | ..._ocean_planet_..._ad81bbaa....jpg | world_ocean.jpg | 0.53 MB | 1024x1024 | RGB, fake checkerboard |
| Worlds | ..._volcanic_planet_..._1d71126c....jpg | world_volcanic.jpg | 0.49 MB | 1024x1024 | RGB, fake checkerboard |

- None of the names matched the expected `bg_universe.png` / `bg_galaxy_01.png` /
  `bg_system_template_01.png` / `world_template_01_volcanic.png`: the files were
  copied under the short names above (full original names in `MapArt.SOURCES`).
- Missing: 8 of 10 galaxy pictures (2 given), 2 of 5 system templates (3 given), the
  City planet (5 of 6 given). As Bailey asked, the few given pictures are recoloured
  for everything; no placeholder art was made, nothing says "Coming Soon".
- The planets are JPGs with a checkerboard painted behind them (not real
  transparency); the shader cuts a soft circle round each planet (measured per
  picture by `tools/analyze_world_art.gd`).
- Added size: 5.46 MB of JPGs, imported as lossy WebP = 2.34 MB in the build.

## Colours (random, fixed by the seed)
Colour is random VISUAL diversity. Affinity is gameplay, shown by the orb icon and
the label. A blue planet can be a Fire world. Do NOT infer affinity from colour.
- One hue-shift shader (`map_recolor.gdshader`): hue shift 0-1, a little saturation /
  brightness variation; greys and whites have no hue, so stars stay white. Galaxy
  and system backgrounds: saturation x0.8-1.0 (light); planets x0.95-1.2 (stronger).
  The universe picture is not recoloured. Orbs, characters, enemies and bosses never
  use this shader.
- Galaxies: each galaxy node sits on one of the 10 galaxies painted in the universe
  picture, and its icon + galaxy map take that painted galaxy's colour, except Thorn
  (moved to green) and Bloom (moved to pink) so no two galaxies in a ring are within
  0.15. Galaxy 1's colour is seeded.
- Systems and worlds: one colour slot each, spread evenly round the wheel, placed by
  a search so neighbours (each node's 3 nearest) differ by 0.15+ in hue shift, the
  same planet picture is never used twice in a system with shifts within 0.15, every
  galaxy uses all hues and every system shows 3+ hues.

## Map
- Universe: the 10 painted galaxies ARE the galaxy positions (a random scatter round
  the centre, not a line or grid). Rings by distance from the centre: Ring 1 0.368-0.393,
  Ring 2 0.401-0.414, Ring 3 0.418-0.503 (picture widths). The painted galaxies are
  nearly the same distance out, so the rings are close; Bailey may want them moved
  (calibration screenshot).
- Galaxy: main system in the centre, 9 more in 3 rings (radius 0.20-0.25, 0.30-0.35,
  0.39-0.43, random angles, at least 0.2 apart). Faint ring guides drawn.
- Solar system: worlds fanned out from the star painted in the top-right of each
  system picture, nearest = lowest level; orbit circles drawn round the star.
- World: the planet (recoloured) as the header, then its stages in order.
- Pan (drag), zoom (pinch, mouse wheel, + / -), tap = preview, double-tap / OPEN = go
  in. Breadcrumb (Universe > Galaxy > System > World > Stage), BACK, GO TO CURRENT
  FIGHT, counters (Worlds X/744, Singularities X/107) on every level.
- Only the level on screen is built; going in / back frees it. Making all 744 worlds'
  layouts and colours takes 66 ms; one world's fights (tuned on the fly) about 30 ms.

## Main story (Bailey's answers, 2026-11-19)
- Each Act is one WORLD with its 8 Stage 6 fights unchanged. System 1 = Acts 1-3,
  System 2 = Acts 4-7, System 3 = Acts 8-10. Each story system gets optional side
  worlds so it has 5 worlds and all 5 affinities (System 1: Light + Dark, System 2:
  Wood, System 3: Fire + Water). Side worlds open when the system's first Act is
  cleared; their Recommended Level sits between the Acts round them.
- Story systems open in order (System 2 after Act 3, System 3 after Act 7). Reaper-0
  (Act 10) opens free exploration.
- About 1 world in 8 is PURE (every stage one affinity): 67 of 734 generated worlds.
  Note: the Art / Colouring prompt says "NO world is a single affinity"; this follows
  your answer to my question instead. `Cosmos.PURE_SHARE = 0.125`: set it to 0 to
  turn pure worlds off.

## Travel and unlocking
- A galaxy / system / world opens when a NEARER one (the ring inside it) is cleared.
  One is enough, and you pick which in each ring. Locked ones can always be
  previewed; only PLAY waits.
- Galaxy 1 counts as complete when Reaper-0 falls; Ring 1 galaxies open then. Another
  galaxy is complete when one of its Ring 3 systems is cleared. A system is cleared by
  its gate world (the farthest world: its Stage 5 boss is the system's singularity).

## Generation table
| Galaxy | Name | Ring | Level band | Worlds per system (Systems 1-10) | Affinity split (systems) | Worlds | Singularities | Pure worlds |
|---|---|---|---|---|---|---|---|---|
| 1 | Orbspire Galaxy | 0 | Lv1-30 | 5, 5, 5, 9, 10, 6, 9, 7, 5, 10 | 2/2/2/2/2 | 71 | 10 Act bosses + 7 | 4 |
| 2 | Tide Galaxy | 1 | Lv31-50 | 10, 5, 5, 7, 6, 6, 8, 7, 9, 9 | 2/2/2/2/2 | 72 | 10 | 11 |
| 3 | Thorn Galaxy | 1 | Lv41-60 | 8, 7, 6, 10, 10, 8, 10, 8, 7, 10 | 2/2/2/2/2 | 84 | 10 | 6 |
| 4 | Dawn Galaxy | 1 | Lv51-70 | 7, 6, 8, 10, 10, 6, 9, 9, 9, 7 | 2/2/2/2/2 | 81 | 10 | 5 |
| 5 | Void Galaxy | 2 | Lv61-80 | 5, 5, 8, 10, 9, 6, 5, 5, 6, 8 | 2/2/2/2/2 | 67 | 10 | 5 |
| 6 | Ember Galaxy | 2 | Lv71-90 | 10, 8, 8, 10, 9, 8, 9, 9, 5, 10 | 2/2/2/2/2 | 86 | 10 | 5 |
| 7 | Frost Galaxy | 2 | Lv81-100 | 7, 7, 7, 9, 9, 6, 10, 9, 6, 6 | 2/2/2/2/2 | 76 | 10 | 13 |
| 8 | Storm Galaxy | 3 | Lv91-105 | 5, 6, 6, 5, 6, 6, 9, 6, 7, 8 | 2/2/2/2/2 | 64 | 10 | 3 |
| 9 | Bloom Galaxy | 3 | Lv101-115 | 10, 10, 5, 10, 6, 8, 6, 6, 5, 8 | 2/2/2/2/2 | 74 | 10 | 9 |
| 10 | Core Galaxy | 3 | Lv111-120 | 8, 5, 7, 9, 7, 5, 5, 10, 7, 6 | 2/2/2/2/2 | 69 | 10 | 6 |
| | **Total** | | | 100 systems | | **744** | **107** | 67 |

- Wardens (Act mini-bosses + every generated world's Stage 4, and Stage 5 unless it
  is the system's singularity): 1,391.
- Every system's worlds cover all 5 affinities, as evenly as the count allows (a
  7-world system: 2/2/1/1/1). Stages 1-4 of a mixed world use 3+ affinities: the main
  one, one it is strong or weak against (the Stage 4 Warden) and one more.
- Galaxy 1 Systems 4-10 (after Reaper-0): Recommended Lv24-30 by ring.
- Inside other galaxies the band is split by ring (Tide: Lv31-35, 36-40, 41-45, 46-50),
  worlds rising across each system's range.

## Fights in generated worlds
- Enemies from the 50 enemy designs (10 per affinity, already coloured, so no recolour
  needed); Wardens drawn 1.25x, bosses 1.45x. Main Act bosses stay unique to the Acts.
- Tuned on the fly through the real damage code against the typical team at the
  world's Recommended Level (the Stage 6 reference team, evolved as the level needs,
  Prime / Ascendant / Singularity rarity by level), element-neutral like Stage 6:
  Stages 1-4 = 3 + 3 + 4 + 5 = 15 good-play turns, Stage 5 boss 9 (10 in the outer
  rings of the narrow late bands). Outer rings at least +4% HP / ATK.
- Wardens and bosses are armoured and have Resolve (max -50% HP per turn): no
  maxed team at the Recommended Level can one-shot them (tested).
- NEW RULE (needs your OK): **Element Shield** on generated Wardens and bosses: an orb
  attack of the affinity they resist does nothing (a Water boss shrugs off Fire).
  Without it a mono-Fire team cleared every Tide Galaxy world (all 4 hunters attack on
  every Fire match, which beats the x0.5 resist). With it, mono-Fire loses 29 of 72
  Tide worlds, mono-Water 32, and a balanced team clears all 72. Story Acts are
  untouched.
- XP per stage = XP for the next level at the Recommended Level x 0.10 (side worlds
  x0.25) x 1 / 1 / 1.2 / 1.5 / 2.5. Credits as if Act = level / 3. A system's
  singularity also gives 1 Key the first time (NEW, please confirm).

## Levelling
- Lv1-30 unchanged (XP 50 x level, +25% steps from Lv10; stats x1 -> x2.5).
- Lv31+: XP = 75 x level, with +35% steps carrying on from Lv30's x6.25 (so Lv31
  costs more than Lv30). Each level = +2% of the Lv30 stats (Lv60 x4.0, Lv120 x7.0).
- Galaxy caps = each galaxy's top level (Galaxy 1 Lv30, Ring 1 up to Lv70, Core
  Lv120): fights in a galaxy can't level you past its cap. A hunter already above it
  keeps its level. Training Cores stop at the highest cap you have reached.
- Evolution: Stage 2 at Lv15, Stage 3 at Lv30 (unchanged). Stage 4 (Lv60) and Stage 5
  (Lv90) are RESERVED only: no art or code. So for now hunters stop at Lv60.
- Recruit in Galaxies 2-10: once a hunter is Lv31+, the odds move to a new band where
  Singularity can also come from Advanced (1%) and Elite (5%) Recruit; Key 10%.
  Galaxy 1 odds unchanged.

## Counters and stats
Worlds Cleansed X/744 and Singularities Defeated X/107 on the universe, galaxy,
system and world maps (system maps also show the system's X/N). STATS: Worlds
Cleansed, Singularities Defeated, Wardens Defeated (X/1391), Acts Cleared, Total
Fights Won, Highest Combo, Total Play Time. Lifetime, saved, survive a restart, wiped
by New Game.

## Danger rating
Team level = the average level of the fighting team. Green at / above the Recommended
Level, Yellow 1-4 below (warns once per world), Red 5-9 below (every time), Skull 10+
below (every time: "Recommended Lv X, your team is Lv Y. This singularity will probably
kill you."). PLAY ANYWAY always works. "Losing costs 1 Energy": the game has no
Energy yet, so nothing is spent (not built in this update).

## Combat pop-up fix
- Tap a head plate: USE (greyed until READY) / DETAILS / CLOSE. No REPLACE, SWAP or
  team change in combat (Replace stays on the TEAM screen). DETAILS = the full detail
  screen (art, stats, every skill and passive, evolution), read-only in combat.
- Tap bug: plates open on RELEASE (and only if the tap started on the same plate);
  0.2 s lockout after opening; the buttons sit over the board, never over the plates;
  only CLOSE or a tap on the dark area outside closes it.
- 20 taps on plates in a real battle: **20/20** opened and stayed open until CLOSE.
- Already built in earlier stages and unchanged: live combo count + multiplier every
  tick, skill cut-ins (with the Settings toggle), FX sprite sheets, no idle bobbing,
  enemies x1.15-1.2, head-only plates.

## Colour versions + dual affinity
- Every human (20) and enemy character (10) now exists in all 5 affinities: 110 new
  colour versions ("<id>@water" etc.) plus the 10 named ones from Stage 3. Same
  design, archetype and skills; stats tilted about 5% (Fire +5% ATK -5% RCV, Water
  +5% RCV -5% ATK, Wood +5% HP -5% ATK, Light +5% RCV -5% HP, Dark +5% ATK -5% HP);
  recoloured in code from the original art (all 3 evolution stages). Recruit and
  fight drops only: never in fights, never in the Lab, no Essence.
- Side effect to know: a human Recruit pull is now one of 100 human versions, so the
  original 20 are 1 in 5 of human pulls. The odds per rarity are unchanged.
- Dual affinity, PROPOSED LIST (needs your approval), Stage 3 only, 8 of 30 (27%):

| Character | Main | Sub | Why it fits |
|---|---|---|---|
| Kaela Rynn (berserker_01_angel_fire) | Fire | Light | an angel of fire: wings of light round the flame |
| Sol Ashford (berserker_05_solar_light) | Light | Fire | a solar warrior: the sun's light is fire |
| Silas Root (biotech_02_splicer_wood) | Wood | Dark | a gene-splicer: living growth bent by forbidden technomancy |
| Kai Draven (spectre_04_assassin_water) | Water | Dark | an assassin striking from the shadows through the rain |
| Rowan Tide (titan_03_anchor_water) | Water | Wood | an anchor: kelp and coral root it to the seabed |
| Ember Drone (enemy) | Fire | Light | its glowing core is a small lamp |
| Vine Strangler (enemy) | Wood | Dark | grows in the dark and chokes the light out |
| Nix (enemy, void imp) | Dark | Fire | hellfire burns in the void |

  The sub affinity attacks when ITS orbs are matched, for 1/3 of ATK (10% if the same
  as the main), measured 0.33 and 0.10 in the test. Shown as two colours: plates get
  an inner border in the sub colour, cards a sub-colour glow and "Fire + Light", the
  detail screen "AFFINITY Fire + Light (dual)". Act 1 can't have Stage 3 hunters, so
  it is unchanged.

## XP table, Lv30 -> Lv120
(XP for the next level; total XP since reaching Lv30; stat multiplier at the new level vs Lv1.)

| Level | XP to next | Total since Lv30 | Stats |
|---|---|---|---|
| 30 -> 31 | 9,375 | 9,375 | x2.550 |
| 31 -> 32 | 15,345 | 24,720 | x2.600 |
| 32 -> 33 | 16,680 | 41,400 | x2.650 |
| 33 -> 34 | 18,068 | 59,468 | x2.700 |
| 34 -> 35 | 19,508 | 78,976 | x2.750 |
| 35 -> 36 | 21,000 | 99,976 | x2.800 |
| 36 -> 37 | 22,545 | 122,521 | x2.850 |
| 37 -> 38 | 24,142 | 146,663 | x2.900 |
| 38 -> 39 | 25,793 | 172,456 | x2.950 |
| 39 -> 40 | 27,495 | 199,951 | x3.000 |
| 40 -> 41 | 29,250 | 229,201 | x3.050 |
| 41 -> 42 | 31,058 | 260,259 | x3.100 |
| 42 -> 43 | 32,918 | 293,177 | x3.150 |
| 43 -> 44 | 34,830 | 328,007 | x3.200 |
| 44 -> 45 | 36,795 | 364,802 | x3.250 |
| 45 -> 46 | 38,813 | 403,615 | x3.300 |
| 46 -> 47 | 40,883 | 444,498 | x3.350 |
| 47 -> 48 | 43,005 | 487,503 | x3.400 |
| 48 -> 49 | 45,180 | 532,683 | x3.450 |
| 49 -> 50 | 47,407 | 580,090 | x3.500 |
| 50 -> 51 | 49,688 | 629,778 | x3.550 |
| 51 -> 52 | 52,020 | 681,798 | x3.600 |
| 52 -> 53 | 54,405 | 736,203 | x3.650 |
| 53 -> 54 | 56,842 | 793,045 | x3.700 |
| 54 -> 55 | 59,332 | 852,377 | x3.750 |
| 55 -> 56 | 61,875 | 914,252 | x3.800 |
| 56 -> 57 | 64,470 | 978,722 | x3.850 |
| 57 -> 58 | 67,118 | 1,045,840 | x3.900 |
| 58 -> 59 | 69,817 | 1,115,657 | x3.950 |
| 59 -> 60 | 72,570 | 1,188,227 | x4.000 |
| 60 -> 61 | 75,375 | 1,263,602 | x4.050 |
| 61 -> 62 | 78,233 | 1,341,835 | x4.100 |
| 62 -> 63 | 81,143 | 1,422,978 | x4.150 |
| 63 -> 64 | 84,105 | 1,507,083 | x4.200 |
| 64 -> 65 | 87,120 | 1,594,203 | x4.250 |
| 65 -> 66 | 90,188 | 1,684,391 | x4.300 |
| 66 -> 67 | 93,308 | 1,777,699 | x4.350 |
| 67 -> 68 | 96,480 | 1,874,179 | x4.400 |
| 68 -> 69 | 99,705 | 1,973,884 | x4.450 |
| 69 -> 70 | 102,982 | 2,076,866 | x4.500 |
| 70 -> 71 | 106,313 | 2,183,179 | x4.550 |
| 71 -> 72 | 109,695 | 2,292,874 | x4.600 |
| 72 -> 73 | 113,130 | 2,406,004 | x4.650 |
| 73 -> 74 | 116,617 | 2,522,621 | x4.700 |
| 74 -> 75 | 120,157 | 2,642,778 | x4.750 |
| 75 -> 76 | 123,750 | 2,766,528 | x4.800 |
| 76 -> 77 | 127,395 | 2,893,923 | x4.850 |
| 77 -> 78 | 131,093 | 3,025,016 | x4.900 |
| 78 -> 79 | 134,842 | 3,159,858 | x4.950 |
| 79 -> 80 | 138,645 | 3,298,503 | x5.000 |
| 80 -> 81 | 142,500 | 3,441,003 | x5.050 |
| 81 -> 82 | 146,408 | 3,587,411 | x5.100 |
| 82 -> 83 | 150,368 | 3,737,779 | x5.150 |
| 83 -> 84 | 154,380 | 3,892,159 | x5.200 |
| 84 -> 85 | 158,445 | 4,050,604 | x5.250 |
| 85 -> 86 | 162,563 | 4,213,167 | x5.300 |
| 86 -> 87 | 166,733 | 4,379,900 | x5.350 |
| 87 -> 88 | 170,955 | 4,550,855 | x5.400 |
| 88 -> 89 | 175,230 | 4,726,085 | x5.450 |
| 89 -> 90 | 179,558 | 4,905,643 | x5.500 |
| 90 -> 91 | 183,938 | 5,089,581 | x5.550 |
| 91 -> 92 | 188,370 | 5,277,951 | x5.600 |
| 92 -> 93 | 192,855 | 5,470,806 | x5.650 |
| 93 -> 94 | 197,392 | 5,668,198 | x5.700 |
| 94 -> 95 | 201,983 | 5,870,181 | x5.750 |
| 95 -> 96 | 206,625 | 6,076,806 | x5.800 |
| 96 -> 97 | 211,320 | 6,288,126 | x5.850 |
| 97 -> 98 | 216,068 | 6,504,194 | x5.900 |
| 98 -> 99 | 220,867 | 6,725,061 | x5.950 |
| 99 -> 100 | 225,720 | 6,950,781 | x6.000 |
| 100 -> 101 | 230,625 | 7,181,406 | x6.050 |
| 101 -> 102 | 235,582 | 7,416,988 | x6.100 |
| 102 -> 103 | 240,593 | 7,657,581 | x6.150 |
| 103 -> 104 | 245,655 | 7,903,236 | x6.200 |
| 104 -> 105 | 250,770 | 8,154,006 | x6.250 |
| 105 -> 106 | 255,938 | 8,409,944 | x6.300 |
| 106 -> 107 | 261,157 | 8,671,101 | x6.350 |
| 107 -> 108 | 266,430 | 8,937,531 | x6.400 |
| 108 -> 109 | 271,755 | 9,209,286 | x6.450 |
| 109 -> 110 | 277,133 | 9,486,419 | x6.500 |
| 110 -> 111 | 282,563 | 9,768,982 | x6.550 |
| 111 -> 112 | 288,045 | 10,057,027 | x6.600 |
| 112 -> 113 | 293,580 | 10,350,607 | x6.650 |
| 113 -> 114 | 299,168 | 10,649,775 | x6.700 |
| 114 -> 115 | 304,808 | 10,954,583 | x6.750 |
| 115 -> 116 | 310,500 | 11,265,083 | x6.800 |
| 116 -> 117 | 316,245 | 11,581,328 | x6.850 |
| 117 -> 118 | 322,043 | 11,903,371 | x6.900 |
| 118 -> 119 | 327,893 | 12,231,264 | x6.950 |
| 119 -> 120 | 333,795 | 12,565,059 | x7.000 |
