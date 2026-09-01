extends Camera2D

# ShakyCamera2D.gd - Trauma-based camera shake with quadratic decay and hitstop for TypeClicker

@export var decay: float = 0.8
@export var max_offset: Vector2 = Vector2(30, 20)
@export var max_roll: float = 0.04

var noise: FastNoiseLite
var trauma: float = 0.0
var time: float = 0.0

func _ready() -> void:
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.18
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = max(trauma - decay * delta, 0.0)
		time += delta * 45.0
		var shake = trauma * trauma # Quadratic response for organic punch
		offset.x = max_offset.x * shake * noise.get_noise_2d(time, 0.0)
		offset.y = max_offset.y * shake * noise.get_noise_2d(0.0, time)
		rotation = max_roll * shake * noise.get_noise_2d(time, time)
	else:
		offset = Vector2.ZERO
		rotation = 0.0

func hit_stop(time_scale: float = 0.05, duration: float = 0.04) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration * time_scale, true, false, true).timeout
	Engine.time_scale = 1.0
