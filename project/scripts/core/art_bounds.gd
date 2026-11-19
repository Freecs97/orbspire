class_name ArtBounds
extends RefCounted
## Measures a character PNG (cached per texture):
##   opaque_rect(tex)  - the box around the visible (non-transparent) pixels
##   head_region(tex)  - a square around the head / face, cropped from the art
##                        itself (Stage 4 head-only party plates; no new images)
##
## Plain English for the head: take the visible body, look at its top part,
## find the middle of it (the median, so a wing or weapon on one side doesn't
## pull it over), go down from the very top of the figure at that point, and
## cut a square about a quarter of the body's height. HEAD_OVERRIDE fixes the
## few pictures where a raised weapon or hair confuses that guess.

const STEP := 2                ## scan every 2nd pixel (fast enough for 512 x 512)
const HEAD_SIZE := 0.27        ## head square = this share of the visible height
## art file name -> head square as fractions of the image (x, y, size).
## (Drones / wisps have a glowing core instead of a head: frame the core.)
## Colour versions use their original's file name, so they share these.
const HEAD_OVERRIDE := {
	"enemy_fire_ember_drone": [0.31, 0.19, 0.39],
	"enemy_light_solar_drone": [0.31, 0.195, 0.39],
	"enemy_light_prism_wisp": [0.33, 0.17, 0.35],
	"enemy_dark_void_imp": [0.31, 0.06, 0.33],
	"friend_khoel": [0.31, 0.1, 0.38],   # a giant face in a pod: frame the face
}

static var _opaque := {}
static var _head := {}


static func _key(tex: Texture2D) -> String:
	return tex.resource_path if tex.resource_path != "" else str(tex.get_instance_id())


static func _image(tex: Texture2D) -> Image:
	var img := tex.get_image()
	if img and img.is_compressed():
		img = img.duplicate()
		img.decompress()
	return img


## Box (in image pixels) around the visible pixels.
static func opaque_rect(tex: Texture2D) -> Rect2:
	if tex == null:
		return Rect2()
	var k := _key(tex)
	if _opaque.has(k):
		return _opaque[k]
	var img := _image(tex)
	var w := img.get_width()
	var h := img.get_height()
	var x0 := w
	var y0 := h
	var x1 := -1
	var y1 := -1
	for y in range(0, h, STEP):
		for x in range(0, w, STEP):
			if img.get_pixel(x, y).a > 0.5:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
				y0 = mini(y0, y)
				y1 = maxi(y1, y)
	var r := Rect2(0, 0, w, h) if x1 < 0 else Rect2(x0, y0, x1 - x0 + STEP, y1 - y0 + STEP)
	_opaque[k] = r
	return r


## Square (in image pixels) around the head / face.
static func head_region(tex: Texture2D) -> Rect2:
	if tex == null:
		return Rect2()
	var k := _key(tex)
	if _head.has(k):
		return _head[k]
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	# Recoloured textures carry their original's file name in resource_name.
	var file := tex.resource_path.get_file().get_basename() if tex.resource_path != "" else tex.resource_name
	var r: Rect2
	if HEAD_OVERRIDE.has(file):
		var o: Array = HEAD_OVERRIDE[file]
		r = Rect2(o[0] * w, o[1] * h, o[2] * w, o[2] * w)
	else:
		var img := _image(tex)
		var box := opaque_rect(tex)
		var body_h := box.size.y
		# Middle of the top 30% of the body (median x of visible pixels, central columns only).
		var xs: Array[int] = []
		var band_end := int(box.position.y + body_h * 0.3)
		for y in range(int(box.position.y), band_end, STEP):
			for x in range(int(w * 0.2), int(w * 0.8), STEP):
				if img.get_pixel(x, y).a > 0.5:
					xs.append(x)
		var cx := w * 0.5
		if not xs.is_empty():
			xs.sort()
			cx = float(xs[xs.size() / 2])
		# Top of the figure near that middle.
		var top := box.position.y
		var near := int(w * 0.05)
		for y in range(int(box.position.y), band_end, STEP):
			var hit := false
			for x in range(int(cx) - near, int(cx) + near, STEP):
				if x >= 0 and x < int(w) and img.get_pixel(x, y).a > 0.5:
					hit = true
					break
			if hit:
				top = y
				break
		var side := maxf(body_h * HEAD_SIZE, w * 0.14)
		r = Rect2(cx - side * 0.5, top - body_h * 0.02, side, side)
	# Keep it inside the picture.
	r.position.x = clampf(r.position.x, 0.0, w - r.size.x)
	r.position.y = clampf(r.position.y, 0.0, h - r.size.y)
	_head[k] = r
	return r
