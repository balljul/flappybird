extends Node

var db_manager: Node
var owned_items: Array[String] = []
var selected_bird_color: Color = Color.YELLOW
var high_score: int = 0

func _ready():
	# Initialize database manager
	db_manager = preload("res://scripts/DatabaseManager.gd").new()
	add_child(db_manager)
	
	# Wait a frame for database to initialize
	await get_tree().process_frame
	load_game_data()

func add_owned_item(item_id: String, item_name: String = "", price: int = 0):
	if not item_id in owned_items:
		owned_items.append(item_id)
		if db_manager:
			db_manager.add_owned_item(item_id, item_name, price)

func is_item_owned(item_id: String) -> bool:
	if db_manager:
		return db_manager.is_item_owned(item_id)
	return item_id in owned_items

func set_selected_bird_color(color: Color):
	selected_bird_color = color
	if db_manager:
		db_manager.set_selected_bird_color(var_to_str(color))

func add_game_session(score: int, duration: int = 0):
	if db_manager:
		db_manager.add_game_session(score, duration, var_to_str(selected_bird_color))

func get_purchase_history() -> Array:
	if db_manager:
		return db_manager.get_purchase_history()
	return []

func get_game_statistics() -> Dictionary:
	if db_manager:
		return db_manager.get_game_statistics()
	return {}

func save_game_data():
	if db_manager:
		db_manager.set_high_score(high_score)
		db_manager.set_selected_bird_color(var_to_str(selected_bird_color))
		print("Game data saved to database")
	else:
		# Fallback to JSON if database not available
		var save_data = {
			"owned_items": owned_items,
			"selected_bird_color": var_to_str(selected_bird_color),
			"high_score": high_score
		}
		
		var save_file = FileAccess.open("user://gamedata.save", FileAccess.WRITE)
		if save_file:
			save_file.store_string(JSON.stringify(save_data))
			save_file.close()
			print("Game data saved to JSON")

func load_game_data():
	if db_manager:
		# Load from database
		owned_items = db_manager.get_owned_items()
		high_score = db_manager.get_high_score()
		var color_str = db_manager.get_selected_bird_color()
		selected_bird_color = str_to_var(color_str) if color_str else Color.YELLOW
		print("Game data loaded from database")
		print("Owned items: ", owned_items)
		print("High score: ", high_score)
	else:
		# Fallback to JSON loading
		var save_file = FileAccess.open("user://gamedata.save", FileAccess.READ)
		if save_file:
			var save_data = JSON.parse_string(save_file.get_as_text())
			save_file.close()
			
			if save_data:
				owned_items = save_data.get("owned_items", [])
				selected_bird_color = str_to_var(save_data.get("selected_bird_color", var_to_str(Color.YELLOW)))
				high_score = save_data.get("high_score", 0)
				print("Game data loaded from JSON")
		else:
			print("No save file found, using defaults")