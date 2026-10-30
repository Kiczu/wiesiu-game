class_name CutoutCharacter
extends Node2D
## A character built from separate parts (cutout animation), like a paper puppet: the author
## draws each part once and the poses are made here by turning the parts at their joints.
## When the author's parts are in one of ART_SETS (PNGs plus rig.json with each part's place and
## joint), they are used; otherwise placeholder shapes. Frame-by-frame animations in ANIM_DIRS
## (PNGs plus frames.json) take over from all of them. The origin is at the feet; drawn facing right.

const OUTLINE := Color("2b1d14")
## Drawn versions of Wiesław made of parts.
const ART_SETS := {"smooth": "res://art/platformer/wieslaw/"}
## Ready-made animation frames: frames.json lists, for each pose, its fps, whether it loops and
## its frames, each with the point of the image that stands on the ground. The first set that is
## there is used: the author's side view, then the chibi.
const ANIM_DIRS := ["res://art/platformer/wieslaw_bok/", "res://art/platformer/wieslaw_chibi/"]
## Parts drawn behind the body.
const ART_BEHIND := ["arm_far", "foot_far", "foot_near"]
## Height of the drawn Wiesław in pixels, before the scale the game gives the puppet.
const ART_HEIGHT := 150.0
## Drawn parts follow the joints of the placeholder puppet: [placeholder joint, how much of its turn].
const ART_JOINTS := {
	"body": ["torso", 1.0], "head": ["head", 1.0], "arm_near": ["arm_near", 0.5], "arm_far": ["arm_far", 0.5],
	"foot_near": ["leg_near", 0.6], "foot_far": ["leg_far", 0.6], "hand_far": ["hand_far", 0.5],
}

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
## idle, run, jump, fall, hurt, win, and climb when drawn
var pose := "idle"

var _parts := {}
var _time := 0.0
## Drawn sets by name: {"root": Node2D, "parts": {part name: Node2D}}.
var _art := {}
var _art_set := ""
## Frame animation: {pose: {"fps", "loop", "frames": [{"texture", "anchor"}]}}.
var _anim := {}
var _anim_sprite: Sprite2D
var _anim_pose := ""
var _anim_time := 0.0
## Colour the purple robe is repainted with, to make other people from the same frames;
## fully transparent keeps the robe as drawn.
var robe_color := Color.TRANSPARENT
## Holds the current frame (Wiesław resting on the ladder).
var paused := false


func _ready() -> void:
	if has_frames():
		_build_anim(JSON.parse_string(FileAccess.get_file_as_string(anim_dir() + "frames.json")))
		return
	for set_name in ART_SETS:
		var dir: String = ART_SETS[set_name]
		if FileAccess.file_exists(dir + "rig.json"):
			_art[set_name] = _build_art(dir, JSON.parse_string(FileAccess.get_file_as_string(dir + "rig.json")))
	if not _art.is_empty():
		_show_art()
		return
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


## Every part hangs at its joint: the body from the root, the others from the body (or the part
## named as their parent). The comic set gets mipmaps so it stays
## smooth when scaled down, the pixel set keeps hard pixel edges.
func _build_art(dir: String, rig: Dictionary) -> Dictionary:
	var feet: float = rig["feet_y"]
	var pixel: bool = rig.get("pixel", false)
	var root := Node2D.new()
	root.scale = Vector2.ONE * ART_HEIGHT / feet
	add_child(root)
	var specs: Dictionary = rig["parts"]
	var nodes := {}
	for id in rig.get("order", ["body", "foot_far", "foot_near", "arm_far", "head", "arm_near"]):
		var spec: Dictionary = specs[id]
		var joint := _vec(spec["joint"])
		var node := Node2D.new()
		var sprite := Sprite2D.new()
		var texture: Texture2D = load(dir + spec["file"])
		if not pixel:
			var image := texture.get_image()
			image.generate_mipmaps()
			texture = ImageTexture.create_from_image(image)
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.centered = false
		sprite.position = _vec(spec["origin"]) - joint
		node.add_child(sprite)
		if id == "body":
			node.position = joint - Vector2(rig["canvas"][0] / 2.0, feet)
			root.add_child(node)
		else:
			var parent: String = spec.get("parent", "body")
			node.position = joint - _vec(specs[parent]["joint"])
			node.show_behind_parent = id in ART_BEHIND
			nodes[parent].add_child(node)
		nodes[id] = node
	return {"root": root, "parts": nodes}


