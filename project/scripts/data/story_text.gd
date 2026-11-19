class_name StoryText
extends RefCounted
## THE STORY, as Bailey approved it on 2026-11-19 (docs/story_full_draft.md, with
## his 3 fixes). Universe-only: no names, no player character, THE PROGENITORS.
##
## Plain English:
##   - Part A (the 10 Acts): intro (once), boss taunt, outro, 4-line codex. The game
##     reads these from data/acts/act_NN.tres; tools/apply_story.gd copies them there
##     from here (and tools/generate_acts.gd uses apply_to, so a rebuild keeps them).
##   - Part B (after Reaper-0): read from here by the universe map (CosmosMap).
## To change a line: edit it here, then run
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/apply_story.gd

## Part A. Act 1's intro, taunt and outro are Bailey's own lines (unchanged).
const ACTS := {
	1: {
		"intro": ["Orbspire was built to burn. Its furnace was spliced with a wolf to guard it.",
			"The wolf learned to guard something else instead."],
		"taunt": "You did not make me. But you made what made me.",
		"outro": "The furnace keeps burning. The colony keeps rationing heat. Killing the wolf did not fix Orbspire. It only proved the wolf could be killed.",
		"colony": "Orbspire was built around one furnace that heated every colony on this edge.",
		"rationed": "Heat, by the hour. Quarantined in Year 121.",
		"spliced": "A grey wolf and the furnace's plasma conduits, Year 82. On the record, the First Splice, made to guard the heat.",
		"abandoned": "When technomancy was outlawed, the furnace was sealed with the wolf inside. It kept guarding, for no one.",
	},
	2: {
		"intro": ["The Drowned Metro carried water to every colony on this edge.",
			"A serpent was spliced into its pumps to keep the water moving. When splicing was outlawed, its valves were shut from outside."],
		"taunt": "Every litre they rationed, I carried. Every single litre.",
		"outro": "The pump logs end where Orbspire's heat lines begin. The furnace kept these pipes from freezing: Emberfang-9 was never guarding the fire. It was guarding the water.\nOne valve the serpent never let close runs out of the colonies, to the Greenhouse domes. Something there is still drinking.",
		"colony": "A transit metro turned waterworks, when the colonies needed water more than trains.",
		"rationed": "Water, by the litre. The tunnels were sealed and quarantined in Year 121.",
		"spliced": "A blind pipe eel and the metro's flood-control drones, Year 97, to keep the water moving.",
		"abandoned": "When the valves were shut from outside, it read each one as a blockage and cleared it. Half the metro drowned.",
	},
	3: {
		"intro": ["The Greenhouse Ruins grew the food and medicine for the edge colonies.",
			"Its gardener was a machine given roots, so it could never leave. When the supply runs stopped, it kept growing."],
		"taunt": "I was told to make things grow. Nobody told me when to stop.",
		"outro": "The domes drank the metro's water for one crop: seedlings, tagged and numbered for splicing. Tidecoil-7 was not flooding the tunnels. It was watering the next singularities.\nThe collection runs stopped in Year 121. Someone up high had already written this place off.",
		"colony": "Glass domes of farmland and medicine gardens that fed the edge colonies.",
		"rationed": "Food and medicine, by the week. The supply runs stopped in Year 121.",
		"spliced": "A maintenance golem and a strangler fig, Year 103, so the domes would tend themselves and raise seedlings for splicing.",
		"abandoned": "Written off as lost. With no runs left to collect the harvest, it fed the domes the only thing it had: the colony.",
	},
	4: {
		"intro": ["The Upper Spires looked down on every colony, day and night.",
			"Dawnwing was spliced from an eagle and an orbital mirror, so the Progenitors would never stop seeing."],
		"taunt": "I have watched every colony since Orbspire was lit. I know which ones were meant to fail.",
		"outro": "Dawnwing wrote the Greenhouse off. Its reports were never warnings. Colony, splice, ration, outcome: they were results.\nEvery colony under the Spires was an experiment, and the Spires were where the Progenitors sat to watch.\nSo why outlaw the very thing they were still testing?",
		"colony": "Observation towers above the colonies, built to watch the weather, and then everything else.",
		"rationed": "Nothing. The Spires were never rationed: they were the ones taking notes.",
		"spliced": "A golden eagle and an orbital mirror array, Year 109, to light the colonies at night and see by that light.",
		"abandoned": "After Year 121 its reports were still read, and never answered. It has stared into its own light ever since.",
	},
	5: {
		"intro": ["The Void Quarter carried every message between the colonies.",
			"Voidscale was spliced to make messages disappear. After Year 121, it made the whole network disappear."],
		"taunt": "You hear nothing. That is how I know I am working.",
		"outro": "In Voidscale's silence: every reply the colonies ever sent up to the Spires. Not one arrived.\nOutlawing technomancy did not stop a single splice. It made speaking of one a crime, so no colony could ever compare what had been done to it.\nEvery colony's last message is stamped with the same hour: the hour the lights went out.",
		"colony": "Relay halls that carried every message between the colonies.",
		"rationed": "Contact. After Year 121, any message that mentioned a splice was a crime.",
		"spliced": "A cave serpent that hunts in silence and the Quarter's signal relays, Year 114, to make messages disappear.",
		"abandoned": "Its power was cut and the Quarter was erased from the maps. It still holds every message it swallowed, unread.",
	},
	6: {
		"intro": ["The Solar Farms turned starlight into power for half the edge.",
			"Ashen-01 was a repair drone spliced with a firebird, built to burn out and rise again, forever."],
		"taunt": "Burn it down. Build it up. Burn it down. I was not made to stop.",
		"outro": "Ashen-01's fires keep to a timetable. Every blackout that silenced the Quarter was scheduled and signed.\nThe rationing was never about running short. Less heat, less water, less light: it was the dial on the experiment, and Orbspire's cold was only the first setting.\nIts ash fell into the cooling sea of the Data Abyss. That sea touches other colonies.",
		"colony": "Fields of panels that turned starlight into power for half the edge.",
		"rationed": "Power, by the blackout. The blackouts were called maintenance.",
		"spliced": "A firebird from a colony zoo and the farms' repair drones, Year 118, so the farms would heal themselves.",
		"abandoned": "Left to burn on a timetable. Each time it rises, it forgets the last fire.",
	},
	7: {
		"intro": ["The Data Abyss kept every record the colonies ever made, cooled by a deep, dark sea.",
			"The Kraken Mainframe was spliced to guard those records. Now that sea reaches other colonies, and so do its arms."],
		"taunt": "Query: Orbspire. Deleted. Query: Drowned Metro. Deleted. I kept every one. I will keep you too.",
		"outro": "The Kraken kept every record it was ordered to erase. They show the quarantine failing for twenty years.\nSplices have been crossing from colony to colony through the shared sea, the supply runs and the pipes. Ashen-01's ash was only the latest.\nEvery crossing in the archive starts from the same sealed address: the Gene Labs.",
		"colony": "Server vaults under a deep sea that cooled them, holding every record the colonies made.",
		"rationed": "Memory. Records were deleted by order, one colony at a time.",
		"spliced": "A deep-sea kraken and the archive servers, Year 99, to cool them and guard them.",
		"abandoned": "Ordered to erase the colonies' records, it hid them inside itself instead, and was left in the dark with them.",
	},
	8: {
		"intro": ["The Gene Labs designed the splices and shipped them to the colonies.",
			"The labs were sealed in Year 121 with the staff inside. Something in there has been shipping ever since."],
		"taunt": "Wolf. Eel. Eagle. Serpent. Firebird. We are all of them. Do you see them in us?",
		"outro": "The Chimera is every splice the labs ever made, grown together in one body. It is what has been crossing the colonies.\nThe Kraken's archive was not tracking escapes. It was tracking deliveries: pieces of the Chimera, shipped out on every supply run since the labs were sealed.\nThe seals were set from outside, with the lab staff still inside. Someone signed that order.",
		"colony": "The laboratories that designed every splice and shipped them out to the colonies.",
		"rationed": "Nothing came in. Splices went out, on every supply run.",
		"spliced": "A lion, a stag and a forest, with a tissue sample from every splice the labs ever made, Year 116. A living catalogue.",
		"abandoned": "Sealed in with the staff in Year 121. It kept shipping itself out anyway.",
	},
	9: {
		"intro": ["The Core Sanctum is where the Progenitors rule, with ledgers, not soldiers.",
			"The Seraph Enforcer was built to carry out their law. Its quarantine is now closing in on the Sanctum itself."],
		"taunt": "Under the law of Year 121, all that technomancy has touched is erased. You have touched eight singularities. Sentence follows.",
		"outro": "The Seraph signed the order. Under its law, anyone who has touched technomancy is sealed away: the lab staff, the colonies, and now the Sanctum's own halls.\nThe ledgers cannot hold any more. The quarantine is closing in on the people who wrote it.\nOnly one world in the ledger is marked never to be judged: the Core.",
		"colony": "The seat of the Progenitors, who rule with ledgers, not soldiers.",
		"rationed": "Every colony's heat, water, light and silence was signed off here.",
		"spliced": "A cathedral guardian android and the Sanctum's ledger engine, made on the day the law was signed, Year 121.",
		"abandoned": "Left to run the ledgers alone when the Progenitors stopped coming to the Sanctum. It kept judging, all the way to their own doors.",
	},
	10: {
		"intro": ["The Core is the origin world, where technomancy began.",
			"Its records say it began in Year 82. Something here remembers an earlier year."],
		"taunt": "I was the first splice. I remember being made. I remember who made me.",
		"outro": "Reaper-0 was the first Progenitor ever spliced, in Year 61, to survive a world that was killing them.\nThen they spliced themselves. Then the colonies. Then, in Year 121, they outlawed it, so no one would ask where it began. The Seraph's law could never judge the Core: splices wrote it.\nReaper-0 was the first splice. It was not the last.",
		"colony": "The origin world: the Progenitors' first lab, the only world they never quarantined.",
		"rationed": "Nothing, ever. The Core was never quarantined, rationed or judged.",
		"spliced": "One of the Progenitors, with machine and shadow, Year 61. The real first splice, recorded nowhere but in itself.",
		"abandoned": "Left to guard the Core, so no one would reach the place where technomancy began.",
	},
}

