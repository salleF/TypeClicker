extends Node2D

# CoffeeCup.gd - Steaming coffee cup on the right side of the desk

@onready var steam_particles: CPUParticles2D = $SteamParticles
@onready var coffee_glow: ColorRect = $GlowEffect
@onready var buff_label: Label = $BuffLabel

func _ready() -> void:
	GameManager.coffee_buff_started.connect(_on_coffee_buff_started)
	GameManager.coffee_buff_ended.connect(_on_coffee_buff_ended)
	_update_buff_visual(false)

func _process(_delta: float) -> void:
	if GameManager.is_coffee_active:
		buff_label.text = "2x COFFEE\n%.1fs" % GameManager.coffee_time_remaining
	else:
		buff_label.text = ""

func _on_coffee_buff_started(_multiplier: float, _duration: float) -> void:
	_update_buff_visual(true)
	steam_particles.amount = 16
	steam_particles.speed_scale = 1.5

func _on_coffee_buff_ended() -> void:
	_update_buff_visual(false)
	steam_particles.amount = 8
	steam_particles.speed_scale = 1.0

func _update_buff_visual(active: bool) -> void:
	coffee_glow.visible = active
	buff_label.visible = active

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		SoundManager.play_coffee_serve()
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.1, 0.9), 0.08)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
