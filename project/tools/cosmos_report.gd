extends SceneTree
## Developer tool: prints the generation table (per galaxy: systems, worlds per
## system, level band, affinity split, totals), the XP table Lv31-120 and a
## sample of tuned exploration fights. Writes tools/cosmos_report.txt.
## Run:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/cosmos_report.gd

const EL := {0: "Fire", 1: "Water", 2: "Wood", 5: "Light", 6: "Dark"}


func _init() -> void:
	var t0 := Time.get_ticks_msec()
	var out := PackedStringArray()
	out.append("ORBSPIRE UNIVERSE  ·  seed %d" % Cosmos.SEED)
	out.append("Totals: %d galaxies, 100 solar systems, %d worlds, %d singularities, %d wardens" % [
		10, Cosmos.total_worlds(), Cosmos.total_singularities(), Cosmos.total_wardens()])
	out.append("")
	for gal in Cosmos.galaxies():
		var g: int = gal["g"]
		var worlds := 0
		var split := {}
		var pure := 0
		var lines := PackedStringArray()
		for sys in Cosmos.systems(g):
			var n: int = sys["n_worlds"]
			worlds += n
			split[sys["element"]] = int(split.get(sys["element"], 0)) + 1
			var wsplit := {}
			for w in Cosmos.worlds(g, int(sys["s"])):
				wsplit[EL[int(w["element"])]] = int(wsplit.get(EL[int(w["element"])], 0)) + 1
				if w["pure"]:
					pure += 1
			lines.append("    System %2d  %-18s ring %d  Lv%d-%d  %2d worlds  singularity: %-5s  worlds: %s%s" % [
				sys["s"], sys["name"], sys["ring"], sys["band"][0], sys["band"][1], n, EL[int(sys["element"])],
				_split_text(wsplit), "  (STORY)" if sys["story"] else ""])
		out.append("GALAXY %d  %s  ring %d  Lv%d-%d  ·  %d worlds  ·  systems by singularity: %s  ·  pure worlds: %d" % [
			g, gal["name"], gal["ring"], gal["band"][0], gal["band"][1], worlds, _split_text(_named(split)), pure])
		out.append_array(lines)
		out.append("")
	var p: ProgressionTuning = load("res://data/progression.tres")
	out.append("XP TABLE  (XP to reach the next level; total from Lv30)")
	var total := 0
	for l in range(30, 120):
		total += p.xp_to_next(l)
		out.append("  Lv%d -> %d: %d   (total since Lv30: %d)   stats x%.3f" % [l, l + 1, p.xp_to_next(l), total, p.stat_mult(l + 1)])
	out.append("")
	out.append("SAMPLE EXPLORATION FIGHTS (tuned to the typical team at the Recommended Level)")
	for key in ["1-4-1", "2-1-1", "2-8-1", "5-5-3", "10-9-1"]:
		var w := Cosmos.world_by_key(key)
		var a := Cosmos.build_world(int(w["g"]), int(w["s"]), int(w["w"]))
		out.append("  %s %s  Lv%d  %s%s" % [key, a.colony_name, a.rec_level, EL[a.element], "  PURE" if a.pure else ""])
		var team := Cosmos.ref_team(a.rec_level)
		for f in a.fights:
			var names := PackedStringArray()
			for e in f.enemies:
				names.append("%s (%s) HP %d ATK %d" % [e.display_name, EL[int(e.element)], e.max_hp, e.atk])
			out.append("    %s: %s  ·  good turns %d  ·  XP %d" % [f.display_name, ", ".join(names), BalanceSim.turns_to_win(f.enemies, team, "GOOD"), f.xp])
	out.append("")
	out.append("Made in %d ms" % (Time.get_ticks_msec() - t0))
	var text := "\n".join(out)
	var file := FileAccess.open("res://tools/cosmos_report.txt", FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print(text.substr(0, 6000))
	quit()


func _named(split: Dictionary) -> Dictionary:
	var out := {}
	for k in split:
		out[EL[int(k)]] = split[k]
	return out


func _split_text(split: Dictionary) -> String:
	var parts := PackedStringArray()
	for name in ["Fire", "Water", "Wood", "Light", "Dark"]:
		parts.append("%s %d" % [name, int(split.get(name, 0))])
	return " / ".join(parts)