## Bailey's fix 2: the Act 9 map preview line no longer says "the ban".
const INTEL_FIXES := {9: {2: "The Progenitors built it to enforce their law. It enforces it on them too."}}

## Bailey's fix 3: this timeline line appears (between Year 0-80 and Year 82)
## only after Reaper-0 falls.
const SECRET_TIMELINE_TITLE := "Year 61 · The real first splice"
const SECRET_TIMELINE_TEXT := "One of the Progenitors is spliced with machine and shadow, to survive a world that was killing them. It becomes Reaper-0."

## ---------------------------------------------------------------- Part B

## Once: the first time the universe map opens after Reaper-0 falls.
const FINAL_ARC_INTRO := [
	"Reaper-0 is gone. It was the first splice. It was not the last.",
	"Everything the Progenitors spliced after it, on themselves and on the colonies, is still out there, and the quarantine that held it is broken.",
	"Singularities are crossing from world to world and galaxy to galaxy, faster than any ledger can count.",
	"Reaper-0's death proved two things: the Progenitors lied, and a singularity can fall. Ten have fallen. The rest can too.",
	"No one else has brought down ten singularities and walked away. That is not destiny. It is a record.",
	"The job: go out through the universe, cleanse every world, defeat every singularity, until technomancy has nowhere left to spread.",
]

