extends Node2D

# WaitressEvent.gd - Periodic Golden Cookie style Coffee Waitress event

@onready var waitress_body: Node2D = $WaitressBody
@onready var speech_bubble: Button = $WaitressBody/SpeechBubble
@onready var sparkle_particles: CPUParticles2D = $WaitressBody/SparkleParticles

var is_present: bool = false
var presence_timer: float = 0.0
var max_presence_duration: float = 6.0

# Spawn timing
var check_interval: float = 8.0
var time_since_last_check: float = 0.0

func _ready() -> void:
	speech_bubble.pressed.connect(_on_speech_bubble_pressed)
	waitress_body.position.y = 80 # hidden below counter
	waitress_body.visible = false

func _process(delta: float) -> void:
	if is_present:
		presence_timer -= delta
		if presence_timer <= 0.0:
			dismiss_waitress(false)
	else:
		time_since_last_check += delta
		if time_since_last_check >= check_interval:
			time_since_last_check = 0.0
			_try_spawn_waitress()

func _try_spawn_waitress() -> void:
	# Don't spawn if coffee is already active
	if GameManager.is_coffee_active:
		return

	# Calculate spawn probability (boosted by Hospitality upgrade)
	var base_chance = 0.35 * GameManager.get_waitress_spawn_rate_multiplier()
	if randf() < base_chance:
		spawn_waitress()

func spawn_waitress() -> void:
	is_present = true
	presence_timer = max_presence_duration
	waitress_body.visible = true

	# Slide up from behind cafe counter
	var tween = create_tween()
	tween.tween_property(waitress_body, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Pulse speech bubble
	var bubble_tween = create_tween().set_loops()
	bubble_tween.tween_property(speech_bubble, "scale", Vector2(1.08, 1.08), 0.4)
	bubble_tween.tween_property(speech_bubble, "scale", Vector2(1.0, 1.0), 0.4)

func dismiss_waitress(accepted: bool) -> void:
	is_present = false
	if accepted:
		sparkle_particles.restart()
		sparkle_particles.emitting = true
		SoundManager.play_coffee_serve()
		GameManager.activate_coffee_buff()

	var tween = create_tween()
	tween.tween_property(waitress_body, "position:y", 80.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): waitress_body.visible = false)

func _on_speech_bubble_pressed() -> void:
	if is_present:
		dismiss_waitress(true)
