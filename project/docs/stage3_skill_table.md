# Orbspire: Stage 3 skill table (APPROVED 2026-11-18, built in Part A)

Built in Stage 3 Part A. Changes after approval:
- **Bram Stone:** Passive 3 is Damage Resist (Bind Resist removed until binds exist).
- **Last Stand:** now "once per fight, a hit that would defeat the team leaves it at 1 HP".
- **Mend:** CD 5.
- **Four leaders toned down** after the Part A balance test (a team of 3 cleared Act 1 in 11-13 turns instead of about 16): Bloodmoon x1.15 / x2 below 50% (was x1.5 / x2.25), Zenith needs 7+ Light orbs (was 6), Rootwork and Second Wind x1.5 (were x1.75).
- **Numbers:** all live in data/skills/skill_tuning.tres; the test is tests/skill_test.tscn.

## Rules for the whole table
- **Leader skills never stack.** Only the hunter in slot 1 is the leader; the leader skills of slots 2-4 do nothing.
- **Personal passives** (marked *self*) only change that hunter, so two hunters with Cleave each get their own Cleave.
- **Team passives** (marked *team*: Time Extend, Overflow Heal, Damage Resist, Fire ATK Up) do NOT stack. If two hunters have the same one, it counts once.
- **Passive unlocks:** Passive 1 at Lv10, Passive 2 at Evolution 1 (Stage 2), Passive 3 at Evolution 2 (Stage 3).
- **Cooldowns** are CD 5-9 at Stage 1. Each evolution still takes 1 off (approved earlier), so Stage 3 is 2 less.
- **Skill damage** uses the same hit code as orb attacks, so the boss **Resolve** cap applies: a boss or mini-boss loses at most 50% of its max HP per player turn, skills included.
- **"This turn"** means the next orb move.

## BERSERKERS: AoE brawlers
| # | Character | Active skill | Leader skill | Passive 1 (Lv10) | Passive 2 (Evo 1) | Passive 3 (Evo 2) | Role |
|---|---|---|---|---|---|---|---|
| 1 | Kaela Rynn, Fire (starter) | **Overrun**, CD7: every Wood orb turns into Fire | **Furnace Heart**: 4+ Fire orbs in one group -> Fire hunters ATK x2 this turn | Cleave: her 4+ groups hit ALL enemies at x1.5 *(self)* | Skill Boost: her skill starts each Act 1 turn closer *(self)* | Breaker: a 3x3 Fire square hits x2.5 and goes through armour *(self)* | AoE burst for Fire teams |
| 2 | Iris Vale, Water (starter) | **Overrun**, CD7: every Fire orb turns into Water | **Riptide**: 4+ Water in one group -> Water hunters ATK x1.75, and the next enemy hit is 15% weaker | Cleave *(self)* | Time Extend: +1 s to move orbs *(team)* | Breaker *(self)* | AoE with a little defence |
| 3 | Drek Vane, Wood (starter) | **Overrun**, CD7: every Water orb turns into Wood | **Overgrowth**: 4+ Wood in one group -> Wood hunters ATK x1.75, and heal 5% team HP | Cleave *(self)* | **Regrowth** (new): every turn Drek attacks, heal 4% team HP *(self)* | Breaker *(self)* | AoE with a little sustain |
| 4 | Corvin Hale, Dark | **Night Rend**, CD8: Corvin hits ALL enemies for ATK x2 (Dark damage) and breaks their armour | **Bloodmoon**: Dark hunters ATK x1.15; x2 instead while team HP is below 50% | **Bloodlust** (new): his ATK x1.3 while team HP is below 50% *(self)* | Cleave *(self)* | Last Stand: once per fight, a hit that would defeat the team leaves it at 1 HP *(team)* | Risky comeback AoE |
| 5 | Sol Ashford, Light | **Solar Flare**, CD7: the bottom row turns into Light orbs; Light hunters ATK x1.5 this turn | **Zenith**: 7+ Light orbs matched in one turn (any groups) -> every hunter ATK x1.75 | Cleave *(self)* | **Orb Enhance** (new): his groups of 5+ orbs hit x1.3 *(self)* | Ambush: his first attack each fight x2 *(self)* | Board setup for Light teams |

