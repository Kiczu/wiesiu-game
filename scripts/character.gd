class_name Character
extends Node2D
## Placeholder character drawn from shapes. The origin is at the feet.

signal arrived

@export var display_name := ""
@export var body_color := Color("7b5ea7")
@export var helmet := false
@export var crown := false
@export var feather := false
@export var beard := false
@export var mustache := false
@export var braids := false
@export var chainmail := false
@export var asleep := false
@export var speed := 280.0

var facing := 1
var talking := false:
	set(value):
		talking = value
		queue_redraw()

var _target := Vector2.ZERO
var _walking := false
var _anim := 0.0

const SKIN := Color("f2c29b")
const OUTLINE := Color("2b1d14")


func _ready() -> void:
	_target = position


func walk_to(point: Vector2) -> void:
	if Game.fast or position.distance_to(point) < 2.0:
		position = point
		_walking = false
		return
	_target = point
	_walking = true
	await arrived


func face(point: Vector2) -> void:
	if absf(point.x - position.x) > 4.0:
		facing = 1 if point.x > position.x else -1
		queue_redraw()


func head_position() -> Vector2:
	if asleep:
		return global_position + Vector2(-60, -70)
	return global_position + Vector2(0, -150) * scale.y


func _process(delta: float) -> void:
	if _walking:
		var to_target := _target - position
		var step := speed * delta
		if to_target.length() <= step:
			position = _target
			_walking = false
			arrived.emit()
		else:
			position += to_target.normalized() * step
			if absf(to_target.x) > 1.0:
				facing = 1 if to_target.x > 0 else -1
	if _walking or talking or asleep:
		_anim += delta
		queue_redraw()
	# Fake depth: characters lower on screen are closer, so larger.
	var depth := clampf(inverse_lerp(470.0, 640.0, position.y), 0.0, 1.0)
	scale = Vector2.ONE * lerpf(0.85, 1.05, depth)


func _draw() -> void:
	if asleep:
		_draw_asleep()
		return
	var bob := absf(sin(_anim * 10.0)) * -4.0 if _walking else 0.0
	var stride := sin(_anim * 10.0) * 8.0 if _walking else 0.0
	draw_rect(Rect2(-16 + stride, -34, 12, 34), Color("5a3e2b"))
	draw_rect(Rect2(4 - stride, -34, 12, 34), Color("5a3e2b"))
	var body := Rect2(-26, -92 + bob, 52, 62)
	draw_rect(body, body_color)
	if chainmail:
		for y in range(-86, -34, 8):
			for x in range(-20, 24, 8):
				draw_arc(Vector2(x, y + bob), 3, 0, PI, 4, Color(0, 0, 0, 0.35), 1.0)
	draw_rect(body, OUTLINE, false, 2.0)
	draw_rect(Rect2(-26, -46 + bob, 52, 6), Color("6b4423"))
	var head := Vector2(0, -114 + bob)
	draw_circle(head, 24, SKIN)
	draw_arc(head, 24, 0, TAU, 32, OUTLINE, 2.0)
	draw_circle(head + Vector2(16 * facing, 4), 9, Color("e8a87c"))
	draw_circle(head + Vector2(6 * facing, -6), 3.5, OUTLINE)
	draw_circle(head + Vector2(16 * facing, -7), 3.5, OUTLINE)
	if beard:
		draw_colored_polygon(PackedVector2Array([head + Vector2(-22, 6), head + Vector2(22, 6), head + Vector2(0, 40)]), Color("f4f4f4"))
	if braids:
		draw_rect(Rect2(head + Vector2(-30, -10), Vector2(8, 40)), Color("f2c14e"))
		draw_rect(Rect2(head + Vector2(22, -10), Vector2(8, 40)), Color("f2c14e"))
		if not helmet:
			draw_circle(head + Vector2(0, -12), 20, Color("f2c14e"))
	if talking and fmod(_anim, 0.3) < 0.15:
		draw_circle(head + Vector2(8 * facing, 14), 5, Color("7a2e2e"))
	else:
		draw_line(head + Vector2(2 * facing, 14), head + Vector2(14 * facing, 13), OUTLINE, 2.0)
	if mustache:
		draw_circle(head + Vector2(10 * facing, 10), 7, Color("5a3e2b"))
		draw_circle(head + Vector2(22 * facing, 10), 7, Color("5a3e2b"))
	if helmet:
		_draw_helmet(head)
	if feather:
		draw_line(head + Vector2(0, -34), head + Vector2(-12 * facing, -56), Color("d62828"), 6.0)
	if crown:
		_draw_crown(head)


func _draw_helmet(head: Vector2) -> void:
	var dome := PackedVector2Array()
	for i in 17:
		var angle := PI + PI * i / 16.0
		dome.append(head + Vector2(cos(angle) * 27, sin(angle) * 32 - 4))
	draw_colored_polygon(dome, Color("a9b1b8"))
	draw_polyline(dome, OUTLINE, 2.0)
	draw_line(head + Vector2(-27, -4), head + Vector2(27, -4), OUTLINE, 2.0)
	draw_rect(Rect2(head + Vector2(4 * facing - 3, -6), Vector2(6, 16)), Color("a9b1b8"))


func _draw_crown(head: Vector2) -> void:
	var top := head + Vector2(0, -20)
	var points := PackedVector2Array([
		top + Vector2(-20, 0), top + Vector2(-20, -18), top + Vector2(-10, -8),
		top + Vector2(0, -22), top + Vector2(10, -8), top + Vector2(20, -18), top + Vector2(20, 0),
	])
	draw_colored_polygon(points, Color("ffcc33"))
	draw_polyline(points, OUTLINE, 2.0)


func _draw_asleep() -> void:
	var breath := sin(_anim * 2.0) * 2.0
	draw_rect(Rect2(-100, -40 - breath, 64, 40 + breath), body_color)
	draw_rect(Rect2(-36, -26, 50, 26), Color("5a3e2b"))
	var head := Vector2(-124, -24)
	draw_circle(head, 24, SKIN)
	draw_arc(head, 24, 0, TAU, 32, OUTLINE, 2.0)
	draw_circle(head + Vector2(0, -16), 9, Color("e8a87c"))
	draw_line(head + Vector2(-12, -4), head + Vector2(-4, -4), OUTLINE, 2.0)
	if helmet:
		draw_circle(head + Vector2(-20, 4), 18, Color("a9b1b8"))
	var font := ThemeDB.fallback_font
	for i in 3:
		var t := fmod(_anim * 0.6 + i / 3.0, 1.0)
		var pos := head + Vector2(10 + t * 40, -30 - t * 60)
		draw_string(font, pos, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, int(18 + t * 14), Color(1, 1, 1, 1.0 - t))
