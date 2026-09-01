extends Control

# PauseModal.gd - In-game Pause Menu with Progress Reset for testing

signal resumed()
signal progress_reset()

@onready var title_label: Label = $ModalBackground/HeaderBar/TitleLabel
@onready var status_label: Label = $ModalBackground/StatusLabel
@onready var resume_button: Button = $ModalBackground/ButtonsContainer/ResumeButton
@onready var reset_button: Button = $ModalBackground/ButtonsContainer/ResetButton
@onready var quit_button: Button = $ModalBackground/ButtonsContainer/QuitButton
@onready var feedback_label: Label = $ModalBackground/FeedbackLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(resume_game)
	reset_button.pressed.connect(_on_reset_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_update_language()

func open_pause() -> void:
	visible = true
	feedback_label.text = ""
	_update_language()
	SoundManager.play_paper_insert()

func resume_game() -> void:
	visible = false
	SoundManager.play_paper_rip()
	resumed.emit()

func _on_reset_pressed() -> void:
	GameManager.reset_progress()
	SoundManager.play_paper_crumple()
	_update_language()
	feedback_label.text = "✓ Progresso Zerado com Sucesso! (0 Gotas de Tinta)" if GameManager.language == "pt" else "✓ Progress Reset Successfully! (0 Ink Drops)"
	progress_reset.emit()

func _on_quit_pressed() -> void:
	get_tree().quit(0)

func _update_language() -> void:
	var lang = GameManager.language
	if title_label:
		title_label.text = "⏸️ Jogo Pausado" if lang == "pt" else "⏸️ Game Paused"
	if status_label:
		status_label.text = "✒️ %d %s no Frasco | 📄 %d Folhas Concluídas" % [
			int(GameManager.points),
			"Gotas de Tinta" if lang == "pt" else "Ink Drops",
			GameManager.career_sheets_completed
		]
	if resume_button:
		resume_button.text = "▶️ Continuar Escrevendo (ESC)" if lang == "pt" else "▶️ Resume Writing (ESC)"
	if reset_button:
		reset_button.text = "🔄 Reiniciar Todo o Progresso (Zerar Tinta e Tomos)" if lang == "pt" else "🔄 Reset All Progress (Clear Ink & Upgrades)"
	if quit_button:
		quit_button.text = "🚪 Sair do Jogo" if lang == "pt" else "🚪 Quit Game"

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		resume_game()
		get_viewport().set_input_as_handled()