## SPECTRES: single-target burst (base stats 230 HP / **110** ATK / 8 RCV; ATK was 130, see the balance check)
| # | Character | Active skill | Leader skill | Passive 1 (Lv10) | Passive 2 (Evo 1) | Passive 3 (Evo 2) | Role |
|---|---|---|---|---|---|---|---|
| 6 | Vex Marlowe, Dark | **Shadow Verdict**, CD8: ATK x4 to the target. A regular enemy below 25% HP is defeated instantly; bosses and mini-bosses take ATK x6 instead (never instant) | **Nightfall**: 5 combos -> all hunters ATK x1.5, rising to x2.5 at 7+ combos | Ambush *(self)* | Combo Boost: x2 at 7+ combos *(self)* | Finisher: x1.5 on enemies below 50% HP *(self)* | Finisher for combo teams |
| 7 | Joren Ash, Fire | **Ember Lance**, CD7: ATK x5 Fire damage to the target; this one hit ignores armour | **Kindled Focus**: 5+ combos -> Fire hunters ATK x2.25 | Finisher *(self)* | Skill Boost *(self)* | Breaker *(self)* | Armour cracker |
| 8 | Wren Solis, Wood | **Thorn Snipe**, CD6: ATK x3 to the target, and it takes +25% damage from everything for 2 turns | **Hunter's Mark**: attacks on the enemy you tapped hit x1.75 (no tap, no bonus) | Ambush *(self)* | Time Extend *(team)* | Combo Boost *(self)* | Marks one target for the team |
| 9 | Kai Draven, Water | **Undertow Strike**, CD8: ATK x3 to the target, x5 instead if it is below 50% HP | **Cold Precision**: attacks on enemies below 50% HP hit x2 | Finisher *(self)* | Ambush *(self)* | Skill Boost *(self)* | Closer for the second half of a fight |
| 10 | Lyra Quinn, Light | **Radiant Pierce**, CD7: ATK x3 to the target, breaks its armour, and turns 3 random orbs into Light | **Halo Sight**: 4+ combos -> all hunters ATK x1.25, Light hunters x1.75 instead | Combo Boost *(self)* | Finisher *(self)* | Orb Enhance *(self)* | Light burst + orb support |

## TITANS: tanks
| # | Character | Active skill | Leader skill | Passive 1 (Lv10) | Passive 2 (Evo 1) | Passive 3 (Evo 2) | Role |
|---|---|---|---|---|---|---|---|
| 11 | Bram Stone, Wood | **Bulwark**, CD6: the next 2 enemy attacks deal 50% | **Stone Wall**: team HP x1.3; match Hearts -> the next enemy hit is 25% weaker | Counter: when the team is hit, he strikes back for ATK x1 *(self)* | Last Stand *(team)* | **Damage Resist**: the team takes 10% less *(team)* | Classic wall |
| 12 | Freya Holt, Fire | **Forge Guard**, CD7: the next 3 enemy attacks deal 35% less, and she strikes back at each attacker for ATK x1 | **Molten Ward**: team HP x1.2, Fire hunters ATK x1.3 | Counter *(self)* | **HP Up** (new): her HP +15% *(self)* | **Retaliation** (new): her Counter hits x2 while team HP is below 50% *(self)* | Tank that hits back |
| 13 | Rowan Tide, Water | **Tidewall**, CD7: heal 15% team HP, and the next 2 enemy attacks deal 40% less | **Deep Current**: team HP x1.2, team RCV x1.5 | **Damage Resist** (new): the team takes 10% less *(team)* | **RCV Up** (new): her RCV +25% *(self)* | Last Stand *(team)* | Healing tank |
| 14 | Dmitri Voss, Dark | **Gravity Well**, CD8: every enemy's ATK -30% for their next 2 turns | **Iron Pact**: team HP x1.25; while team HP is below 50%, the team takes 30% less | Counter *(self)* | Damage Resist *(team)* | HP Up *(self)* | Shuts down multi-enemy fights |
| 15 | Aurelia Dawn, Light | **Sanctuary**, CD9: block the next enemy attack completely (one attack), and heal 10% team HP | **Dawn Aegis**: team HP x1.15, and the team takes 15% less from every hit | Last Stand *(team)* | Damage Resist *(team)* | HP Up *(self)* | Boss-hit insurance |

## BIOTECHS: healers and support
| # | Character | Active skill | Leader skill | Passive 1 (Lv10) | Passive 2 (Evo 1) | Passive 3 (Evo 2) | Role |
|---|---|---|---|---|---|---|---|
| 16 | Mira Solace, Water | **Mend**, **CD5**: heal 30% team HP and turn 3 random orbs into Hearts | **Lifeline**: 2+ elements matched -> all hunters ATK x1.5, and heal 10% team HP | Time Extend *(team)* | Overflow Heal: Heart groups of 5+ heal x1.5 *(team)* | Field Medic: when she uses Mend, every other skill charges 1 turn *(self)* | Main healer |
| 17 | Silas Root, Wood | **Spore Bloom**, CD6: every Dark orb turns into a Heart | **Rootwork**: match Hearts -> Hearts heal x1.5 and Wood hunters ATK x1.5 | RCV Up *(self)* | **Heart Charge** (new): match 5+ Hearts in one turn -> his skill charges 1 extra turn *(self)* | Overflow Heal *(team)* | Heart engine for Wood teams |
| 18 | Ash Moreno, Fire | **Cauterize**, CD7: heal 20% team HP; Fire hunters ATK x1.5 this turn | **Second Wind**: team RCV x1.3; match Hearts -> Fire hunters ATK x1.5 | RCV Up *(self)* | Skill Boost *(self)* | **Fire ATK Up** (new): Fire hunters ATK +10% *(team)* | Battle medic for Fire teams |
| 19 | Selene Dark, Dark | **Night Bloom**, CD8: heal 12% team HP at the start of each of your next 3 turns (36% in total) | **Umbral Pact**: team RCV x1.3; 3+ elements matched -> Dark hunters ATK x2 | Time Extend *(team)* | Damage Resist *(team)* | Field Medic *(self)* | Slow, steady healing |
| 20 | Luca Bright, Light | **Dawn Chorus**, CD6: turn 4 random orbs into Hearts and +2 s to move this turn | **Radiance**: +1 s to move; match Hearts -> every hunter ATK x1.3 | Overflow Heal *(team)* | Time Extend *(team)* | Heart Charge *(self)* | Easy-mode support |