## Once per ring: the first time you enter a galaxy of that ring.
const RING_INTROS := {
	1: ["The spread is here already. These galaxies were quarantined first, and the quarantine failed first.",
		"They traded with Orbspire's edge for a hundred years. The splices followed the trade routes out."],
	2: ["Farther out, the splices are older, stranger, and less human. The Progenitors never reached this far with their ledgers.",
		"Here, singularities have had decades with no one counting them."],
	3: ["The far edge. This is where technomancy goes when no one is watching.",
		"Whatever runs here has been running the longest. If it is not cleansed here, it will come back."],
}

## Once per galaxy (2-10): the first time you enter it.
const GALAXY_INTROS := {
	2: ["The Tide Galaxy mined ice and shipped water to a hundred colonies.",
		"Its splices were built to move water. Now they move themselves, and take the water with them."],
	3: ["The Thorn Galaxy was farmland: whole worlds terraformed to feed the colonies.",
		"The splices that tended the crops have grown past the fields and into the cities."],
	4: ["The Dawn Galaxy built the mirrors and beacons that lit the dark colonies.",
		"Its splices still shine, and they still watch, though no one reads their reports."],
	5: ["The Void Galaxy was a relay chain, carrying signals across the empty gap between the rings.",
		"Its splices learned to live in the silence between messages, and to make more of it."],
	6: ["The Ember Galaxy forged the hulls and engines that carried humanity outward.",
		"Its splices were made to work the furnaces. They never stopped feeding them."],
	7: ["The Frost Galaxy stored what the colonies could not use yet: seeds, embryos, frozen samples.",
		"Something thawed. The samples are not frozen any more, and they are not samples."],
	8: ["The Storm Galaxy powered the outer rings, harvesting lightning from its gas giants.",
		"Its splices drink the storms now, and the storms have grown."],
	9: ["The Bloom Galaxy was named for the years when splices first began to evolve on their own.",
		"Whatever bloomed here was never planted, and no one has ever counted it."],
	10: ["The Core Galaxy was meant to be a second Core, far from anyone who might ask questions.",
		"What the Progenitors began there was never finished. It has been finishing itself."],
}

