extends Node2D

# Typewriter.gd - Close-up POV mechanical typewriter with diegetic brass odometer point counter

signal word_typed(word_data: Dictionary, points_earned: int)
signal sheet_finished(sheet_index: int)
signal paper_failed(reason: String)

const PAPER_BALL_SCENE = preload("res://scenes/PaperBall.tscn")
const FLOATING_TEXT_SCENE = preload("res://scenes/FloatingScoreText.tscn")

@export var trash_bin_path: NodePath
var trash_bin_node: Node2D = null

# Nodes
@onready var paper_node: Polygon2D = $PaperSheet
@onready var current_word_label: RichTextLabel = $PaperSheet/CurrentWordLabel
@onready var category_label: Label = $PaperSheet/CategoryLabel
@onready var sheet_info_label: Label = $PaperSheet/SheetInfoLabel
@onready var thinking_progress: ProgressBar = $PaperSheet/ThinkingProgressBar
@onready var writing_timer_label: Label = $PaperSheet/WritingTimerLabel
@onready var prompt_panel: Panel = $PromptInsertPanel
@onready var prompt_label: Label = $PromptInsertPanel/PromptLabel
@onready var prompt_button: Button = $PromptInsertPanel/InsertButton
@onready var hammer_strike: Polygon2D = $HammerStrike

# Diegetic Brass Odometer Plate
@onready var brass_plate: Polygon2D = $BrassCounterPlate
@onready var brass_counter_label: Label = $BrassCounterPlate/CounterLabel
@onready var brass_record_label: Label = $BrassCounterPlate/RecordLabel
@onready var coffee_buff_badge: Label = $BrassCounterPlate/CoffeeBuffBadge

# Typing State
var is_active: bool = false
var current_word_data: Dictionary = {}
var target_text: String = ""
var typed_index: int = 0

# Timers
var thinking_time_max: float = 0.5
var thinking_time_current: float = 0.5
var writing_time_current: float = 10.0
var has_started_typing_first_letter: bool = false

func _ready() -> void:
	if not trash_bin_path.is_empty():
		trash_bin_node = get_node_or_null(trash_bin_path)

	prompt_button.pressed.connect(insert_new_sheet)
	GameManager.points_updated.connect(_on_points_updated)
	GameManager.coffee_buff_started.connect(_on_coffee_buff_started)
	GameManager.coffee_buff_ended.connect(_on_coffee_buff_ended)

	_update_brass_plate()
	_set_idle_state()

func _process(delta: float) -> void:
	if is_active:
		# 1. Total Sheet Writing Timer
		writing_time_current -= delta
		_update_writing_timer_display()
		if writing_time_current <= 0.0:
			fail_run("Tempo da folha esgotado!" if GameManager.language == "pt" else "Sheet time ran out!")
			return

		# 2. Thinking Timer (Active once player types first key on current word)
		if has_started_typing_first_letter:
			thinking_time_current -= delta
			thinking_progress.value = (thinking_time_current / thinking_time_max) * 100.0
			if thinking_time_current <= 0.0:
				fail_run("Tempo de pensamento esgotado!" if GameManager.language == "pt" else "Hesitation timeout!")
				return

	if GameManager.is_coffee_active:
		coffee_buff_badge.visible = true
		coffee_buff_badge.text = "☕ 2x (%.0fs)" % GameManager.coffee_time_remaining
	else:
		coffee_buff_badge.visible = false

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return

	# If idle, space or enter starts run immediately
	if not is_active:
		if event.is_action_pressed("ui_accept") or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			insert_new_sheet()
			get_viewport().set_input_as_handled()
		return

	# Active typing
	var char_typed = OS.get_keycode_string(event.key_label if event.key_label != KEY_NONE else event.keycode).to_lower()
	if char_typed.length() == 0:
		return

	if event is InputEventKey and event.unicode > 0:
		char_typed = char(event.unicode).to_lower()

	_handle_character_input(char_typed)
	get_viewport().set_input_as_handled()