Checks on uniqueness:
- The 17 non-starter actives all have their own names.
- All 20 leaders are different (names and effects).
- No two hunters share the same 3 passives.

## Balance check (plain words)
1. **No boss one-shots, at any level.** Resolve caps every boss and mini-boss at -50% max HP per player turn, skill hits included, so Lv1, Lv15 and Lv30-evolved all fail to one-shot.
   - Strongest skill hits at Lv1 (Forged): Joren's Ember Lance 110 x 5 = 550, or 1,100 with a strong element. The smallest mini-boss (Furnace Worker) has 1,950 HP. So no Lv1 one-shot of a mini-boss even without Resolve.
   - Execute-type skills (Vex, Kai) only finish weakened enemies, and never bosses instantly.
2. **Spectres toned down: ATK 130 -> 110** (HP stays 230, still the highest ATK of the 4 types). With good play, a team of 3 Spectres clears Act 1 in **15 turns** (was 12). With average play it is 23 turns, the same as Berserkers.
   - ATK 100 still gave 15 turns: turns only move in whole steps, so 16 would need Spectre ATK below Berserker ATK. I chose 110 to keep "high ATK".
3. **Teams of 3 of the other types** measured 16 (Berserker), 16 (Titan) and 17 (Biotech) in Stage 2. The new leader skills stay at x1.25-x2.5, like the old ones. **Part A re-measures all of this with the real skills** and tunes any number that drifts outside 15-17.
4. **Starters stay equal.**
   - All three keep Overrun (CD7), the same stats and Cleave at Lv10.
   - Their leaders all trigger on "4+ of their colour in one group": Kaela gets x2 with nothing extra; Iris and Drek get x1.75 plus a small extra (a weaker next hit / a 5% heal).
   - The tutorial is fought with 3-orb matches, which trigger no leader, so it stays identical. Part A re-tests all three.
5. **Resolve can't be bypassed.**
   - "Ignores armour" (Joren, Lyra, Corvin) only skips the armour gimmick, never Resolve.
   - Instant defeat only works on regular enemies.

## Toned down from the Puzzles & Dragons ideas
| Idea | P&D-style | Orbspire version | Why |
|---|---|---|---|
| Leader multipliers | often x4 to x25+ | x1.25 to x2.5, conditional | Bosses are tuned around x2 leaders; big multipliers bring back the one-shot problem |
| Board change | whole colours, short cooldowns | one colour (or one row), CD7 | Free full boards every few turns would make combos trivial |
| Orb enhance | big boosts | x1.3, only on 5+ groups, self only | Stacks with Cleave/leaders, so it has to be small |
| Execute | instant kill, sometimes on bosses | regular enemies only; bosses take ATK x6 and Resolve still applies | "No skill that instantly defeats a boss" |
| Damage void / shield break | ignores all defences | breaks the Armour gimmick for one hit; Resolve still applies | Keeps bosses lasting more than one turn |
| Defence down | often huge | +25% damage taken for 2 turns | Stacks with leader and element multipliers |
| Time extend | can be large or stack | +1 s passive (doesn't stack); +2 s for one turn (Luca's skill) | "No unlimited time" |
| Skill charge | can refill whole teams | Field Medic: 1 turn, only when that healer uses her skill | Prevents skill loops |
| Damage reduction | can reach full invulnerability | 50% for 2 attacks (Bram); 1 full block at CD9 (Aurelia) | Nothing is permanent |
| Healing | can exceed max HP | never above max; biggest single heal 30%; heal over time 36% across 3 turns | "No unlimited healing". The prompt's idea list says Overflow Heal "heals over max HP"; in Orbspire it stays a x1.5 heal on 5+ Heart groups, capped at max HP |
| ATK up for an affinity | x2+ | x1.5 for one turn (Sol, Ash); +10% passive (doesn't stack) | Overlaps with leader skills |
| Gravity (% HP damage) | left out | none | % damage ignores boss HP tuning and Resolve-style caps |

## Open questions
1. **Mend CD.** Stage 2 set Mend to CD4, but the Stage 3 rule is CD 5-9. I set Mira's Mend to **CD5**. OK, or keep CD4 as an exception?
2. **Last Stand.** The prompt's idea list describes it as "survive a fatal hit once per fight", but Orbspire's (approved in Phase 3) is "below 30% team HP, take 30% less". I kept Orbspire's. Switch?
3. **Bind Resist.** No enemy uses binds yet, so Bram's Passive 3 does nothing for now (kept from Phase 3). OK?
