# Bailey's friends: ultra-rare hunters (built 2026-11-19)

Art: `Orbspire/orbspire-art-organized/characters/Friend_Character_Art/Friend_<Name>.png`,
copied to `assets/characters/friend/friend_<name>.png` at 512 px (`tools/import_friend_art.gd`).
Data: `data/characters/friend_*.tres`. Numbers: `data/skills/skill_tuning.tres` (groups "Friend actives",
"Leader skills", "Passives"). Ids in `Catalog.FRIEND_IDS`.

## How you get them
- After ANY won fight (any Act, bosses too): **0.25% chance** (about 1 win in 400) that one friend joins.
  Tuning: `economy friend_drop_chance`.
- Prefers a friend you don't own yet. Joins even when the roster is full.
- Never in Recruit, the Lab or Essence.
- Always **Prime** rarity (fixed), Lv1. Stats are the normal ones for their type, so they're special, not overpowered.
- Result screen: "ULTRA RARE! JAKE (Prime) joined your team!"

## Kits
| Friend | Type | Active (CD) | Leader | Passives (Lv10 / Evo 1 / Evo 2) |
|---|---|---|---|---|
| JAKE | Light Berserker 320/95/10 | **Twin Comet** (7): hits EVERY enemy twice for ATK x1 each; 3 random orbs -> Light | **Hammerfall**: Light x1.15; x2 with 3+ separate Light groups | **Double Swing** (2+ Light groups: its ATK x1.3) / Cleave / Orb Enhance |
| JOHNNY | Dark Titan 470/78/26 | **Thunder Hammer** (8): ATK x2, the target skips its next attack (bosses: next attack -50% instead) | **Bedrock**: team HP x1.2, team takes 10% less, Dark x1.15 | **Storm Battery** (team hit: his skill charges 1, once per enemy turn) / Counter / Damage Resist |
| KHOEL | Fire Biotech 350/72/46 | **Overclock** (8): every OTHER hunter's skill charges 2 turns; heals 10% | **Neural Link**: 3+ different elements -> team x1.35 and every skill +1 charge | **Thruster Boost** (TEAM: +0.5 s to move orbs) / RCV Up / Heart Charge |
| LOGAN | Fire Spectre 230/110/8 | **Inferno Cleaver** (7): ATK x3, then BURN ATK x0.5 at the start of each of your next 3 turns | **Executioner**: Fire x2 on enemies below 15% HP; every enemy defeated charges every skill 1 | **Molten Edge** (his attacks ignore armour) / Finisher / Ambush |

## Balance (tests/friends_test.tscn, section FB)
Same test as every other character (Act 1, good play, element-neutral enemies):
| Team | Act 1 turns | Leads 2 humans of its element | Same team, human leader |
|---|---|---|---|
| 3x Jake | 15 | 14 | 15 |
| 3x Johnny | 16 | 15 | 14 |
| 3x Khoel | 17 | 16 | 15 |
| 3x Logan | 15 | 15 | 15 |

Toned down while building: Hammerfall was x1.2 / x1.5 at 2 groups (12 turns); Bedrock Dark x1.2 (13 turns led);
Executioner was x1.25 / x1.75 below 50% (12-13 turns) and became the finisher + skill-charge version.
