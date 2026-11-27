extends Node
# Placeholder pixel art generated in code (autoload "PixelArt").
# Keeps the slice free of external assets. When real sprite sheets arrive, replace the
# getters here; scenes only ever ask PixelArt for a texture by name.
# Scale: 32x32 tiles, 1 art pixel = 1 game pixel. Avatar is 32x48.

const OUT := Color("1e1520")
var _cache: Dictionary = {}

# ---------------------------------------------------------------- helpers

func _new(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)

func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var rect := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if rect.size.x > 0 and rect.size.y > 0:
		img.fill_rect(rect, c)

func _p(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

func _ell(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_p(img, x, y, c)

func _outline(img: Image, c: Color = OUT) -> void:
	var src := img.duplicate() as Image
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				continue
			var hit := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and src.get_pixel(nx, ny).a > 0.5:
					hit = true
					break
			if hit:
				img.set_pixel(x, y, c)

func _tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)

func _cached(key: String, maker: Callable) -> Texture2D:
	if not _cache.has(key):
		_cache[key] = maker.call()
	return _cache[key]

func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r

func _vary(c: Color, rng: RandomNumberGenerator, amt: float) -> Color:
	var v := rng.randf_range(-amt, amt)
	return Color(clampf(c.r + v, 0, 1), clampf(c.g + v, 0, 1), clampf(c.b + v * 0.8, 0, 1), c.a)

# Builds one big texture from a tile picker: picker(tx, ty) -> Image (32x32) or null.
func compose_tiles(key: String, tw: int, th: int, picker: Callable) -> Texture2D:
	return _cached(key, func():
		var img := _new(tw * 32, th * 32)
		for ty in th:
			for tx in tw:
				var t = picker.call(tx, ty)
				if t != null:
					img.blit_rect(t, Rect2i(0, 0, 32, 32), Vector2i(tx * 32, ty * 32))
		return _tex(img))

# ---------------------------------------------------------------- tiles (Images)

func wood_floor_img(v: int) -> Image:
	var key := "img_wood_%d" % v
	if _cache.has(key):
		return _cache[key]
	var img := _new(32, 32)
	var rng := _rng(100 + v)
	for row in 4:
		var y0 := row * 8
		var base := _vary(Color("8b5a35"), rng, 0.04)
		_r(img, 0, y0, 32, 8, base)
		_r(img, 0, y0, 32, 1, base.lightened(0.15))
		_r(img, 0, y0 + 7, 32, 1, Color("4e301b"))
		if (row + v) % 3 == 0:
			var seam := (row * 13 + v * 7 + 5) % 32
			_r(img, seam, y0, 1, 7, Color("4e301b"))
			_r(img, seam + 1, y0, 1, 7, base.lightened(0.08))
		for i in 7:
			var gx := rng.randi_range(0, 31)
			var gy := y0 + rng.randi_range(2, 5)
			_r(img, gx, gy, rng.randi_range(2, 5), 1, base.darkened(0.12))
	_cache[key] = img
	return img

func grass_img(v: int) -> Image:
	var key := "img_grass_%d" % v
	if _cache.has(key):
		return _cache[key]
	var img := _new(32, 32)
	var rng := _rng(300 + v)
	img.fill(Color("5f9a48"))
	for i in 26:
		var x := rng.randi_range(0, 31)
		var y := rng.randi_range(0, 31)
		var dark := rng.randf() < 0.55
		var c := Color("4d833b") if dark else Color("74b058")
		_p(img, x, y, c)
		_p(img, x, y - 1, c)
	if v == 3:
		for i in 3:
			var fx := rng.randi_range(4, 27)
			var fy := rng.randi_range(4, 27)
			var fc: Color = [Color("f4e27a"), Color("f2f0ea"), Color("e98bb0")][i % 3]
			_p(img, fx, fy, fc); _p(img, fx + 1, fy, fc); _p(img, fx, fy + 1, fc); _p(img, fx + 1, fy + 1, fc)
			_p(img, fx, fy + 2, Color("3f6f30"))
	_cache[key] = img
	return img

func path_img(v: int) -> Image:
	var key := "img_path_%d" % v
	if _cache.has(key):
		return _cache[key]
	var img := _new(32, 32)
	var rng := _rng(500 + v)
	img.fill(Color("c9a873"))
	for i in 30:
		_p(img, rng.randi_range(0, 31), rng.randi_range(0, 31), Color("b39360") if rng.randf() < 0.6 else Color("dcc08e"))
	for i in 3:
		var sx := rng.randi_range(2, 27)
		var sy := rng.randi_range(2, 27)
		_r(img, sx, sy, 3, 2, Color("a68a5f"))
		_r(img, sx, sy, 3, 1, Color("d9c7a3"))
	_cache[key] = img
	return img

# ---------------------------------------------------------------- room pieces

func back_wall(width_tiles: int) -> Texture2D:
	return _cached("wall_%d" % width_tiles, func():
		var w := width_tiles * 32
		var img := _new(w, 64)
		img.fill(Color("5b4a6e"))
		for x in range(0, w, 8):
			_r(img, x, 4, 2, 34, Color("63527a"))
		for y in range(8, 36, 8):
			for x in range(4, w, 8):
				var o := 4 if (y / 8) % 2 == 0 else 0
				_p(img, x + o, y, Color("7a6896"))
				_p(img, x + o - 1, y + 1, Color("6d5c88")); _p(img, x + o + 1, y + 1, Color("6d5c88"))
				_p(img, x + o, y + 2, Color("7a6896"))
		_r(img, 0, 0, w, 4, Color("4a2e1c")); _r(img, 0, 3, w, 1, Color("6b4428"))
		_r(img, 0, 37, w, 3, Color("7a4e2d")); _r(img, 0, 37, w, 1, Color("a06c40"))
		_r(img, 0, 40, w, 18, Color("6b4428"))
		for x in range(4, w - 20, 24):
			_r(img, x, 43, 20, 12, Color("5c3a22"))
			_r(img, x + 1, 44, 18, 1, Color("7a4e2d"))
			_r(img, x + 1, 54, 18, 1, Color("4a2e1c"))
		_r(img, 0, 58, w, 6, Color("3a2416")); _r(img, 0, 58, w, 1, Color("5c3a22"))
		return _tex(img))

func window_tex() -> Texture2D:
	return _cached("window", func():
		var img := _new(30, 30)
		for y in 30:
			var t := y / 30.0
			_r(img, 0, y, 30, 1, Color("1b2647").lerp(Color("35508a"), t))
		var rng := _rng(77)
		for i in 9:
			_p(img, rng.randi_range(3, 26), rng.randi_range(3, 20), Color("f5f1d0"))
		_ell(img, 21, 8, 3.5, 3.5, Color("f3ecc4"))
		_ell(img, 22.5, 7, 3, 3, Color("27386a"))
		_r(img, 14, 0, 2, 30, Color("6b4428")); _r(img, 0, 14, 30, 2, Color("6b4428"))
		var framed := _new(36, 38)
		_r(framed, 0, 0, 36, 36, Color("6b4428"))
		_r(framed, 1, 1, 34, 1, Color("a06c40"))
		framed.blit_rect(img, Rect2i(0, 0, 30, 30), Vector2i(3, 3))
		_r(framed, 0, 34, 36, 4, Color("8a5a35")); _r(framed, 0, 34, 36, 1, Color("b07a48"))
		_outline(framed)
		return _tex(framed))

func rug_tex(w: int, h: int) -> Texture2D:
	return _cached("rug_%d_%d" % [w, h], func():
		var img := _new(w, h)
		img.fill(Color("8a2f2f"))
		for y in h:
			for x in w:
				if (x + y) % 4 == 0:
					_p(img, x, y, Color("7a2828"))
		_r(img, 3, 3, w - 6, 2, Color("d4a24c")); _r(img, 3, h - 5, w - 6, 2, Color("d4a24c"))
		_r(img, 3, 3, 2, h - 6, Color("d4a24c")); _r(img, w - 5, 3, 2, h - 6, Color("d4a24c"))
		_r(img, 7, 7, w - 14, 1, Color("b07a38")); _r(img, 7, h - 8, w - 14, 1, Color("b07a38"))
		_r(img, 7, 7, 1, h - 14, Color("b07a38")); _r(img, w - 8, 7, 1, h - 14, Color("b07a38"))
		_ell(img, w / 2.0, h / 2.0, w * 0.22, h * 0.24, Color("d4a24c"))
		_ell(img, w / 2.0, h / 2.0, w * 0.18, h * 0.19, Color("5e2a4a"))
		_ell(img, w / 2.0, h / 2.0, w * 0.07, h * 0.08, Color("e8c070"))
		for x in range(0, w, 3):
			_p(img, x, 0, Color("e8d4a8")); _p(img, x, h - 1, Color("e8d4a8"))
		return _tex(img))

func sofa_tex() -> Texture2D:
	return _cached("sofa", func():
		var img := _new(76, 46)
		var base := Color("5f8a6a"); var dark := Color("486b52"); var lite := Color("79a884")
		_r(img, 6, 2, 64, 20, base); _r(img, 6, 2, 64, 2, lite)
		for x in [26, 48]:
			_r(img, x, 6, 1, 14, dark)
		_r(img, 8, 20, 60, 16, lite.lerp(base, 0.4)); _r(img, 8, 20, 60, 1, lite)
		_r(img, 37, 21, 1, 15, dark)
		_r(img, 8, 34, 60, 3, dark)
		_r(img, 0, 8, 10, 32, base); _r(img, 0, 8, 10, 2, lite); _r(img, 0, 36, 10, 4, dark)
		_r(img, 66, 8, 10, 32, base); _r(img, 66, 8, 10, 2, lite); _r(img, 66, 36, 10, 4, dark)
		_r(img, 3, 40, 4, 4, Color("3a2416")); _r(img, 69, 40, 4, 4, Color("3a2416"))
		_r(img, 14, 10, 12, 9, Color("e0b860")); _r(img, 14, 10, 12, 1, Color("f2d488"))
		_outline(img)
		return _tex(img))

func lamp_tex() -> Texture2D:
	return _cached("lamp", func():
		var img := _new(20, 56)
		_ell(img, 10, 52, 7, 3, Color("3a2416"))
		_r(img, 9, 16, 2, 36, Color("6b4428")); _r(img, 9, 16, 1, 36, Color("8a5a35"))
		for i in 15:
			var hw := 4 + i * 0.4
			_r(img, int(10 - hw), 2 + i, int(hw * 2), 1, Color("f2c46b").lerp(Color("e09a40"), i / 15.0))
		_r(img, 5, 2, 10, 1, Color("fff0c0"))
		_outline(img)
		return _tex(img))

func plant_tex() -> Texture2D:
	return _cached("plant", func():
		var img := _new(28, 44)
		for i in 14:
			var hw := 8 - i * 0.2
			_r(img, int(14 - hw), 30 + i, int(hw * 2), 1, Color("c0643a").darkened(i / 40.0))
		_r(img, 5, 29, 18, 2, Color("d97a4a"))
		var leaves := [[14, 14, 7, 9], [7, 20, 6, 7], [21, 19, 6, 7], [10, 9, 5, 6], [18, 8, 5, 6], [14, 24, 8, 5]]
		var cols := [Color("3f7a3a"), Color("4f9447"), Color("5fab52")]
		var k := 0
		for l in leaves:
			_ell(img, l[0], l[1], l[2], l[3], cols[k % 3])
			k += 1
		for l in leaves:
			_p(img, l[0] - 2, l[1] - 3, Color("8fd07a"))
		_outline(img)
		return _tex(img))

func bookshelf_tex() -> Texture2D:
	return _cached("bookshelf", func():
		var img := _new(44, 66)
		_r(img, 0, 0, 44, 66, Color("5c3a22")); _r(img, 0, 0, 44, 2, Color("7a4e2d"))
		var rng := _rng(9)
		var cols := [Color("a8443c"), Color("3f6e9a"), Color("d4a24c"), Color("4f8a5a"), Color("7a4f8a"), Color("c9c0a8")]
		for s in 3:
			var y0 := 4 + s * 20
			_r(img, 3, y0, 38, 16, Color("2e1c12"))
			var x := 4
			while x < 39:
				var bw := rng.randi_range(2, 4)
				var bh := rng.randi_range(10, 15)
				var c: Color = cols[rng.randi_range(0, cols.size() - 1)]
				_r(img, x, y0 + 16 - bh, bw, bh, c)
				_r(img, x, y0 + 16 - bh, 1, bh, c.lightened(0.2))
				_p(img, x, y0 + 16 - bh + 3, c.lightened(0.4))
				x += bw + (1 if rng.randf() < 0.2 else 0)
			_r(img, 2, y0 + 16, 40, 2, Color("7a4e2d"))
		_outline(img)
		return _tex(img))

func chair_tex() -> Texture2D:
	return _cached("chair", func():
		var img := _new(24, 36)
		var wood := Color("9a6a3e"); var dark := Color("6b4428")
		_r(img, 3, 1, 18, 3, wood); _r(img, 3, 1, 18, 1, wood.lightened(0.2))
		for x in [5, 11, 17]:
			_r(img, x, 4, 2, 12, dark if x == 11 else wood)
		_r(img, 2, 16, 20, 7, wood); _r(img, 2, 16, 20, 1, wood.lightened(0.25)); _r(img, 2, 22, 20, 1, dark)
		_r(img, 9, 18, 5, 1, dark)
		_r(img, 3, 23, 2, 11, dark); _r(img, 19, 23, 2, 10, dark)
		_r(img, 18, 33, 2, 2, dark)
		_r(img, 7, 23, 2, 9, wood.darkened(0.3)); _r(img, 15, 23, 2, 9, wood.darkened(0.3))
		_outline(img)
		return _tex(img))

func sconce_tex() -> Texture2D:
	return _cached("sconce", func():
		var img := _new(10, 14)
		_r(img, 4, 8, 2, 6, Color("6b4428"))
		_ell(img, 5, 5, 4, 5, Color("f7d27a"))
		_ell(img, 5, 4, 2, 2, Color("fff4d0"))
		_outline(img)
		return _tex(img))

func portal_frame(frame: int) -> Texture2D:
	return _cached("portal_%d" % frame, func():
		var w := 48; var h := 64
		var img := _new(w, h)
		var cx := 24.0; var cy := 30.0; var rx := 16.0; var ry := 22.0
		var pal := [Color("2a1650"), Color("4b2a8a"), Color("7b4fd0"), Color("4fc3e8"), Color("b8f0ff"), Color("7b4fd0")]
		for y in h:
			for x in w:
				var dx := (x + 0.5 - cx) / rx
				var dy := (y + 0.5 - cy) / ry
				var d := sqrt(dx * dx + dy * dy)
				if d <= 1.0:
					var ang := atan2(dy, dx)
					var band := fposmod(ang * 1.6 / PI + d * 3.0 - frame * 0.5, 3.0)
					var idx := int(band * 2.0) % pal.size()
					var c: Color = pal[idx]
					c = c.lerp(Color("1a0e30"), clampf((d - 0.85) * 5.0, 0, 1))
					if d < 0.18:
						c = Color("e8fbff")
					_p(img, x, y, c)
		for y in range(4, 58):
			var dy := (y + 0.5 - cy) / (ry + 4)
			if absf(dy) > 1.0:
				continue
			var ex := (rx + 4) * sqrt(1.0 - dy * dy)
			for t in 3:
				_p(img, int(cx - ex) + t, y, Color("8a8478").darkened(t * 0.12))
				_p(img, int(cx + ex) - t, y, Color("8a8478").darkened(t * 0.12))
		_r(img, 4, 54, 40, 8, Color("7a7468")); _r(img, 4, 54, 40, 2, Color("a8a294")); _r(img, 4, 60, 40, 2, Color("5a554c"))
		for x in range(8, 40, 8):
			_p(img, x, 57, Color("4fc3e8"))
		_outline(img)
		return _tex(img))

# ---------------------------------------------------------------- pond scene

func tree_tex(v: int) -> Texture2D:
	return _cached("tree_%d" % v, func():
		var img := _new(64, 86)
		var rng := _rng(40 + v)
		_ell(img, 32, 81, 20, 5, Color(0, 0, 0, 0.0))
		_r(img, 27, 52, 10, 30, Color("6b4428")); _r(img, 27, 52, 3, 30, Color("8a5a35")); _r(img, 35, 52, 2, 30, Color("4a2e1c"))
		_r(img, 23, 78, 18, 4, Color("6b4428"))
		var greens := [Color("2f5f2c"), Color("3f7a3a"), Color("4f9447"), Color("66ad57")]
		var blobs := []
		for i in 9:
			blobs.append([rng.randf_range(14, 50), rng.randf_range(14, 48), rng.randf_range(10, 15)])
		for b in blobs:
			_ell(img, b[0], b[1] + 3, b[2], b[2] * 0.9, greens[0])
		for b in blobs:
			_ell(img, b[0], b[1], b[2] - 1.5, b[2] * 0.85 - 1.5, greens[1])
		for b in blobs:
			_ell(img, b[0] - 2, b[1] - 3, b[2] * 0.55, b[2] * 0.45, greens[2])
		for b in blobs:
			_ell(img, b[0] - 4, b[1] - 5, b[2] * 0.22, b[2] * 0.18, greens[3])
		_outline(img)
		return _tex(img))

func lantern_tex() -> Texture2D:
	return _cached("lantern", func():
		var img := _new(14, 52)
		_r(img, 6, 14, 3, 36, Color("3a3430")); _r(img, 6, 14, 1, 36, Color("5a524a"))
		_r(img, 3, 48, 9, 3, Color("3a3430"))
		_r(img, 2, 2, 11, 2, Color("3a3430"))
		_r(img, 3, 4, 9, 9, Color("f7c860")); _r(img, 5, 6, 5, 5, Color("fff0b8"))
		_r(img, 7, 4, 1, 9, Color("3a3430"))
		_r(img, 2, 13, 11, 2, Color("3a3430"))
		_outline(img)
		return _tex(img))

func bench_tex() -> Texture2D:
	return _cached("bench", func():
		var img := _new(52, 30)
		var wood := Color("a8743f")
		for i in 3:
			_r(img, 2, 2 + i * 4, 48, 3, wood.darkened(i * 0.05)); _r(img, 2, 2 + i * 4, 48, 1, wood.lightened(0.2))
		_r(img, 0, 15, 52, 6, wood); _r(img, 0, 15, 52, 1, wood.lightened(0.25)); _r(img, 0, 20, 52, 1, wood.darkened(0.3))
		_r(img, 4, 21, 3, 8, Color("3a3430")); _r(img, 45, 21, 3, 8, Color("3a3430"))
		_outline(img)
		return _tex(img))

func reeds_tex() -> Texture2D:
	return _cached("reeds", func():
		var img := _new(20, 26)
		var rng := _rng(5)
		for i in 7:
			var x := 2 + i * 2 + rng.randi_range(0, 1)
			var top := rng.randi_range(2, 10)
			_r(img, x, top, 1, 26 - top, Color("5f8a3a"))
			if i % 2 == 0:
				_r(img, x, top, 2, 5, Color("7a4e2d"))
		_outline(img, Color("2a3a1e"))
		return _tex(img))

# The pond: a rounded basin with a sandy rim, depth shading, lily pads and a shimmer
# that animates over 3 frames. inside(px, py) decides the shape.
func pond_frame(key: String, w: int, h: int, inside: Callable, frame: int) -> Texture2D:
	return _cached("%s_%d" % [key, frame], func():
		var img := _new(w, h)
		var rng := _rng(900)
		for y in h:
			for x in w:
				var d: float = inside.call(x + 0.5, y + 0.5)  # >0 inside water, value ~ px from edge
				if d > 6.0:
					var depth := clampf((d - 6.0) / 40.0, 0.0, 1.0)
					var c := Color("5eb0d0").lerp(Color("2a6593"), depth)
					if (x + y * 3 + frame * 5) % 23 == 0 and d > 10.0:
						c = c.lightened(0.18)
					_p(img, x, y, c)
				elif d > 3.0:
					_p(img, x, y, Color("8fd0e0"))
				elif d > -4.0:
					var sc := Color("d9c08a") if d > -2.0 else Color("b89c66")
					if rng.randf() < 0.12:
						sc = sc.darkened(0.1)
					_p(img, x, y, sc)
		# shimmer streaks
		var srng := _rng(1000 + frame)
		for i in 16:
			var sx := srng.randi_range(0, w - 8)
			var sy := srng.randi_range(0, h - 1)
			if inside.call(sx + 0.5, sy + 0.5) > 12.0 and inside.call(sx + 6.5, sy + 0.5) > 12.0:
				_r(img, sx, sy, srng.randi_range(3, 6), 1, Color("c8f0ff"))
		# lily pads
		for p in [[0.22, 0.3], [0.75, 0.62], [0.3, 0.75], [0.8, 0.25]]:
			var px: float = p[0] * w
			var py: float = p[1] * h
			if inside.call(px, py) > 14.0:
				_ell(img, px, py, 6, 4, Color("4f9447"))
				_ell(img, px - 1, py - 1, 4, 2.5, Color("66ad57"))
				_r(img, int(px), int(py) - 4, 3, 4, Color("3a7aa0"))
				if p[0] < 0.5:
					_ell(img, px + 3, py - 2, 2, 2, Color("f2a6c8"))
		return _tex(img))

func pier_tex(w: int, h: int) -> Texture2D:
	return _cached("pier_%d_%d" % [w, h], func():
		var img := _new(w, h + 8)
		for y in range(0, h, 6):
			var c := Color("a8743f") if (y / 6) % 2 == 0 else Color("9a6a3a")
			_r(img, 2, y, w - 4, 5, c); _r(img, 2, y, w - 4, 1, c.lightened(0.18)); _r(img, 2, y + 5, w - 4, 1, Color("5c3a22"))
		_r(img, 0, 0, 3, h + 6, Color("6b4428")); _r(img, w - 3, 0, 3, h + 6, Color("6b4428"))
		_r(img, 0, h, 4, 8, Color("4a2e1c")); _r(img, w - 4, h, 4, 8, Color("4a2e1c"))
		_r(img, 0, h + 6, 4, 2, Color("8fd0e0")); _r(img, w - 4, h + 6, 4, 2, Color("8fd0e0"))
		_outline(img)
		return _tex(img))

func bobber_tex() -> Texture2D:
	return _cached("bobber", func():
		var img := _new(8, 10)
		_ell(img, 4, 4, 3, 3, Color("e84a3a"))
		_r(img, 1, 5, 6, 2, Color("f5f1ea"))
		_r(img, 3, 0, 2, 2, Color("3a3430"))
		_outline(img)
		return _tex(img))

# ---------------------------------------------------------------- fish icons

func fish_icon(id: String) -> Texture2D:
	return _cached("fish_" + id, func():
		var f: Dictionary = GameState.fish(id)
		if f.get("container", false):
			return _chest_icon()
		var art: Dictionary = f.get("art", {})
		var body := Color(art.get("body", "#999999"))
		var belly := Color(art.get("belly", "#dddddd"))
		var fin := Color(art.get("fin", "#666666"))
		var pattern: String = art.get("pattern", "none")
		var ln: float = art.get("len", 1.0)
		var img := _new(32, 18)
		var rx := 9.0 + 3.0 * ln
		var cx := 18.0
		var cy := 9.0
		# tail
		for i in 6:
			_r(img, int(cx - rx) - 5 + i, int(cy - 1 - i * 0.8), 1, int(2 + i * 1.6), fin)
		# fins
		for i in 5:
			_r(img, int(cx - 3 + i), int(cy - 5 - (4 - i) * 0.6), 2, 2, fin)
		_r(img, int(cx), int(cy + 3), 3, 3, fin)
		_ell(img, cx, cy, rx, 4.6, body)
		for y in range(int(cy) + 1, int(cy) + 5):
			for x in range(int(cx - rx), int(cx + rx) + 1):
				if img.get_pixel(x, y) == body:
					_p(img, x, y, belly)
		match pattern:
			"stripes":
				for k in range(-2, 3):
					_r(img, int(cx + k * 3), int(cy - 3), 1, 5, body.darkened(0.3))
			"spots":
				var rng := _rng(id.hash())
				for k in 6:
					_p(img, int(cx + rng.randf_range(-rx + 3, rx - 3)), int(cy + rng.randf_range(-3, 1)), body.darkened(0.35))
			"scales":
				for x in range(int(cx - rx + 3), int(cx + rx - 2), 2):
					_p(img, x, int(cy - 1) + (x % 4) / 2, body.darkened(0.2))
			"shine":
				_r(img, int(cx - 4), int(cy - 3), 6, 1, Color("fffbe0"))
			"koi":
				_ell(img, cx - 2, cy - 2, 3, 2, Color("e8743b"))
				_ell(img, cx + 4, cy, 2.5, 2, Color("e8743b"))
			"sunbeam":
				for k in range(-3, 4):
					_p(img, int(cx + k * 2), int(cy - 2 + absi(k) % 2), Color("fff6d0"))
				_r(img, int(cx - 6), int(cy - 4), 10, 1, Color("ff8a3d"))
		_r(img, int(cx + rx - 4), int(cy - 2), 2, 2, Color("1e1520"))
		_p(img, int(cx + rx - 4), int(cy - 2), Color("ffffff"))
		_outline(img)
		return _tex(img))

func _chest_icon() -> Texture2D:
	var img := _new(26, 20)
	_r(img, 2, 7, 22, 12, Color("7a4e2d")); _r(img, 2, 7, 22, 1, Color("9a6a3e"))
	_r(img, 3, 2, 20, 6, Color("8a5a35")); _r(img, 3, 2, 20, 1, Color("b07a48"))
	_r(img, 2, 8, 22, 2, Color("d4a24c")); _r(img, 6, 2, 2, 17, Color("d4a24c")); _r(img, 18, 2, 2, 17, Color("d4a24c"))
	_r(img, 11, 9, 4, 4, Color("f5d061")); _p(img, 12, 11, Color("3a2416"))
	_p(img, 4, 16, Color("5fa39a")); _p(img, 5, 15, Color("5fa39a")); _p(img, 21, 5, Color("5fa39a"))
	_outline(img)
	return _tex(img)

# ---------------------------------------------------------------- avatar (32x48)

const SKIN := Color("e0ac7e")
const SKIN_SH := Color("c48c62")
const HAIR := Color("3b2a20")
const HAIR_HI := Color("5a4030")
const SHIRT := Color("4a7fb5")
const SHIRT_SH := Color("365f8a")
const PANTS := Color("3a3f5a")
const PANTS_SH := Color("2a2e44")
const SHOE := Color("2a1e18")
const EYE := Color("1e1520")

# dir: "down", "up", "side" (faces right; flip for left). frame: 0 stand, 1/2 walk, 3 sit.
func avatar(dir: String, frame: int) -> Texture2D:
	return _cached("av_%s_%d" % [dir, frame], func():
		var img := _new(32, 48)
		var sit := frame == 3
		var dy := 4 if sit else 0
		match dir:
			"down", "up":
				_legs_front(img, frame)
				_torso_front(img, dy, frame, dir == "up")
				_head_front(img, dy, dir == "up")
			"side":
				_legs_side(img, frame)
				_torso_side(img, dy, frame)
				_head_side(img, dy)
		_outline(img)
		return _tex(img))

func _legs_front(img: Image, frame: int) -> void:
	if frame == 3:
		_r(img, 11, 38, 4, 5, PANTS); _r(img, 17, 38, 4, 5, PANTS)
		_r(img, 10, 43, 5, 3, SHOE); _r(img, 17, 43, 5, 3, SHOE)
		return
	var l_up := 1 if frame == 1 else 0
	var r_up := 1 if frame == 2 else 0
	_r(img, 11, 34, 4, 9 - l_up, PANTS); _r(img, 14, 34, 1, 9 - l_up, PANTS_SH)
	_r(img, 17, 34, 4, 9 - r_up, PANTS); _r(img, 20, 34, 1, 9 - r_up, PANTS_SH)
	_r(img, 10, 43 - l_up * 2, 5, 3, SHOE)
	_r(img, 17, 43 - r_up * 2, 5, 3, SHOE)

func _torso_front(img: Image, dy: int, frame: int, back: bool) -> void:
	_r(img, 9, 22 + dy, 14, 13, SHIRT)
	_r(img, 21, 22 + dy, 2, 13, SHIRT_SH)
	_r(img, 9, 33 + dy, 14, 2, PANTS_SH)
	if not back:
		_r(img, 15, 22 + dy, 2, 2, SKIN)
		_p(img, 14, 22 + dy, SHIRT_SH); _p(img, 17, 22 + dy, SHIRT_SH)
	var la := -1 if frame == 2 else 0
	var ra := -1 if frame == 1 else 0
	_r(img, 7, 23 + dy + la, 2, 6, SHIRT_SH); _r(img, 7, 29 + dy + la, 2, 4, SKIN)
	_r(img, 23, 23 + dy + ra, 2, 6, SHIRT_SH); _r(img, 23, 29 + dy + ra, 2, 4, SKIN_SH)

func _head_front(img: Image, dy: int, back: bool) -> void:
	_r(img, 15, 20 + dy, 2, 2, SKIN_SH)
	_r(img, 9, 7 + dy, 14, 14, SKIN)
	_r(img, 9, 19 + dy, 14, 2, SKIN_SH)
	_r(img, 8, 4 + dy, 16, 6, HAIR)
	_r(img, 10, 3 + dy, 12, 1, HAIR)
	_r(img, 11, 4 + dy, 6, 1, HAIR_HI)
	if back:
		_r(img, 8, 9 + dy, 16, 10, HAIR)
		_r(img, 10, 10 + dy, 2, 6, HAIR_HI)
		return
	_r(img, 8, 9 + dy, 2, 7, HAIR); _r(img, 22, 9 + dy, 2, 7, HAIR)
	_r(img, 10, 10 + dy, 3, 1, HAIR); _r(img, 15, 10 + dy, 4, 1, HAIR)
	_r(img, 12, 13 + dy, 2, 3, EYE); _r(img, 18, 13 + dy, 2, 3, EYE)
	_p(img, 12, 13 + dy, Color("ffffff")); _p(img, 18, 13 + dy, Color("ffffff"))
	_p(img, 11, 17 + dy, Color("e89a88")); _p(img, 20, 17 + dy, Color("e89a88"))
	_r(img, 15, 18 + dy, 2, 1, SKIN_SH)

func _legs_side(img: Image, frame: int) -> void:
	if frame == 3:
		_r(img, 13, 37, 9, 4, PANTS); _r(img, 20, 41, 3, 4, PANTS)
		_r(img, 20, 44, 5, 2, SHOE)
		return
	if frame == 0:
		_r(img, 13, 34, 6, 9, PANTS); _r(img, 13, 34, 1, 9, PANTS_SH)
		_r(img, 13, 43, 7, 3, SHOE)
	else:
		var f := 1 if frame == 1 else -1
		_r(img, 14 - 3 * f, 34, 4, 9, PANTS_SH)
		_r(img, 13 - 3 * f, 43, 5, 3, SHOE.lightened(0.05))
		_r(img, 14 + 3 * f, 34, 4, 9, PANTS)
		_r(img, 14 + 3 * f, 43, 6, 3, SHOE)

func _torso_side(img: Image, dy: int, frame: int) -> void:
	_r(img, 11, 22 + dy, 10, 13, SHIRT)
	_r(img, 11, 22 + dy, 2, 13, SHIRT_SH)
	_r(img, 11, 33 + dy, 10, 2, PANTS_SH)
	var sw := 0
	if frame == 1:
		sw = 2
	elif frame == 2:
		sw = -2
	_r(img, 15 + sw, 23 + dy, 3, 6, SHIRT_SH)
	_r(img, 15 + sw, 29 + dy, 3, 4, SKIN)

func _head_side(img: Image, dy: int) -> void:
	_r(img, 15, 20 + dy, 3, 2, SKIN_SH)
	_r(img, 10, 7 + dy, 12, 14, SKIN)
	_r(img, 10, 19 + dy, 12, 2, SKIN_SH)
	_p(img, 22, 15 + dy, SKIN)
	_r(img, 9, 4 + dy, 13, 6, HAIR)
	_r(img, 9, 9 + dy, 6, 9, HAIR)
	_r(img, 11, 3 + dy, 9, 1, HAIR)
	_r(img, 12, 4 + dy, 5, 1, HAIR_HI)
	_r(img, 16, 10 + dy, 5, 1, HAIR)
	_r(img, 18, 13 + dy, 2, 3, EYE)
	_p(img, 19, 13 + dy, Color("ffffff"))
	_p(img, 17, 17 + dy, Color("e89a88"))
	_r(img, 13, 12 + dy, 2, 3, SKIN_SH)

# Soft radial texture for PointLight2D.
func light_tex() -> Texture2D:
	return _cached("light", func():
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.45, Color(1, 1, 1, 0.45))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 256
		t.height = 256
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		return t)
