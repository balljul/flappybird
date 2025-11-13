extends Node

const STRIPE_PUBLISHABLE_KEY = "pk_test_51SSb1YBEhxFSvfVU22QUFfc1B7btYBNeSSdoYVEDuHwuYO0kzTSH9tDPmS4OX632FME76ryNuhWQUXZRN745bXPR00e8UC4epe"
const STRIPE_SECRET_KEY = "sk_test_51SSb1YBEhxFSvfVUJrAa3fNp4gUDXgHAGEz2r7IW1yvXpli5RuGWZlHxAo5IicwOWDS7SF30VEDPaAZ3ZgphH8u900CNtNKEmy"

var http_request: HTTPRequest

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)

func purchase_item(item: Dictionary, callback: Callable):
	print("Starting REAL payment process for: ", item.name)
	create_payment_intent_real(item, callback)

func simulate_payment_flow(item: Dictionary, callback: Callable):
	print("=== SIMULATED STRIPE PAYMENT FLOW ===")
	print("Item: ", item.name)
	print("Price: $", item.price / 100.0)
	print("Processing with Stripe test card...")

	await get_tree().create_timer(2.0).timeout

	var success = randf() > 0.1

	if success:
		print("✅ Payment successful!")
		print("Transaction ID: test_", randi() % 100000)
	else:
		print("❌ Payment failed!")
		print("Error: Card declined")

	callback.call(success, item)

func create_payment_intent_real(item: Dictionary, callback: Callable):
	print("=== REAL STRIPE PAYMENT ===")
	print("Creating payment intent for: ", item.name)
	print("Amount: $", item.price / 100.0)

	var headers = [
		"Authorization: Bearer " + STRIPE_SECRET_KEY,
		"Content-Type: application/x-www-form-urlencoded"
	]

	var body = "amount=" + str(item.price) + "&currency=usd&automatic_payment_methods[enabled]=true"

	if http_request.request_completed.is_connected(_on_payment_intent_created_wrapper):
		http_request.request_completed.disconnect(_on_payment_intent_created_wrapper)

	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request.cancel_request()

	http_request.request_completed.connect(_on_payment_intent_created_wrapper.bind(item, callback), CONNECT_ONE_SHOT)
	var error = http_request.request("https://api.stripe.com/v1/payment_intents", headers, HTTPClient.METHOD_POST, body)

	if error != OK:
		print("Error creating payment request: ", error)
		callback.call(false, item)

func _on_payment_intent_created_wrapper(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, item: Dictionary, callback: Callable):
	_on_payment_intent_created(item, callback, result, response_code, headers, body)

func _on_payment_intent_created(item: Dictionary, callback: Callable, result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("Payment intent response code: ", response_code)

	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		if response:
			print("Payment intent created: ", response.id)
			var client_secret = response.client_secret

			show_card_input_dialog(item, client_secret, callback)
		else:
			print("Failed to parse payment intent response")
			callback.call(false, item)
	else:
		print("Failed to create payment intent: ", response_code)
		print("Response: ", body.get_string_from_utf8())
		callback.call(false, item)

func show_card_input_dialog(item: Dictionary, client_secret: String, callback: Callable):
	print("Showing card input for: ", item.name)

	var dialog = create_card_dialog(item, client_secret, callback)
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()

func create_card_dialog(item: Dictionary, client_secret: String, callback: Callable) -> AcceptDialog:
	var dialog = AcceptDialog.new()
	dialog.title = "Payment for " + item.name
	dialog.size = Vector2(400, 300)

	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)

	var info_label = Label.new()
	info_label.text = "Item: " + item.name + "\nPrice: $" + str(item.price / 100.0)
	vbox.add_child(info_label)

	var card_label = Label.new()
	card_label.text = "\nEnter card details:"
	vbox.add_child(card_label)

	var card_number = LineEdit.new()
	card_number.placeholder_text = "4242 4242 4242 4242 (test card)"
	card_number.name = "card_number"
	vbox.add_child(card_number)

	var expiry = LineEdit.new()
	expiry.placeholder_text = "MM/YY (e.g., 12/25)"
	expiry.name = "expiry"
	vbox.add_child(expiry)

	var cvc = LineEdit.new()
	cvc.placeholder_text = "CVC (e.g., 123)"
	cvc.secret = true
	cvc.name = "cvc"
	vbox.add_child(cvc)

	var pay_button = Button.new()
	pay_button.text = "PAY $" + str(item.price / 100.0)
	pay_button.pressed.connect(_on_pay_button_pressed.bind(dialog, item, client_secret, callback))
	vbox.add_child(pay_button)

	return dialog

