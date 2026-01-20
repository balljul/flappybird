extends Node

var db
var db_path = "res://database/flappy_bird.db"

func _ready():
	db = SQLite.new()
	db.path = db_path
	if not db.open_db():
		print("Failed to open database")
		return
	
	create_tables()
	print("Database initialized at: ", db_path)

func create_tables():
	var queries = [
		"""CREATE TABLE IF NOT EXISTS player_data (
			id INTEGER PRIMARY KEY,
			high_score INTEGER DEFAULT 0,
			selected_bird_color TEXT DEFAULT 'Color(1, 1, 0, 1)',
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		);""",
		
		"""CREATE TABLE IF NOT EXISTS owned_items (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			item_id TEXT UNIQUE NOT NULL,
			item_name TEXT NOT NULL,
			purchase_price INTEGER NOT NULL,
			purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		);""",
		
		"""CREATE TABLE IF NOT EXISTS game_sessions (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			score INTEGER NOT NULL,
			duration_seconds INTEGER DEFAULT 0,
			bird_color TEXT,
			played_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		);""",
		
		"""INSERT OR IGNORE INTO player_data (id, high_score) VALUES (1, 0);"""
	]
	
	for query in queries:
		db.query(query)

func get_high_score() -> int:
	db.query("SELECT high_score FROM player_data WHERE id = 1;")
	var result = db.query_result
	if result and result.size() > 0:
		return result[0]["high_score"]
	return 0

func set_high_score(score: int):
	var query = "UPDATE player_data SET high_score = %d, updated_at = CURRENT_TIMESTAMP WHERE id = 1;" % score
	db.query(query)
	print("High score updated to: ", score)

func get_selected_bird_color() -> String:
	db.query("SELECT selected_bird_color FROM player_data WHERE id = 1;")
	var result = db.query_result
	if result and result.size() > 0:
		return result[0]["selected_bird_color"]
	return "Color(1, 1, 0, 1)"

func set_selected_bird_color(color_string: String):
	var query = "UPDATE player_data SET selected_bird_color = '%s', updated_at = CURRENT_TIMESTAMP WHERE id = 1;" % color_string
	db.query(query)
	print("Selected bird color updated to: ", color_string)

func get_owned_items() -> Array:
	db.query("SELECT item_id FROM owned_items ORDER BY purchased_at;")
	var result = db.query_result
	var items = []
	if result:
		for row in result:
			items.append(row["item_id"])
	return items

func add_owned_item(item_id: String, item_name: String, price: int):
	var query = "INSERT OR IGNORE INTO owned_items (item_id, item_name, purchase_price) VALUES ('%s', '%s', %d);" % [item_id, item_name, price]
	db.query(query)
	print("Added owned item: ", item_name, " (", item_id, ") for $", price / 100.0)

func is_item_owned(item_id: String) -> bool:
	db.query("SELECT item_id FROM owned_items WHERE item_id = '%s';" % item_id)
	var result = db.query_result
	return result and result.size() > 0

func add_game_session(score: int, duration: int = 0, bird_color: String = ""):
	if not db:
		print("Database not initialized, cannot add game session")
		return
	var query = "INSERT INTO game_sessions (score, duration_seconds, bird_color) VALUES (%d, %d, '%s');" % [score, duration, bird_color]
	db.query(query)

func get_purchase_history() -> Array:
	db.query("SELECT * FROM owned_items ORDER BY purchased_at DESC;")
	var result = db.query_result
	return result if result else []

func get_game_statistics() -> Dictionary:
	var stats = {}
	
	# Total games played
	db.query("SELECT COUNT(*) as count FROM game_sessions;")
	var total_games = db.query_result
	stats["total_games"] = total_games[0]["count"] if total_games and total_games.size() > 0 else 0
	
	# Average score
	db.query("SELECT AVG(score) as avg FROM game_sessions;")
	var avg_score = db.query_result
	stats["average_score"] = avg_score[0]["avg"] if avg_score and avg_score.size() > 0 else 0
	
	# Total spent
	db.query("SELECT SUM(purchase_price) as total FROM owned_items;")
	var total_spent = db.query_result
	stats["total_spent"] = total_spent[0]["total"] if total_spent and total_spent.size() > 0 else 0
	
	return stats

func backup_database() -> bool:
	var backup_path = "res://database/flappy_bird_backup_%s.db" % Time.get_datetime_string_from_system().replace(":", "-")
	return db.backup(backup_path)

func close_database():
	if db:
		db.close()