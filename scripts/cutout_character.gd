class_name CutoutCharacter
extends Node2D
## A character built from separate parts (cutout animation), like a paper puppet: the author
## draws each part once and the poses are made here by turning the parts at their joints.
## The parts are placeholder shapes for now. The origin is at the feet; drawn facing right.

const OUTLINE := Color("2b1d14")

## Part: [parent, joint position in the parent, size, colour, drawn behind the body].
## Each part hangs from its joint: limbs point down from it, the torso and head point up.
const PARTS := {
	"hips": ["", Vector2(0, -46), Vector2.ZERO, Color.TRANSPARENT, false],
	"leg_far": ["hips", Vector2(-3, 0), Vector2(12, 24), Color("4a3222"), true],
	"shin_far": ["leg_far", Vector2(0, 22), Vector2(11, 24), Color("4a3222"), true],
	"leg_near": ["hips", Vector2(3, 0), Vector2(12, 24), Color("5a3e2b"), false],
	"shin_near": ["leg_near", Vector2(0, 22), Vector2(11, 24), Color("5a3e2b"), false],
	"torso": ["hips", Vector2(0, 4), Vector2(28, 40), Color("7b5ea7"), false],
	"arm_far": ["torso", Vector2(-2, -34), Vector2(10, 18), Color("62488a"), true],
	"hand_far": ["arm_far", Vector2(0, 16), Vector2(9, 17), Color("e0ac86"), true],
	"head": ["torso", Vector2(0, -38), Vector2(32, 32), Color("f2c29b"), false],
	"arm_near": ["torso", Vector2(2, -34), Vector2(10, 18), Color("7b5ea7"), false],
	"hand_near": ["arm_near", Vector2(0, 16), Vector2(9, 17), Color("f2c29b"), false],
}

## 1 faces right, -1 left (the whole puppet is mirrored).
var facing := 1:
	set(value):
		facing = value
		scale.x = absf(scale.x) * value
## idle, run, jump, fall, hurt, win
var pose := "idle"

var _parts := {}
var _time := 0.0


func _ready() -> void:
	for id in PARTS:
		var spec: Array = PARTS[id]
		var part := Part.new()
		part.id = id
		part.size = spec[2]
		part.color = spec[3]
		part.position = spec[1]
		var parent: Node2D = self if spec[0] == "" else _parts[spec[0]]
		parent.add_child(part)
		if spec[4]:
			part.z_index = -1
		_parts[id] = part


func _process(delta: float) -> void:
	_time += delta
	_apply(_angles(pose, _time))


## Joint angles for a pose at time t, in radians; positive turns a hanging limb backwards.
func _angles(name: String, t: float) -> Dictionary:
	var a := {}
	var lift := 0.0
	match name:
		"idle":
			var breath := sin(t * 2.5)
			a = {"torso": 0.02 * breath, "head": -0.03 * breath, "arm_near": 0.08 + 0.04 * breath, "arm_far": -0.08,
				"hand_near": -0.25, "hand_far": -0.25, "leg_near": -0.05, "leg_far": 0.05}
			lift = breath * 0.8
		"run":
			var p := t * 13.0
			var swing := sin(p)
			a = {"torso": 0.14, "head": -0.1,
				"leg_near": -0.8 * swing, "leg_far": 0.8 * swing,
				"shin_near": 1.1 * maxf(0.0, sin(p + 1.6)), "shin_far": 1.1 * maxf(0.0, sin(p + 1.6 + PI)),
				"arm_near": 0.7 * swing, "arm_far": -0.7 * swing, "hand_near": -0.9, "hand_far": -0.9}
			lift = absf(cos(p)) * 4.0
		"jump":
			a = {"torso": 0.05, "head": -0.1, "leg_near": -1.1, "shin_near": 1.4, "leg_far": 0.3, "shin_far": 0.8,
				"arm_near": -2.6, "hand_near": -0.3, "arm_far": 0.6, "hand_far": -0.6}
		"fall":
			var flap := sin(t * 18.0) * 0.15
			a = {"torso": -0.05, "leg_near": -0.35, "shin_near": 0.4, "leg_far": 0.35, "shin_far": 0.3,
				"arm_near": -1.9 + flap, "hand_near": -0.4, "arm_far": 1.9 - flap, "hand_far": 0.4}
		"hurt":
			a = {"torso": -0.35, "head": 0.25, "leg_near": -0.5, "shin_near": 0.5, "leg_far": 0.3,
				"arm_near": -2.2, "hand_near": 0.5, "arm_far": 2.2, "hand_far": -0.5}
		"win":
			var cheer := sin(t * 8.0) * 0.2
			a = {"head": -0.15, "arm_near": -2.9 + cheer, "hand_near": 0.2, "arm_far": 2.9 - cheer, "hand_far": -0.2,
				"leg_near": -0.15, "leg_far": 0.15}
			lift = absf(sin(t * 4.0)) * 14.0
	a["lift"] = lift
	return a


func _apply(angles: Dictionary) -> void:
	for id in _parts:
		_parts[id].rotation = angles.get(id, 0.0)
	_parts["hips"].position.y = PARTS["hips"][1].y - angles["lift"]


## One placeholder part. A drawn PNG will replace these shapes later.
class Part:
	extends Node2D

	var id := ""
	var size := Vector2.ZERO
	var color := Color.WHITE

	func _draw() -> void:
		if size == Vector2.ZERO:
			return
		match id:
			"head":
				var center := Vector2(2, -14)
				draw_circle(center, 15, color)
				draw_arc(center, 15, 0, TAU, 24, OUTLINE, 2.0)
				draw_circle(center + Vector2(14, 3), 6, color.darkened(0.12))
				draw_circle(center + Vector2(9, -3), 2.5, OUTLINE)
				draw_line(center + Vector2(5, 8), center + Vector2(13, 7), OUTLINE, 2.0)
				var dome := PackedVector2Array()
				for i in 13:
					var angle := PI + PI * i / 12.0
					dome.append(center + Vector2(cos(angle) * 17, sin(angle) * 19 - 2))
				draw_colored_polygon(dome, Color("a9b1b8"))
				draw_polyline(dome, OUTLINE, 2.0)
				draw_rect(Rect2(center + Vector2(4, -4), Vector2(4, 11)), Color("a9b1b8"))
			"torso":
				var body := Rect2(-size.x / 2, -size.y, size.x, size.y)
				draw_rect(body, color)
				draw_rect(Rect2(-size.x / 2, -12, size.x, 5), Color("6b4423"))
				draw_rect(body, OUTLINE, false, 2.0)
			"hand_near", "hand_far":
				var sleeve := Rect2(-size.x / 2, -2, size.x, size.y - 6)
				draw_rect(sleeve, PARTS["arm_" + id.substr(5)][3])
				draw_rect(sleeve, OUTLINE, false, 1.5)
				draw_circle(Vector2(0, size.y - 4), 5, color)
				draw_arc(Vector2(0, size.y - 4), 5, 0, TAU, 12, OUTLINE, 1.5)
			"shin_near", "shin_far":
				var shin := Rect2(-size.x / 2, -2, size.x, size.y - 6)
				draw_rect(shin, color)
				draw_rect(Rect2(-size.x / 2, size.y - 8, size.x + 7, 8), Color("2e1f14"))
				draw_rect(shin, OUTLINE, false, 1.5)
			_:
				var limb := Rect2(-size.x / 2, -size.x / 2, size.x, size.y + size.x / 2)
				draw_rect(limb, color)
				draw_rect(limb, OUTLINE, false, 1.5)