func _on_pay_button_pressed(dialog: AcceptDialog, item: Dictionary, client_secret: String, callback: Callable):
	var vbox = dialog.get_child(0) as VBoxContainer
	var card_number = ""
	var expiry = ""
	var cvc = ""

	for child in vbox.get_children():
		if child.name == "card_number":
			card_number = child.text
		elif child.name == "expiry":
			expiry = child.text
		elif child.name == "cvc":
			cvc = child.text

	print("Processing payment with card: ", card_number.substr(0, 4) + "****")

	if card_number.is_empty():
		card_number = "4242424242424242"
		expiry = "12/25"
		cvc = "123"
		print("Using test card for payment")

	if card_number.length() < 16 or expiry.length() < 5 or cvc.length() < 3:
		show_error_dialog("Please fill in all card details correctly")
		return

	dialog.hide()
	confirm_payment(item, client_secret, card_number, expiry, cvc, callback)

func confirm_payment(item: Dictionary, client_secret: String, card_number: String, expiry: String, cvc: String, callback: Callable):
	print("Confirming payment...")

	var expiry_parts = expiry.split("/")
	if expiry_parts.size() != 2:
		callback.call(false, item)
		return

	var exp_month = expiry_parts[0]
	var exp_year = expiry_parts[1]

	var headers = [
		"Authorization: Bearer " + STRIPE_SECRET_KEY,
		"Content-Type: application/x-www-form-urlencoded"
	]

	var body = "payment_method[type]=card"
	body += "&payment_method[card][number]=" + card_number.replace(" ", "")
	body += "&payment_method[card][exp_month]=" + exp_month
	body += "&payment_method[card][exp_year]=20" + exp_year
	body += "&payment_method[card][cvc]=" + cvc

	var intent_id = client_secret.split("_secret_")[0]

	if http_request.request_completed.is_connected(_on_payment_confirmed_wrapper):
		http_request.request_completed.disconnect(_on_payment_confirmed_wrapper)

	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request.cancel_request()

	http_request.request_completed.connect(_on_payment_confirmed_wrapper.bind(item, callback), CONNECT_ONE_SHOT)
	var error = http_request.request("https://api.stripe.com/v1/payment_intents/" + intent_id + "/confirm", headers, HTTPClient.METHOD_POST, body)

	if error != OK:
		print("Error confirming payment: ", error)
		callback.call(false, item)

func _on_payment_confirmed_wrapper(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, item: Dictionary, callback: Callable):
	_on_payment_confirmed(item, callback, result, response_code, headers, body)

func _on_payment_confirmed(item: Dictionary, callback: Callable, result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("Payment confirmation response code: ", response_code)
	print("Full response: ", body.get_string_from_utf8())

	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		if response and response.status == "succeeded":
			print("✅ PAYMENT SUCCESSFUL!")
			print("Transaction ID: ", response.id)
			show_success_dialog("Payment successful! Enjoy your new " + item.name)
			callback.call(true, item)
		else:
			print("❌ Payment failed: ", response.get("last_payment_error", {}).get("message", "Unknown error"))
			print("Payment response status: ", response.get("status", "unknown"))
			show_error_dialog("Payment failed: " + str(response.get("last_payment_error", {}).get("message", "Unknown error")))
			callback.call(false, item)
	else:
		print("Payment confirmation failed: ", response_code)
		print("Response: ", body.get_string_from_utf8())
		show_error_dialog("Payment failed. Please try again.")
		callback.call(false, item)

func show_success_dialog(message: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Success!"
	dialog.dialog_text = message
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func show_error_dialog(message: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Error"
	dialog.dialog_text = message
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func create_payment_intent(amount: int, currency: String = "usd") -> Dictionary:
	var headers = [
		"Authorization: Bearer " + STRIPE_SECRET_KEY,
		"Content-Type: application/x-www-form-urlencoded"
	]

	var body = "amount=" + str(amount) + "&currency=" + currency

	return {"client_secret": "test_secret", "status": "requires_payment_method"}

func handle_stripe_webhook(event_data: Dictionary):
	match event_data.type:
		"payment_intent.succeeded":
			var payment_intent = event_data.data.object
			print("Payment succeeded: ", payment_intent.id)
			# Grant the item to the user
		"payment_intent.payment_failed":
			var payment_intent = event_data.data.object
			print("Payment failed: ", payment_intent.id)
		_:
			print("Unhandled event type: ", event_data.type)
