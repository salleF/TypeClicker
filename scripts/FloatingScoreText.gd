extends Node2D

# FloatingScoreText.gd - Floating animated score numbers that jump from typewriter paper

@onready var label: Label = $Label

var velocity: Vector2 = Vector2.ZERO
var duration: float = 0.8
var elapsed: float = 0.0
var initial_scale: Vector2 = Vector2(1.4, 1.4)

func setup(text: String, color: Color = Color(0.96, 0.75, 0.4, 1.0), is_culture: bool = false) -> void:
	if label == null:
		label = $Label
	label.text = text
	label.add_theme_color_override("font_color", color)

	# Initial squash and random rotation
	scale = initial_scale
	rotation = randf_range(-0.15, 0.15)
	velocity = Vector2(randf_range(-30, 30), randf_range(-140, -180))

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration).set_delay(0.3)
	tween.tween_callback(queue_free)

func _process(delta: float) -> void:
	elapsed += delta
	velocity.y += 200.0 * delta # gentle gravity
	position += velocity * delta
