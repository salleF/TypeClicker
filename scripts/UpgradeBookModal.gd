extends Control

# UpgradeBookModal.gd - Displays the 3 drafted Roguelike Book Cards for upgrade selection

signal closed()

const UPGRADE_CARD_SCENE = preload("res://scenes/UpgradeCardItem.tscn")

@onready var points_label: Label = $ModalBackground/HeaderBar/PointsLabel
@onready var cards_container: HBoxContainer = $ModalBackground/CardsContainer
@onready var reroll_button: Button = $ModalBackground/FooterBar/RerollButton
@onready var close_button: Button = $ModalBackground/FooterBar/CloseButton
@onready var close_x_button: Button = $ModalBackground/HeaderBar/CloseXButton

func _ready() -> void:
	close_button.pressed.connect(close_book)
	close_x_button.pressed.connect(close_book)
	reroll_button.pressed.connect(_on_reroll_pressed)
	GameManager.points_updated.connect(_on_points_updated)
	GameManager.draft_upgrades_rolled.connect(_on_draft_rolled)
	visible = false

func open_book() -> void:
	visible = true
	SoundManager.play_paper_insert()
	_update_header()
	_populate_cards()

func close_book() -> void:
	visible = false
	SoundManager.play_paper_rip()
	closed.emit()

func _on_points_updated(_pts: float) -> void:
	if visible:
		_update_header()
		_populate_cards()

func _on_draft_rolled(_cards: Array) -> void:
	if visible:
		_populate_cards()

func _on_reroll_pressed() -> void:
	if GameManager.reroll_draft_with_cost():
		SoundManager.play_paper_rip()
		_update_header()
		_populate_cards()

func _update_header() -> void:
	var lang = GameManager.language
	points_label.text = "✒️ %d %s Disponíveis" % [int(GameManager.points), "Gotas de Tinta" if lang == "pt" else "Ink Drops"]
	reroll_button.text = "🎲 Re-rolar Tomos (R) - 2 ✒️" if lang == "pt" else "🎲 Re-roll Tomes (R) - 2 ✒️"
	close_button.text = "Voltar à Máquina (ESC)" if lang == "pt" else "Back to Typewriter (ESC)"

func _populate_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()

	for card_data in GameManager.current_draft_cards:
		var card_node = UPGRADE_CARD_SCENE.instantiate()
		cards_container.add_child(card_node)
		card_node.setup(card_data)
		card_node.purchased.connect(func(_key): _populate_cards())

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			close_book()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			_on_reroll_pressed()
			get_viewport().set_input_as_handled()
