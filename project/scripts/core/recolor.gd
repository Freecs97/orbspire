class_name Recolor
extends RefCounted
## Recolours a character PNG in CODE (no new art files): used for the enemy
## colour versions (e.g. the Fire Ember Drone turned blue = Frost Drone, Water).
##
## Plain English: every pixel's hue is turned by `hue_deg` degrees (keeping its
## brightness), then scaled by `value`, then mixed with `tint` (tint alpha = how
## much). Transparent pixels are left alone. Results are cached by the caller.


static func apply(src: Texture2D, hue_deg: float, value := 1.0, tint := Color(1, 1, 1, 0)) -> Texture2D:
	if src == null:
		return null
	var img := src.get_image()
	if img == null:
		return src
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var data := img.get_data()
	# Hue rotation matrix (keeps luminance roughly the same). This matrix turns
	# the hue the other way round, so the angle is negated: +90 = orange -> green.
	var a := deg_to_rad(-hue_deg)
	var c := cos(a)
	var s := sin(a)
	var m := [
		0.299 + 0.701 * c + 0.168 * s, 0.587 - 0.587 * c + 0.330 * s, 0.114 - 0.114 * c - 0.497 * s,
		0.299 - 0.299 * c - 0.328 * s, 0.587 + 0.413 * c + 0.035 * s, 0.114 - 0.114 * c + 0.292 * s,
		0.299 - 0.300 * c + 1.250 * s, 0.587 - 0.588 * c - 1.050 * s, 0.114 + 0.886 * c - 0.203 * s,
	]
	var m0: float = m[0]
	var m1: float = m[1]
	var m2: float = m[2]
	var m3: float = m[3]
	var m4: float = m[4]
	var m5: float = m[5]
	var m6: float = m[6]
	var m7: float = m[7]
	var m8: float = m[8]
	var tr := tint.r * 255.0
	var tg := tint.g * 255.0
	var tb := tint.b * 255.0
	var ta := tint.a
	var n := data.size()
	var i := 0
	while i < n:
		if data[i + 3] > 0:
			var r := float(data[i])
			var g := float(data[i + 1])
			var b := float(data[i + 2])
			var r2 := (m0 * r + m1 * g + m2 * b) * value
			var g2 := (m3 * r + m4 * g + m5 * b) * value
			var b2 := (m6 * r + m7 * g + m8 * b) * value
			if ta > 0.0:
				# Multiply-tint, mixed in by tint alpha.
				r2 = lerpf(r2, r2 * tr / 255.0 * 1.25, ta)
				g2 = lerpf(g2, g2 * tg / 255.0 * 1.25, ta)
				b2 = lerpf(b2, b2 * tb / 255.0 * 1.25, ta)
			data[i] = clampi(int(r2), 0, 255)
			data[i + 1] = clampi(int(g2), 0, 255)
			data[i + 2] = clampi(int(b2), 0, 255)
		i += 4
	var out := Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)
	return ImageTexture.create_from_image(out)
