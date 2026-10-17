class_name AlpineBackdrop
extends Control
## The painted scenery behind every screen: a soft sky, snowy alpine peaks, green hills
## with pines, and the flood water at the bottom. Drawn in code, so it is original art
## and stays sharp at any screen size. Placeholder until the illustrated scenery
## (see the Illustration Art Direction Brief) is painted.

const SKY_TOP := Color("#7DB7E6")
const SKY_BOTTOM := Color("#E6EFD9")
const PEAK := Color("#8C9FB8")
const PEAK_SHADE := Color("#6F829C")
const SNOW := Color("#F7F9FC")
const HILL_FAR := Color("#7FBF59")
const HILL_NEAR := Color("#5E9C43")
const PINE := Color("#2F6B3A")
const ARK_BODY := Color("#6B4A2E")
const ARK_CABIN := Color("#8A6440")
const ARK_ROOF := Color("#3A2818")
const ARK_DARK := Color("#4A3220")
const WATER := Color("#2E5F6E")
const WATER_LIGHT := Color("#5C93A0")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	_draw_sky(w, h)
	# Peaks sit in the top half so the menu cards cover only the lower slopes.
	var base := h * 0.46
	_draw_peak(Vector2(w * 0.18, h * 0.22), w * 0.34, base)
	_draw_peak(Vector2(w * 0.52, h * 0.14), w * 0.42, base)
	_draw_peak(Vector2(w * 0.86, h * 0.24), w * 0.32, base)
	_draw_hill(h * 0.44, h * 0.05, HILL_FAR, w, h, 0.0)
	_draw_hill(h * 0.52, h * 0.04, HILL_NEAR, w, h, 1.7)
	for i in 9:
		var x := w * (0.05 + i * 0.115)
		var y := h * (0.50 + 0.02 * sin(i * 1.3))
		_draw_pine(Vector2(x, y), h * 0.05)
	_draw_ark(Vector2(w * 0.5, h * 0.455), minf(w * 0.5, h * 0.28))
	_draw_water(w, h)


## The ark resting on the hilltop: hull, cabin, roof, and a door.
func _draw_ark(keel: Vector2, length: float) -> void:
	var half := length / 2.0
	var hull_h := length * 0.2
	var hull := PackedVector2Array([
		Vector2(keel.x - half, keel.y - hull_h), Vector2(keel.x + half, keel.y - hull_h),
		Vector2(keel.x + half * 0.78, keel.y), Vector2(keel.x - half * 0.78, keel.y)])
	draw_colored_polygon(hull, ARK_BODY)
	draw_polyline(hull + PackedVector2Array([hull[0]]), ARK_DARK, 5.0, true)
	draw_line(Vector2(keel.x - half * 0.86, keel.y - hull_h * 0.45), Vector2(keel.x + half * 0.86, keel.y - hull_h * 0.45), ARK_DARK, 3.0)
	var cabin := Rect2(keel.x - half * 0.5, keel.y - hull_h - length * 0.14, half, length * 0.14)
	draw_rect(cabin, ARK_CABIN)
	draw_rect(cabin, ARK_DARK, false, 4.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cabin.position.x - length * 0.04, cabin.position.y),
		Vector2(keel.x, cabin.position.y - length * 0.09),
		Vector2(cabin.end.x + length * 0.04, cabin.position.y)]), ARK_ROOF)
	draw_rect(Rect2(keel.x - length * 0.03, cabin.position.y + length * 0.04, length * 0.06, length * 0.1), SNOW)


func _draw_sky(w: float, h: float) -> void:
	var bands := 24
	for i in bands:
		var t := float(i) / bands
		draw_rect(Rect2(0, h * t, w, h / bands + 1.0), SKY_TOP.lerp(SKY_BOTTOM, t))


func _draw_peak(top: Vector2, width: float, base: float) -> void:
	var left := Vector2(top.x - width / 2.0, base)
	var right := Vector2(top.x + width / 2.0, base)
	draw_colored_polygon(PackedVector2Array([top, right, left]), PEAK)
	# The shaded east face.
	draw_colored_polygon(PackedVector2Array([top, right, Vector2(top.x + width * 0.05, base)]), PEAK_SHADE)
	# A jagged snowcap on the top quarter.
	var cap := 0.28
	var cl := top.lerp(left, cap)
	var cr := top.lerp(right, cap)
	var points := PackedVector2Array([top, cr])
	for k in range(4, 0, -1):
		var p := cl.lerp(cr, k / 5.0)
		points.append(p + Vector2(0, (width * 0.03) if k % 2 == 1 else -width * 0.01))
	points.append(cl)
	draw_colored_polygon(points, SNOW)


func _draw_hill(y: float, bump: float, color: Color, w: float, h: float, phase: float) -> void:
	var points := PackedVector2Array()
	var steps := 32
	for i in steps + 1:
		var x := w * i / steps
		points.append(Vector2(x, y - bump * sin(i * 0.35 + phase)))
	points.append(Vector2(w, h))
	points.append(Vector2(0, h))
	draw_colored_polygon(points, color)


func _draw_pine(foot: Vector2, height: float) -> void:
	var half := height * 0.32
	for tier in 3:
		var top := foot.y - height * (0.45 + tier * 0.27)
		var bottom := foot.y - height * tier * 0.27
		var spread := half * (1.0 - tier * 0.22)
		draw_colored_polygon(PackedVector2Array([
			Vector2(foot.x, top), Vector2(foot.x + spread, bottom), Vector2(foot.x - spread, bottom)]), PINE)


func _draw_water(w: float, h: float) -> void:
	var top := h * 0.86
	draw_rect(Rect2(0, top, w, h - top), WATER)
	for row in 3:
		var y := top + (h - top) * (0.2 + row * 0.28)
		var points := PackedVector2Array()
		for i in 21:
			var x := w * i / 20.0
			points.append(Vector2(x, y + 6.0 * sin(i * 1.1 + row)))
		draw_polyline(points, WATER_LIGHT, 4.0, true)
