# Stage 6: Acts 2-10 on the new balance (built 2026-11-19)

Built by `tools/generate_acts.gd`, one Act at a time, one fight at a time. Full per-fight
playtest: `tools/act_generation_report.txt`. Test: `tests/stage6_test.tscn`.

## How it was built
- 240 simulated players start a New Game (one starter each) and play the whole
  campaign through the REAL reward / Recruit / Lab / evolution / level-cap code.
- Half are **keepers** (always their 4 strongest hunters now), half are **upgraders**
  (at each Act start they bring their 4 highest-rarity hunters and train them up).
- Spending: Keys -> Key Recruit, Essence -> craft, capped hunters -> evolve (buying
  Cores), save for the next evolution, Basic Recruits up to 8 characters, then
  Training Cores for the lowest hunter.
- Each fight is tuned to the TYPICAL team right before it (median level / rarity /
  evolution per slot), element-neutral, then every player plays it with their own team
  and real elements.
- Targets per slot like Act 1 (good-play turns, turns until a team that does nothing
  falls), x1.30 -> x1.55 HP and x1.25 -> x1.41 ATK from Act 2 to Act 10, and every fight
  at least 4% stronger than the same fight one Act before.
- Mini-bosses and bosses: armoured, Resolve (max -50% HP per turn), survive one perfect
  6-combo turn; good play needed, average play often loses.

## Results (medians of 240 players)
| Act | Colony / boss (element) | Boss HP / ATK | Typical team, good play | Players beat the boss: good / average play | Team after the boss |
|---|---|---|---|---|---|
| 1 | Orbspire / Emberfang-9 (Fire) - unchanged | 2900 / 216 | 8 turns | 100% / 47% | Lv10 · Scrap 67%, Forged 33% |
| 2 | Drowned Metro / Tidecoil-7 (Water) | 3910 / 298 | 8 | 94% / 45% | Lv12 · Scrap 45%, Alloy 16%, Forged 39% |
| 3 | Greenhouse Ruins / Thornwood Unit (Wood) | 4280 / 334 | 8 | 90% / 40% | Lv14 · first Prime (3%) |
| 4 | Upper Spires / Dawnwing (Light) | 5070 / 375 | 9 | 93% / 21% | Lv16/15 · lead evolved, half the team Stage 2 |
| 5 | Void Quarter / Voidscale (Dark) | 5380 / 417 | 9 | 91% / 26% | Lv18-15 · 97% Stage 2 · first Ascendant |
| 6 | Solar Farms / Ashen-01 (Fire) | 5600 / 462 | 9 | 95% / 52% | Lv20-19 · all Stage 2 |
| 7 | Data Abyss / Kraken Mainframe (Water) | 5820 / 516 | 9 | 89% / 38% | Lv22 · Prime 29% · first Singularity (Act clear Key) |
| 8 | Gene Labs / Mossback Chimera (Wood) | 6050 / 555 | 9 | 89% / 41% | Lv25-24 |
| 9 | Core Sanctum / Seraph Enforcer (Light) | 6450 / 605 | 9 | 95% / 33% | Lv28-27 |
| 10 | The Core / Reaper-0 (Dark) | 7270 / 681 | 9 | 88% / 30% (keepers 78%, upgraders 98%) | Lv30 = max, after evolving |

- Regular fights: 100% win with good play, 98-100% with average play.
- Mini-bosses: 95-100% with good play, 30-75% with average play.
- XP: the team reaches Lv10, 12, 14, 16, 18, 20, 22, 24, 27, 30 after each boss. The
  Stage 1 cap (Lv15) is hit in Act 4; evolving is affordable then (the lead evolves in
  Act 4, the whole team by the end of Act 5). Lv30 (max) only after Act 10.
- Upgrading pays off late: keepers win Reaper-0 78% of the time with good play, upgraders 98%.

## Story (universe only: THE PROGENITORS, technomancy, singularities)
Each Act: 3 intel lines (star map), a 2-line intro (first time you start it), a boss
taunt, an outro, and a codex entry (spliced from / wanted / cost). Every singularity was
made and discarded by the Progenitors; every outro reframes the Act before it; no clean wins.
The arc: Emberfang-9 guarded the metro's water -> Tidecoil-7 watered the Greenhouse ->
Dawnwing's guess starved it -> Voidscale swallowed the correction -> Ashen-01's fires cut
the Quarter -> the Kraken kept the orders -> every splice came from the Chimera -> the
Seraph locked the Progenitors in with it -> Reaper-0: the Progenitors were the first splices.
Texts live in `tools/generate_acts.gd` (STORY) and the `data/acts/act_NN.tres` files.
