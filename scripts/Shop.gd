extends Control

@onready var items_container = $VBoxContainer/ItemsContainer
@onready var close_button = $CloseButton

signal shop_closed

var cosmetic_items = [
	{"name": "Red Bird", "price": 1999, "color": Color.RED, "id": "red_bird"},
	{"name": "Blue Bird", "price": 2999, "color": Color.BLUE, "id": "blue_bird"},
	{"name": "Green Bird", "price": 3999, "color": Color.GREEN, "id": "green_bird"},
	{"name": "Purple Bird", "price": 4999, "color": Color.PURPLE, "id": "purple_bird"},
	{"name": "Golden Bird", "price": 9999, "color": Color.GOLD, "id": "golden_bird"},
]

func _ready():
	close_button.pressed.connect(_on_close_pressed)

	var screen_size = get_viewport().get_visible_rect().size
	var container = $VBoxContainer
	var width = min(800, screen_size.x * 0.8)
	var height = min(600, screen_size.y * 0.8)

	container.position = Vector2(screen_size.x * 0.5 - width * 0.5, screen_size.y * 0.5 - height * 0.5)
	container.size = Vector2(width, height)

	close_button.position = Vector2(container.position.x + width - 100, container.position.y)
	close_button.size = Vector2(100, 50)

	print("Shop positioned at: ", container.position, " size: ", container.size)
	print("Close button at: ", close_button.position)

	create_shop_items()

func create_shop_items():
	for item in cosmetic_items:
		create_item_card(item)

func create_item_card(item: Dictionary):
	var card = VBoxContainer.new()
	card.custom_minimum_size = Vector2(180, 150)

	var preview = ColorRect.new()
	preview.color = item.color
	preview.custom_minimum_size = Vector2(150, 100)
	card.add_child(preview)

	var name_label = Label.new()
	name_label.text = item.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_label)

	var buy_button = Button.new()
	buy_button.text = "$" + str(item.price / 100.0) + " USD"

	if GameData.is_item_owned(item.id):
		buy_button.text = "OWNED"
		buy_button.disabled = true
	else:
		buy_button.pressed.connect(_on_buy_item.bind(item))

	card.add_child(buy_button)
	items_container.add_child(card)

func _on_buy_item(item: Dictionary):
	print("Purchasing: ", item.name, " for $", item.price / 100.0)
	PaymentManager.purchase_item(item, _on_purchase_complete)

func _on_purchase_complete(success: bool, item: Dictionary):
	if success:
		GameData.add_owned_item(item.id, item.name, item.price)
		GameData.save_game_data()
		for child in items_container.get_children():
			child.queue_free()
		await get_tree().process_frame
		create_shop_items()
		print("Purchase successful!")
	else:
		print("Purchase failed!")

func _on_close_pressed():
	shop_closed.emit()
	queue_free()
