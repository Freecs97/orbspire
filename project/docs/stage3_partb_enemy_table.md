# Orbspire: Stage 3 Part B, enemies as playable characters (APPROVED and BUILT 2026-11-18)

Built. Answers / changes after approval:
- **Essence:** each drop rolls 50/50 between the enemy's OWN Essence and the human Essence it used to give.
- **Drop rate:** regular enemies 30% chance of 2 Essence (was 15% x 1), about 17 wins for 10. Mini-bosses 1-2 every win, bosses 3.
- **Recolours:** keep their original's type.
- **Stat fixes:** Helios RCV 9 (was 10, which tied a human Berserker). The Light tilt gives RCV +5% (was +10%) and the Wood tilt keeps full ATK, so every enemy stays below the human Forged numbers and Bog Slime's team of 3 is 17 turns (was 18).
- **Part A fix found here:** the balance sim now tells leaders which enemy is hit. That showed Kai's Cold Precision makes a 3-Kai team clear Act 1 in 13 turns (bosses lose their Resolve turn). Cold Precision now works on regular enemies only; Kai's team is 15 again.
- **Correction:** the draft said no enemy leader is faster than a human leader with the same humans. In fact several are 1 turn faster (14 vs 15). Every enemy-led team is still 14+ (never 11-13).
- **Animations:** Part A's Godot code effects (no FX sprite sheets yet).

Same rules as the human table:
- **Leaders:** only slot 1 leads; leader skills never stack.
- **Passives:** *team* passives count once; *self* passives only change that character.
- **Cooldowns:** CD 5-9.
- **Resolve:** every skill hit goes through it (bosses and mini-bosses lose at most 50% max HP per turn).
- **Passive unlocks:** Passive 1 at Lv10, Passive 2 at Evolution 1, Passive 3 at Evolution 2.
- **Evolution:** these enemies have no Stage 2/3 art yet, so they keep their art when they evolve; stats, cooldown and passives still go up.

## The 10 kits
| # | Enemy | Archetype (why) | Active skill | Leader skill | Passive 1 (Lv10) | Passive 2 (Evo 1) | Passive 3 (Evo 2) |
|---|---|---|---|---|---|---|---|
| 1 | Ember Drone, Fire | **Berserker**: a small drone that bursts into flame and hits everything | **Cinder Burst**, CD6: hits ALL enemies for ATK x1.5 (Fire) | **Kindling Swarm**: match 2+ separate Fire groups -> Fire hunters ATK x1.15 | Cleave *(self)* | Ambush *(self)* | Fire ATK Up *(team)* |
| 2 | Coolant Slime, Water | **Biotech**: a coolant blob that cools and soothes | **Coolant Flush**, CD6: every Fire orb turns into a Heart; heal 10% | **Coolant Loop**: team RCV x1.25; match Hearts -> Water hunters ATK x1.15 | RCV Up *(self)* | Overflow Heal *(team)* | Damage Resist *(team)* |
| 3 | Spore Sprout, Wood | **Biotech**: a sprout whose spores heal allies and weaken foes | **Spore Puff**, CD5: heal 15%; every enemy's next attack is 20% weaker | **Germinate**: +1 s to move orbs; Wood hunters ATK x1.2 | Time Extend *(team)* | RCV Up *(self)* | Last Stand *(team)* |
| 4 | Helios (Solar Drone), Light | **Berserker**: a sun-core drone that floods the field with light | **Sunburst Charge**, CD7: the TOP row turns into Light orbs, and 2 random orbs into Hearts | **Solar Array**: Light hunters ATK x1.15; x1.6 at 4+ combos | Cleave *(self)* | Orb Enhance *(self)* | Skill Boost *(self)* |
| 5 | Shade (Shadow Thief), Dark | **Spectre**: a hooded thief with twin blades, one target at a time | **Twin Shiv**, CD6: hits the target TWICE for ATK x2 each (Dark) | **Backstab**: attacks on enemies above 80% HP hit x1.25 | Ambush *(self)* | Finisher *(self)* | Bloodlust *(self)* |
| 6 | Furnace Worker, Fire | **Titan**: a bulky heat-suit worker built to take hits | **Heat Vent**, CD7: the next 2 enemy attacks do 40% less; Fire hunters ATK x1.3 this turn | **Heat Shielding**: team HP x1.2, Fire hunters ATK x1.15, and the team takes 20% less from FIRE enemies | Counter *(self)* | HP Up *(self)* | Fire ATK Up *(team)* |
| 7 | Tide Guard, Water | **Titan**: wave armour, trident and shield | **Trident Wall**, CD8: the next 3 enemy attacks do 30% less; heal 10% | **Wave Wall**: team HP x1.15, team RCV x1.15, Water hunters ATK x1.15 | Counter *(self)* | RCV Up *(self)* | Last Stand *(team)* |
| 8 | Vine Strangler, Wood | **Spectre**: a vine creature that grabs and chokes one target | **Strangle**, CD7: ATK x3 to the target (Wood); its next attack is 50% weaker | **Constrict**: 5+ combos -> every hunter ATK x1.75 | Finisher *(self)* | Combo Boost *(self)* | Skill Boost *(self)* |
| 9 | Prisma (Prism Wisp), Light | **Biotech**: a crystal spirit that bends light into healing | **Refract**, CD7: every Dark orb turns into Light; heal 10% | **Refraction**: Light hunters ATK x1.2; x1.4 and heal 8% when 2+ elements are matched | RCV Up *(self)* | Field Medic *(self)* | Heart Charge *(self)* |
| 10 | Nix (Void Imp), Dark | **Spectre**: a small imp that preys on the weak | **Void Bite**, CD6: ATK x2.5 to the target (Dark); heal the team for 50% of the damage dealt | **Void Hunger**: Dark hunters hit x1.4 against enemies below 50% HP | Ambush *(self)* | Bloodlust *(self)* | Combo Boost *(self)* |

