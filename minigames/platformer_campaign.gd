class_name PlatformerCampaign
extends RefCounted
## The platformer levels in story order, after the comic. Each level has its own map (the same
## letters as PlatformerGame.LEVEL), a name, whether it is played at night, and the comic pages
## shown before it.

## Book I, part 1: Wiesław guards the orchard at night and chases the apple thieves through it.
const ORCHARD_AT_NIGHT := [
	"                                                                                                    ",
	"                                                                                                    ",
	"                                                                                                    ",
	"                                                                                                    ",
	"             a                  aa                                  T                               ",
	"            ===                ===          ?                     ====                              ",
	"         aa                                                         H                               ",
	"        ====                ====           a  aV        aa     ==== H           aaa                 ",
	"          H                               ######       ====         H           ###                 ",
	"  P       H      ##  aa V     B      xx   ######   C          V     H V    BB   ###    x   V   D    ",
	"#######################################################    #########################################",
	"#######################################################    #########################################",
]


static func levels() -> Array[Dictionary]:
	var pages := BookOneStory.intro_pages()
	return [
		{"name": "Sad nocą", "map": ORCHARD_AT_NIGHT, "night": true, "pages": [pages[0]]},
		{"name": "Pościg za drakkarem", "map": PlatformerGame.LEVEL_KNIGHT, "night": false, "pages": [pages[1]]},
	]
