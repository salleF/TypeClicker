extends Node2D

# TrashBin.gd - Wastebasket on the left side where crumpled papers land

@onready var bin_sprite: Polygon2D = $BinBody
@onready var dust_particles: CPUParticles2D = $DustParticles
@onready var count_label: Label = $CountLabel

func _ready() -> void:
	_update_count()

func _update_count() -> void:
	if count_label:
		count_label.text = str(GameManager.career_crumpled_papers)

func receive_paper_ball() -> void:
	_update_count()
	dust_particles.restart()
	dust_particles.emitting = true
	SoundManager.play_trash_thud()

	# Wobble animation
	var tween = create_tween()
	tween.tween_property(self, "rotation", 0.08, 0.05)
	tween.tween_property(self, "rotation", -0.08, 0.08)
	tween.tween_property(self, "rotation", 0.04, 0.06)
	tween.tween_property(self, "rotation", 0.0, 0.05)