func insert_new_sheet() -> void:
	is_active = true
	has_started_typing_first_letter = false

	# Setup timers from GameManager upgrades
	thinking_time_max = GameManager.get_thinking_time_limit()
	thinking_time_current = thinking_time_max
	writing_time_current = GameManager.get_writing_time_base()

	if not GameManager.is_run_active:
		GameManager.start_new_run()
	else:
		GameManager.start_new_sheet()

	SoundManager.play_paper_insert()

	# Visual paper slide animation into carriage
	paper_node.position.y = 120
	var tween = create_tween()
	tween.tween_property(paper_node, "position:y", -60.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	prompt_panel.visible = false
	paper_node.visible = true

	_next_word()
	_update_sheet_header()

func _next_word() -> void:
	typed_index = 0
	has_started_typing_first_letter = false
	thinking_time_current = thinking_time_max
	thinking_progress.value = 100.0

	var unlocked_cats = GameManager.get_unlocked_categories()
	current_word_data = WordDatabase.get_paced_word(GameManager.current_sheet_words_typed, unlocked_cats, GameManager.language)
	target_text = current_word_data["text"]

	_update_word_display()
	_update_sheet_header()

func _handle_character_input(char_typed: String) -> void:
	if typed_index >= target_text.length():
		return

	var expected_char = target_text[typed_index].to_lower()

	if char_typed == expected_char:
		# Correct letter
		has_started_typing_first_letter = true
		thinking_time_current = thinking_time_max
		thinking_progress.value = 100.0

		typed_index += 1
		SoundManager.play_key_clack(current_word_data.get("base_points", 0) > 40)
		_animate_hammer()
		_apply_key_recoil()

		_update_word_display()

		# Word Completed!
		if typed_index >= target_text.length():
			_on_word_completed()
	else:
		# Typo!
		SoundManager.play_mistake()
		fail_run("Letra errada!" if GameManager.language == "pt" else "Typo!")

func _on_word_completed() -> void:
	# Add bonus time from stamina upgrade
	var bonus_time = GameManager.get_writing_time_bonus()
	writing_time_current += bonus_time

	var points_earned = GameManager.record_word_completed(current_word_data)
	word_typed.emit(current_word_data, points_earned)

	# Spawn floating score text
	_spawn_floating_score("+%d ✒️" % points_earned, Color(0.98, 0.85, 0.45, 1.0))
	_update_brass_plate()

	# Check if sheet is full (5 words)
	if GameManager.current_sheet_words_typed >= GameManager.words_per_sheet:
		# Page completed: Bell ding followed by Next Page sound
		SoundManager.play_page_complete()
		sheet_finished.emit(GameManager.sheets_completed_in_run + 1)
		GameManager.complete_current_sheet()

		# Sheet slide animation
		var tween = create_tween()
		tween.tween_property(paper_node, "position:y", -170.0, 0.15)
		tween.tween_property(paper_node, "position:y", -60.0, 0.2)
		tween.tween_callback(func():
			_next_word()
			_update_sheet_header()
		)
	else:
		# Line completed on the same sheet: carriage return lever pulled
		SoundManager.play_word_lever()
		_next_word()

func fail_run(reason: String) -> void:
	if not is_active:
		return

	is_active = false
	GameManager.crumple_paper(reason)

	# Spawn paper ball flying smoothly into the trash bin
	_spawn_paper_ball()

	paper_node.visible = false
	_set_idle_state()
	_update_brass_plate()
	paper_failed.emit(reason)

func _spawn_paper_ball() -> void:
	var ball = PAPER_BALL_SCENE.instantiate()
	var spawn_pos = global_position + Vector2(0, -40)
	var target_pos = Vector2(160, 560)
	if trash_bin_node and is_instance_valid(trash_bin_node):
		target_pos = trash_bin_node.global_position + Vector2(0, -30)

	get_parent().add_child(ball)
	ball.launch(spawn_pos, target_pos, trash_bin_node)

func _set_idle_state() -> void:
	is_active = false
	prompt_panel.visible = true
	paper_node.visible = false
	prompt_label.text = "Pressione ESPAÇO para Inserir Folha" if GameManager.language == "pt" else "Press SPACE to Insert Sheet"
	prompt_button.text = "📄 Inserir Folha (Espaço)" if GameManager.language == "pt" else "📄 Insert Sheet (Space)"
	_update_brass_plate()

func _update_sheet_header() -> void:
	var sheet_num = GameManager.sheets_completed_in_run + 1
	var sheet_mult = GameManager.get_sheet_multiplier()
	var special_txt = ""
	if GameManager.is_special_sheet:
		if GameManager.special_sheet_type == "golden":
			special_txt = " [DOURADA 3x]" if GameManager.language == "pt" else " [GOLDEN 3x]"
		elif GameManager.special_sheet_type == "coffee_stained":
			special_txt = " [CAFÉ 2x]" if GameManager.language == "pt" else " [COFFEE 2x]"

	sheet_info_label.text = "Folha #%d (%.1fx)%s" % [sheet_num, sheet_mult, special_txt]
	category_label.text = current_word_data.get("category_name", "")

func _update_writing_timer_display() -> void:
	writing_timer_label.text = "⏰ %.1fs" % max(0.0, writing_time_current)
	if writing_time_current < 3.0:
		writing_timer_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 1.0))
	else:
		writing_timer_label.add_theme_color_override("font_color", Color(0.29, 0.12, 0.11, 1.0))

func _update_word_display() -> void:
	var bbcode = "[center]"

	# Typed letters in dark vintage ink
	var typed_part = target_text.substr(0, typed_index)
	bbcode += "[color=#4A1E1B][b]" + typed_part + "[/b][/color]"

	# Current character highlighted with cursor
	if typed_index < target_text.length():
		var current_char = target_text[typed_index]
		bbcode += "[color=#BC5D3B][u][b]" + current_char + "[/b][/u][/color]"

		# Remaining letters in soft sepia
		var remaining_part = target_text.substr(typed_index + 1)
		bbcode += "[color=#A7584A]" + remaining_part + "[/color]"

	bbcode += "[/center]"
	current_word_label.text = bbcode

func _animate_hammer() -> void:
	hammer_strike.visible = true
	hammer_strike.position.y = 8
	var tween = create_tween()
	tween.tween_property(hammer_strike, "position:y", -24.0, 0.04)
	tween.tween_property(hammer_strike, "position:y", 8.0, 0.05)
	tween.tween_callback(func(): hammer_strike.visible = false)

func _apply_key_recoil() -> void:
	scale = Vector2(1.015, 0.985)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _spawn_floating_score(text: String, color: Color) -> void:
	var float_obj = FLOATING_TEXT_SCENE.instantiate()
	float_obj.position = global_position + Vector2(randf_range(-60, 60), -120)
	get_parent().add_child(float_obj)
	float_obj.setup(text, color)

func _on_points_updated(_pts: float) -> void:
	_update_brass_plate()

func _on_coffee_buff_started(_mult: float, _dur: float) -> void:
	_update_brass_plate()

func _on_coffee_buff_ended() -> void:
	_update_brass_plate()

func _update_brass_plate() -> void:
	var lang = GameManager.language
	brass_counter_label.text = "✒️ %d %s" % [int(GameManager.points), "Tinta" if lang == "pt" else "Ink"]
	brass_record_label.text = "🏆 %s: %d" % ["Recorde" if lang == "pt" else "Best", GameManager.highest_run_score]
