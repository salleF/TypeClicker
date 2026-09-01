extends Node2D

# DeskBook.gd - Physical interactive upgrade book on the desk

signal book_clicked()

@onready var book_body: Polygon2D = $BookBody
@onready var glow_effect: ColorRect = $GlowEffect
@onready var bookmark_tag: Label = $BookmarkTag
@onready var area: Area2D = $Area2D

var is_highlighted: bool = false
var pulse_tween: Tween

func _ready() -> void:
	area.input_event.connect(_on_input_event)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	set_highlight(true)

func set_highlight(active: bool) -> void:
	is_highlighted = active
	glow_effect.visible = active
	bookmark_tag.visible = active

	if active:
		if pulse_tween:
			pulse_tween.kill()
		pulse_tween = create_tween().set_loops()
		pulse_tween.tween_property(glow_effect, "modulate:a", 0.8, 0.6)
		pulse_tween.tween_property(glow_effect, "modulate:a", 0.2, 0.6)
	else:
		if pulse_tween:
			pulse_tween.kill()
		glow_effect.visible = false

func _on_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)

func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.06)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)
		book_clicked.emit()
