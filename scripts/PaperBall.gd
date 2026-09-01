extends Node2D

# PaperBall.gd - Crumpled paper ball that arcs from the typewriter into the trash bin

var start_pos: Vector2
var target_pos: Vector2
var duration: float = 0.55
var elapsed: float = 0.0
var trash_bin_ref: Node2D = null

@onready var sprite: Polygon2D = $BallShape

func launch(from_pos: Vector2, to_pos: Vector2, trash_bin: Node2D) -> void:
	global_position = from_pos
	start_pos = from_pos
	target_pos = to_pos
	trash_bin_ref = trash_bin
	elapsed = 0.0

	SoundManager.play_paper_crumple()

	# Spin tween
	var tween = create_tween()
	tween.tween_property(self, "rotation", TAU * 3.0, duration)

func _process(delta: float) -> void:
	if elapsed < duration:
		elapsed += delta
		var t = clamp(elapsed / duration, 0.0, 1.0)

		# Parabolic arc
		var height_arc = sin(t * PI) * -160.0
		var current_x = lerp(start_pos.x, target_pos.x, t)
		var current_y = lerp(start_pos.y, target_pos.y, t) + height_arc

		global_position = Vector2(current_x, current_y)

		if t >= 1.0:
			_on_landed()

func _on_landed() -> void:
	if trash_bin_ref and is_instance_valid(trash_bin_ref):
		trash_bin_ref.call("receive_paper_ball")

	queue_free()
