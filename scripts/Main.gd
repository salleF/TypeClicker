extends Node2D

# Main.gd - Diegetic master scene controller with cafe interior in depth and foreground typewriter

@onready var camera: Camera2D = $ShakyCamera2D
@onready var typewriter: Node2D = $Environment/Typewriter
@onready var coffee_cup: Node2D = $Environment/CoffeeCup
@onready var desk_book: Node2D = $Environment/DeskBook
@onready var trash_bin: Node2D = $Environment/TrashBin
@onready var waitress: Node2D = $Environment/WaitressEvent
@onready var upgrade_book_modal: Control = $UI/UpgradeBookModal
@onready var pause_modal: Control = $UI/PauseModal
@onready var lang_button: Button = $UI/DeskOverlay/LangButton

func _ready() -> void:
	# Connect GameManager signals
	GameManager.points_updated.connect(_on_points_updated)
	GameManager.coffee_buff_started.connect(_on_coffee_buff_started)
	GameManager.coffee_buff_ended.connect(_on_coffee_buff_ended)
	GameManager.paper_crumpled.connect(_on_paper_crumpled)
	GameManager.sheet_started.connect(_on_sheet_started)
	GameManager.sheet_completed.connect(_on_sheet_completed)

	# Connect Typewriter signals for juice
	typewriter.paper_failed.connect(_on_paper_failed)
	typewriter.sheet_finished.connect(_on_typewriter_sheet_finished)

	# Connect Desk Book & Language
	desk_book.book_clicked.connect(_on_open_book_pressed)
	lang_button.focus_mode = Control.FOCUS_NONE
	lang_button.pressed.connect(_on_toggle_language_pressed)
	upgrade_book_modal.closed.connect(_on_book_closed)

	# Connect Pause Modal
	pause_modal.progress_reset.connect(_on_progress_reset)

	_update_language_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if upgrade_book_modal.visible:
				upgrade_book_modal.close_book()
				get_viewport().set_input_as_handled()
			elif pause_modal.visible:
				pause_modal.resume_game()
				get_viewport().set_input_as_handled()
			else:
				pause_modal.open_pause()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_L and not upgrade_book_modal.visible and not pause_modal.visible:
			_on_open_book_pressed()
			get_viewport().set_input_as_handled()

func _on_progress_reset() -> void:
	typewriter._set_idle_state()
	desk_book.set_highlight(true)
	_update_language_ui()

func _on_points_updated(_pts: float) -> void:
	pass

func _on_coffee_buff_started(_mult: float, _dur: float) -> void:
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.1)

func _on_coffee_buff_ended() -> void:
	pass

func _on_paper_crumpled(_reason: String) -> void:
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.35)
	# Highlight the book on the desk to invite player to check upgrades
	desk_book.set_highlight(true)

func _on_paper_failed(_reason: String) -> void:
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.2)

func _on_typewriter_sheet_finished(_index: int) -> void:
	if camera and camera.has_method("hit_stop"):
		camera.hit_stop(0.05, 0.04)

func _on_sheet_completed(_index: int, _score: int) -> void:
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.15)

func _on_sheet_started(_index: int, _is_special: bool, _type: String) -> void:
	# Turn off glowing highlight once typing resumes
	desk_book.set_highlight(false)

func _on_open_book_pressed() -> void:
	upgrade_book_modal.open_book()

func _on_book_closed() -> void:
	pass

func _on_toggle_language_pressed() -> void:
	lang_button.release_focus()
	GameManager.language = "en" if GameManager.language == "pt" else "pt"
	GameManager.save_game()
	_update_language_ui()
	typewriter._set_idle_state()

func _update_language_ui() -> void:
	var lang = GameManager.language
	lang_button.text = "🇧🇷 Idioma: PT" if lang == "pt" else "🇺🇸 Language: EN"
