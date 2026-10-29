class_name PlatformerCampaign
extends RefCounted
## The platformer levels in story order, after the comic. Each level is a scene painted in the
## editor (LevelMap) with its name and whether it is played at night; the comic pages shown before
## it go with it here. A new level is a copy of one of these scenes, added to SCENES.

## Book I: the orchard at night, then the chase after the drakkar.
const SCENES := ["res://levels/01_sad_noca.tscn", "res://levels/02_poscig.tscn"]


static func levels() -> Array[Dictionary]:
	var pages := BookOneStory.intro_pages()
	var list: Array[Dictionary] = []
	for i in SCENES.size():
		var spec := LevelMap.read(SCENES[i])
		spec["pages"] = [pages[i]] if i < pages.size() else []
		list.append(spec)
	return list