## Once: the first time a world outside the 10 Acts is cleansed.
const CLEANSE_POPUP_TITLE := "WORLD CLEANSED"
const CLEANSE_POPUP := [
	"Its Stage 5 boss is down. Technomancy can no longer spread from this world.",
	"Worlds Cleansed and Singularities Defeated are your record: proof the universe is getting cleaner, one world at a time.",
	"You can come back for Essence and Recruits. It stays cleansed, and what was here does not return.",
]

## The Codex: CLEANSING page (readable any time). Bailey's fix 1: "exploration".
const CLEANSING_CODEX := [
	"A world is cleansed when its Stage 5 boss falls. The splice nest at its heart is gone, and technomancy cannot spread from that world any more.",
	"Each exploration solar system's farthest world hides that system's singularity. There are 107 in the universe; the 10 Act bosses are the first.",
	"Worlds Cleansed (X / 744) and Singularities Defeated (X / 107) are a lifetime record. They never go down.",
	"A cleansed world can be replayed for Essence and Recruits. Its counter stays, and its singularity does not come back.",
]

## Once: when every world is cleansed and all 107 singularities are defeated.
const FINAL_OUTRO := [
	"Every world is cleansed. Every singularity is down. There is nowhere left for technomancy to hide.",
	"The colonies have heat, water and light that no ledger rations, and messages that arrive.",
	"The Progenitors are still out there. They are still the first splices. They are not forgiven and they are not defeated, but now every world knows what they are.",
	"It was never going to be one fight. It took hundreds of worlds, cleansed one at a time, until the spread had nowhere left to go.",
	"The universe is open. Keep exploring it.",
]


## The cleansing codex with the real totals filled in.
static func cleansing_codex() -> Array:
	var out: Array = []
	for line in CLEANSING_CODEX:
		out.append(String(line).replace("744", str(Cosmos.total_worlds())).replace("107", str(Cosmos.total_singularities())))
	return out


## Writes Act n's approved story onto its ActData (intro, taunt, outro, codex,
## intel fixes) and gives longer beats a little more time on screen.
static func apply_to(act: ActData, n: int) -> void:
	var s: Dictionary = ACTS[n]
	var intro: Array[String] = []
	for line in s["intro"]:
		intro.append(line)
	act.intro_lines = intro
	act.boss_taunt = s["taunt"]
	act.outro_line = s["outro"]
	act.codex_colony = s["colony"]
	act.codex_rationed = s["rationed"]
	act.codex_spliced_from = s["spliced"]
	act.codex_abandoned = s["abandoned"]
	act.intro_seconds = clampf(roundf(_words(" ".join(PackedStringArray(intro))) / 3.5), 10.0, 14.0)
	act.taunt_seconds = clampf(roundf(_words(act.boss_taunt) / 3.0), 5.0, 9.0)
	act.outro_seconds = clampf(roundf(_words(act.outro_line) / 3.5), 10.0, 18.0)
	if INTEL_FIXES.has(n):
		var intel: Array[String] = act.intel_lines.duplicate()
		for i in INTEL_FIXES[n]:
			intel[i] = INTEL_FIXES[n][i]
		act.intel_lines = intel


static func _words(text: String) -> float:
	return float(text.split(" ", false).size())