## Whether this puppet can show the pose: drawn frames may not have every pose yet.
func has_pose(pose_name: String) -> bool:
	return _anim.has(pose_name) if _anim_sprite else true


## Whether the pose comes from drawn frames rather than the puppet.
func has_drawn_pose(pose_name: String) -> bool:
	return _anim_sprite != null and _anim.has(pose_name)


## Whether drawn animation frames are there (other characters can then be made from them).
static func has_frames() -> bool:
	return anim_dir() != ""


## The animation set in use, or "" when there is none.
static func anim_dir() -> String:
	for dir in ANIM_DIRS:
		if FileAccess.file_exists(dir + "frames.json"):
			return dir
	return ""


func _build_anim(spec: Dictionary) -> void:
	_anim_sprite = Sprite2D.new()
	_anim_sprite.centered = false
	_anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_anim_sprite.scale = Vector2.ONE * ART_HEIGHT / spec["height"]
	add_child(_anim_sprite)
	if robe_color.a > 0.0:
		var material := ShaderMaterial.new()
		material.shader = preload("res://scripts/robe_recolor.gdshader")
		material.set_shader_parameter("new_color", Vector3(robe_color.h, robe_color.s, robe_color.v))
		_anim_sprite.material = material
	for pose_name in spec["poses"]:
		var pose_spec: Dictionary = spec["poses"][pose_name]
		var frames := []
		for frame in pose_spec["frames"]:
			frames.append({"texture": load(anim_dir() + frame["file"]), "anchor": _vec(frame["anchor"])})
		# A pose drawn at another size gives its own height, so it shows at the same size as the rest.
		var pose_scale: float = ART_HEIGHT / pose_spec.get("height", spec["height"])
		_anim[pose_name] = {"fps": pose_spec["fps"], "loop": pose_spec["loop"], "frames": frames, "scale": pose_scale}


func _show_frame(delta: float) -> void:
	var current: Dictionary = _anim.get(pose, _anim["idle"])
	if pose != _anim_pose:
		_anim_pose = pose
		_anim_time = 0.0
	if not paused:
		_anim_time += delta
	var frames: Array = current["frames"]
	var index := int(_anim_time * current["fps"])
	index = index % frames.size() if current["loop"] else mini(index, frames.size() - 1)
	var frame: Dictionary = frames[index]
	_anim_sprite.texture = frame["texture"]
	_anim_sprite.scale = Vector2.ONE * current["scale"]
	_anim_sprite.position = -frame["anchor"] * _anim_sprite.scale


func _show_art() -> void:
	if _art.is_empty():
		return
	_art_set = _art.keys()[0]
	for set_name in _art:
		_art[set_name]["root"].visible = set_name == _art_set


static func _vec(value: Array) -> Vector2:
	return Vector2(value[0], value[1])


func _process(delta: float) -> void:
	_time += delta
	if _anim_sprite:
		_show_frame(delta)
		return
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
		"hurt", "death":
			a = {"torso": -0.35, "head": 0.25, "leg_near": -0.5, "shin_near": 0.5, "leg_far": 0.3,
				"arm_near": -2.2, "hand_near": 0.5, "arm_far": 2.2, "hand_far": -0.5}
		"attack":
			a = {"torso": 0.2, "head": -0.1, "leg_near": -0.5, "shin_near": 0.3, "leg_far": 0.4,
				"arm_near": -1.5, "hand_near": -0.2, "arm_far": 0.5, "hand_far": -0.5}
		"win":
			var cheer := sin(t * 8.0) * 0.2
			a = {"head": -0.15, "arm_near": -2.9 + cheer, "hand_near": 0.2, "arm_far": 2.9 - cheer, "hand_far": -0.2,
				"leg_near": -0.15, "leg_far": 0.15}
			lift = absf(sin(t * 4.0)) * 14.0
	a["lift"] = lift
	return a


func _apply(angles: Dictionary) -> void:
	if _art_set != "":
		var drawn: Dictionary = _art[_art_set]
		for id in drawn["parts"]:
			drawn["parts"][id].rotation = angles.get(ART_JOINTS[id][0], 0.0) * ART_JOINTS[id][1]
		drawn["root"].position.y = -angles["lift"]
		return
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