Archetype spread: 2 Berserkers, 2 Titans, 3 Spectres, 3 Biotechs.

Uniqueness checks:
- All 10 active and leader names are new (none shared with the 20 humans).
- No enemy shares a full set of 3 passives with any other enemy or human.

## How to get each one, rarity, Lv1 stats
"Base" = the character's stats at Forged. "At its rarity" = what you actually get from the Lab.

Human Forged Lv1 for comparison: Berserker 320/95/10, Titan 470/78/26, Spectre 230/110/8, Biotech 350/72/46.

| Enemy | Where it drops Essence | Rarity from the Lab | Base HP/ATK/RCV | At its rarity |
|---|---|---|---|---|
| Ember Drone | Act 1 fight 5 | Scrap | 280 / 88 / 8 | 238 / 75 / 7 |
| Coolant Slime | Act 1 fight 2, Act 8 fight 4 | Scrap | 300 / 62 / 42 | 255 / 53 / 36 |
| Spore Sprout | Act 1 fight 4 (2 sprouts = 2 rolls) | Scrap | 320 / 60 / 40 | 272 / 51 / 34 |
| Helios | Act 1 fight 1 (tutorial) | Scrap | 300 / 84 / 9 | 255 / 71 / 8 |
| Shade | Act 1 fight 6 (2 Shades = 2 rolls) | Alloy | 200 / 100 / 6 | 184 / 92 / 6 |
| Furnace Worker | Act 1 fight 3, mini-boss: 1-2 every win | Alloy | 430 / 70 / 22 | 396 / 64 / 20 |
| Tide Guard | Act 2 fight 3, mini-boss: 1-2 every win (also Act 9 fight 4) | Alloy | 420 / 68 / 24 | 386 / 63 / 22 |
| Vine Strangler | Act 3 fight 3, mini-boss: 1-2 every win | Forged | 210 / 98 / 7 | 210 / 98 / 7 |
| Prisma | Act 3 fight 5, Act 7 fight 5, Act 9 fight 1 | Alloy | 310 / 64 / 42 | 285 / 59 / 39 |
| Nix | Act 3 fight 6, Act 10 fight 1 | Alloy | 215 / 92 / 7 | 198 / 85 / 6 |

Every enemy is below the human Forged numbers of its archetype, before rarity and after it. They grow through levels and evolution like humans: Stage 1 cap Lv15, Stage 2 cap Lv30.

## Balance check (measured in the balance sim)
How it was measured:
- **Engine:** the real damage and enemy code, through Act 1.
- **Enemies:** made element-neutral.
- **Play:** good play.
- **Stats:** base stats.
- **Leader skills:** the PROPOSED ones, modelled in a scratch copy of the sim.
- **Not counted:** active skills. Part B2 re-measures everything with the real skills.

