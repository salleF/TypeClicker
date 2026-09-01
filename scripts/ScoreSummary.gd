extends Control

# ScoreSummary.gd - Run-end score summary card displayed when a paper sheet is crumpled

signal play_again_requested()
signal open_book_requested()

@onready var reason_label: Label = $Card/ReasonLabel
@onready var points_value_label: Label = $Card/StatsGrid/PointsBox/ValueLabel
@onready var culture_value_label: Label = $Card/StatsGrid/CultureBox/ValueLabel
@onready var words_count_label: Label = $Card/StatsGrid/WordsBox/ValueLabel
@onready var sheets_count_label: Label = $Card/StatsGrid/SheetsBox/ValueLabel
@onready var play_again_btn: Button = $Card/ButtonsContainer/PlayAgainButton
@onready var open_book_btn: Button = $Card/ButtonsContainer/OpenBookButton

func _ready() -> void:
	play_again_btn.pressed.connect(_on_play_again_pressed)
	open_book_btn.pressed.connect(_on_open_book_pressed)
	visible = false

func show_summary(summary: Dictionary) -> void:
	reason_label.text = "🗑️ " + summary.get("reason", "Folha descartada!")
	points_value_label.text = "+%d" % summary.get("total_score", 0)
	culture_value_label.text = "+%d" % summary.get("total_culture", 0)
	words_count_label.text = str(summary.get("words_count", 0))
	sheets_count_label.text = str(summary.get("sheets_completed", 0))

	visible = true

	# Pop-in tween
	scale = Vector2(0.9, 0.9)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_summary() -> void:
	visible = false

func _on_play_again_pressed() -> void:
	hide_summary()
	play_again_requested.emit()

func _on_open_book_pressed() -> void:
	hide_summary()
	open_book_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		_on_play_again_pressed()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_L:
		_on_open_book_pressed()
		get_viewport().set_input_as_handled()
