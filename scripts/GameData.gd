extends Node

const SAVE_FILE_PATH = "user://gamedata.save"

var owned_items: Array[String] = []
var selected_bird_color: Color = Color.YELLOW
var high_score: int = 0

func _ready():
	load_game_data()

func add_owned_item(item_id: String):
	if not item_id in owned_items:
		owned_items.append(item_id)

func is_item_owned(item_id: String) -> bool:
	return item_id in owned_items

func set_selected_bird_color(color: Color):
	selected_bird_color = color

func save_game_data():
	var save_data = {
		"owned_items": owned_items,
		"selected_bird_color": var_to_str(selected_bird_color),
		"high_score": high_score
	}
	
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		print("Game data saved")

func load_game_data():
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if save_file:
		var save_data = JSON.parse_string(save_file.get_as_text())
		save_file.close()
		
		if save_data:
			owned_items = save_data.get("owned_items", [])
			selected_bird_color = str_to_var(save_data.get("selected_bird_color", var_to_str(Color.YELLOW)))
			high_score = save_data.get("high_score", 0)
			print("Game data loaded")
	else:
		print("No save file found, using defaults")