| Enemy | 3 of it | It leads 2 humans* | Same 2 humans + a human leader |
|---|---|---|---|
| Ember Drone | 15 | 14 | 15 |
| Coolant Slime | 17 | 15 | 15 |
| Spore Sprout | 17 | 14 | 15 |
| Helios | 16 | 14 | 15 |
| Shade | 15 | 14 | 14 |
| Furnace Worker | 16 | 15 | 15 |
| Tide Guard | 16 | 15 | 15 |
| Vine Strangler | 16 | 15 | 15 |
| Prisma | 16 | 14 | 15 |
| Nix | 15 | 14 | 14 |

\*The two humans are the Berserker and Spectre of the enemy's element (e.g. Kaela + Joren for Ember Drone).

- **Teams of 3 enemies:** 15-17 turns, same as human teams, not faster.
- **Enemy leaders: no repeat of the Part A problem.** My first drafts did repeat it:
  - Ember Drone x1.3 -> 12 turns, Coolant x1.25 -> 13, Shade x1.6 -> 13, Nix x1.25 / x1.7 -> 12-13.
  - I cut them to the numbers above.
  - Now no enemy leader beats 14, and none is faster than a human leader with the same two humans.
- **No one-shots, at Lv1, Lv15 or Lv30 evolved:** every skill hit goes through Resolve (max -50% per turn on bosses and mini-bosses).
  - Biggest Lv1 skill: Shade's Twin Shiv, 2 x 184 = 368 at Alloy (736 with a strong element), against the smallest mini-boss's 1,950 HP.
  - At Lv30, Singularity, both evolutions: Twin Shiv is about 1,440 raw, below Emberfang-9's 2,900 HP even without Resolve.
- **Resolve can't be bypassed:**
  - Twin Shiv's 2 hits and Void Bite's heal both count against the boss's per-turn cap like any other hit.
  - No skill defeats a boss instantly.

## Recolours (Godot code only, a shader on the existing PNG; no new art)
| Design | Recoloured versions (new roster characters) |
|---|---|
| Ember Drone (Fire) | Water "Frost Drone" (blue), Wood "Moss Drone" (green) |
| Coolant Slime (Water) | Fire "Magma Slime" (orange-red), Wood "Bog Slime" (green) |
| Spore Sprout (Wood) | Fire "Ash Sprout" (red), Water "Dew Sprout" (blue) |
| Helios (Light) | Dark "Eclipse Drone" (purple, darkened) |
| Shade (Dark) | Light "Glint" (gold, brightened) |
| Prisma (Light) | Dark "Umbral Wisp" (purple, darkened) |
| Nix (Dark) | Light "Lux Imp" (gold, brightened) |

- **Count:** 10 recoloured characters in total. Fire, Water and Wood designs get the other two triangle colours; Light and Dark designs get the opposite one.
- **Recoloured versions:**
  - Same design, new element, so a different roster character.
  - Stats tilt about 5% (e.g. Water versions +RCV, Fire versions +ATK).
  - They keep the base enemy's archetype and kit, acting on their new element.
  - Rarity matches the original.
- **How to get them:** they never appear in fights, so they can't drop Essence. Proposal: they join the Recruit pool and the Scrap/fight-drop pool.
- **NOT recoloured:**
  - Furnace Worker, Tide Guard and Vine Strangler (mini-bosses stay unique, like bosses).
  - The 10 main bosses.
  - All 20 human characters.

## Open questions
1. **Essence source.** Today these 10 enemies drop Essence for HUMAN characters (e.g. Ember Drone -> Kaela Rynn). My proposal: they drop their OWN Essence instead. Downside: Act 1 then gives human Essence only from the boss; humans still come from Recruit, Scrap drops and later Acts. Or should each drop roll 50/50 between the two?
2. **Drop rate.** At the current 15%, a 1-enemy fight needs about 67 wins on average for 10 Essence. Mini-bosses need about 7. Keep 15% for regular enemies, or raise it (e.g. 30%, about 33 wins)?
3. **Recolour archetypes.** I kept the archetype on recoloured versions; only the element changes. Your prompt mentions recolours for "different archetypes" too. If you want e.g. Frost Drone to be a Water Biotech, each such version needs its own kit, and I'd bring a second table for those.
