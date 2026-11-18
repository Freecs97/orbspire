# Orbspire — Phase 2 Lineup Spec

Status: **waiting for your approval** (2026-11-18). This is the agreed result of the Phase 2 questionnaire. Nothing here is built yet; Phase 3 builds it.

Where you changed an answer more than once, the **latest** answer is the one written here.

## The board

- 6 columns × 5 rows. **6 orb types from Act 1:** Fire, Water, Wood, Light, Dark, Heart.
- Element wheel: Fire beats Wood, Wood beats Water, Water beats Fire (2× / 0.5×). Light and Dark each beat the other (2×). Anything else 1×.
- Damage formula, combo multiplier, healing and rounding stay exactly as in the prototype.

## Types (the stat pattern only)

Type is locked per character design. Any design can be any affinity.

| Type | Like PAD's | HP | ATK | RCV | Lv1 (HP / ATK / RCV) | Lv30 (×3) | Lv30 + Evo 2 (+20%) |
|---|---|---|---|---|---|---|---|
| Berserker | Dragon | Med | Med | Low | 320 / 95 / 10 | 960 / 285 / 30 | 1152 / 342 / 36 |
| Titan | Physical | High | Low | Med | 420 / 65 / 22 | 1260 / 195 / 66 | 1512 / 234 / 79 |
| Spectre | Attacker | Low | High | Low | 230 / 130 / 8 | 690 / 390 / 24 | 828 / 468 / 29 |
| Biotech | Healer | Med | Low | High | 320 / 55 / 40 | 960 / 165 / 120 | 1152 / 198 / 144 |

Rarity multipliers (Scrap → Singularity) are set in Phase 6 and apply on top.

## The 4 Act 1 designs

Look, weapon, personality and gender: **yours** — whatever your art shows. Skills belong to the design.

| Design | Leader skill (slot 1 only) | Active skill (verb · CD) | Passive 1 (Lv10) | Passive 2 (Evo 1) | Passive 3 (Evo 2) |
|---|---|---|---|---|---|
| **Berserker** | Match 4+ orbs of the leader's affinity in one group → that affinity's characters ATK ×2 this turn | **Overrun** · change orbs · CD 7: every orb of the affinity this character beats becomes its own affinity | **Cleave**: 4+ own-affinity group → its ATK ×1.5 | **Skill Boost**: its skill starts each Act 1 extra turn charged | **Breaker**: 3×3 square of own affinity → ATK ×2.5 and ignores shields |
| **Titan** | Match Hearts → team takes 25% less damage from the next enemy hit. Always: team HP ×1.3 | **Bulwark** · shield · CD 8: team takes 50% less damage for the next 2 enemy attacks | **Counter**: when the team is hit, strikes back at that enemy for ATK ×1 | **Last Stand**: team HP below 30% → team takes 30% less damage | **Bind Resist**: 50% chance to ignore a bind |
| **Spectre** | ATK ×1.5 at 5 combos, up to ×2.5 at 7+ | **Execute** · finish · CD 8: tapped enemy takes ATK ×4; below 25% HP it dies instantly (bosses take ATK ×6 instead) | **Ambush** (cloak): its first attack each fight ATK ×2 | **Combo Boost**: ATK ×2 at 7+ combos | **Finisher**: ×1.5 damage vs enemies below 50% HP |
| **Biotech** | Match 3+ different affinities in a turn (Hearts don't count) → team ATK ×1.5 and heal 10% max HP | **Mend** · heal · CD 5: heal 30% max HP and turn 3 random orbs into Hearts | **Time Extend**: +1 s move time while on the team (5 → 6 s) | **Overflow Heal**: 5+ Hearts in one group heals 50% more | **Field Medic**: using Mend charges every ally's skill by 1 turn |

## Combat rules

- **Targeting:** tap an enemy to target it. Otherwise attacks hit the front (first alive) enemy.
- **Berserker** hits **all** enemies only when 4+ of its orbs are matched in a group; otherwise one. **Spectre** always hits one.
- **Most fights have 2+ enemies.** Mini-bosses and the main boss may be solo.
- **Active skills:** tap a glowing card before moving orbs; using a skill does not end the turn.
- **Cooldowns** tick only on turns where you make a match. Charge **carries over between fights within an Act**. The first fight of each Act starts **half-charged**.
- **Act 1 gimmick:** Shield ("Armoured") only — half damage until broken by a 4+ group or any active-skill hit.
- **Damage stacking** (Berserker leader + Cleave; Spectre leader + Combo Boost) stays as approved; Phase 3 measures real numbers and tunes if a boss falls in one turn.

## Team and roster

- **Starter:** always Fire Berserker. **Story unlocks:** Water Biotech and Wood Titan join right after the tutorial; Dark Spectre joins in Act 2.
- **Team:** 3 in Act 1, 4 from Act 2. Only slot 1 is leader. The same design may appear twice.
- **Roster:** cap 30, +5 slots for Credits. When full, Expand or Retire before creating a character.
- **Recruit and Essence** can give **any affinity** from Act 1. Characters from them can be swapped into the Act 1 team; the story trio is always guaranteed. No Recruit pulls in the tutorial.

## Economy (built in a later phase)

- **Credits:** earned on WIN (less on LOSE), daily / weekly quests, Act clear bonuses. Spent on roster slots, Training Cores, evolving. No real money in the proof.
- **Digital Essence:** each monster drops Essence for one specific character (regular: low chance of 1; lesser boss: 1–2 guaranteed; main boss: 3 guaranteed). 10 Essence → create that character in the Lab at Lv1 with only its active skill. Roster shows progress (e.g. 7/10).
- **Recruit screen:** spend Credits on random characters; pricier tiers give better odds; rare Keys guarantee a pull from a rare pool. Show the odds on screen.
- **Rarity (6):** Scrap, Alloy, Forged, Prime, Ascendant, Singularity. Rarity comes with each pull; any design can roll any rarity. Rarity = stats + a card frame / aura made in code.
- **Duplicates** allowed. **Retire** gives a base by rarity (Scrap 2, Alloy 5, Forged 15, Prime 30, Ascendant 60, Singularity 150 Training Cores) plus 50% of Training Cores invested. Confirm twice; lockable; can't retire a team member or your only character of an element or type. No fusion.

## Levelling and evolution

- Lv1–30, stats ~3×. Battle XP; full XP to everyone in the team on WIN; catch-up 1.5× (3–5 levels behind your highest) / 2× (6+ behind). Benched characters earn nothing.
- **XP pacing:** the story trio reaches **Lv10 around the Act 1 boss**, unlocking Passive 1.
- **Evolution 1 (Stage 2):** Lv15 + Credits → +10% stats, active CD −1, Passive 2. **Evolution 2 (Stage 3):** Lv30 + more Credits → +10% more, active CD −1, Passive 3. Level never resets; rarity never changes. Linear only — branching, Reincarnation, assists, latents get a data field, not code.

## Art

- You make every character. Each **character and each stage** is its own unique PNG (Leonardo), getting visibly more powerful per stage.
- Folders: `berserker/`, `titan/`, `spectre/`, `biotech/`. File name: `designname_affinity_stage.png` (e.g. `seraph_light_1.png`).
- The game loads exactly the file you name. If a file is ever missing, it falls back to recolouring another affinity of the same stage so nothing breaks — a safety net only.
- Until your art arrives, placeholders are drawn in code.
