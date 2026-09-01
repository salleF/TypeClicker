extends PanelContainer

# UpgradeCardItem.gd - Illustrated Roguelike Book Card for Draft Upgrades

signal purchased(upgrade_key: String)

@onready var book_cover: ColorRect = $CardVBox/CoverContainer/BookCover
@onready var symbol_label: Label = $CardVBox/CoverContainer/SymbolLabel
@onready var title_label: Label = $CardVBox/TitleLabel
@onready var category_badge: Label = $CardVBox/CategoryBadge
@onready var level_label: Label = $CardVBox/LevelLabel
@onready var desc_label: Label = $CardVBox/DescLabel
@onready var buy_button: Button = $CardVBox/BuyButton

var current_card_data: Dictionary = {}
var upgrade_key: String = ""

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(card_data: Dictionary) -> void:
	current_card_data = card_data
	upgrade_key = card_data["upgrade_key"]

	var lang = GameManager.language
	var up = GameManager.upgrades[upgrade_key]

	# Set visual cover theme
	book_cover.color = card_data.get("cover_color", Color(0.45, 0.18, 0.15, 1))
	symbol_label.text = card_data.get("symbol", "📖")

	title_label.text = card_data["title"][lang]
	category_badge.text = "[ %s ]" % card_data["category"][lang]
	desc_label.text = card_data["description"][lang]

	var is_max = up["level"] >= up["max_level"]
	var cost = GameManager.get_upgrade_cost(upgrade_key)
	var can_afford = GameManager.can_afford_upgrade(upgrade_key)

	if up["max_level"] > 1:
		level_label.text = "Nível %d / %d" % [up["level"], up["max_level"]] if lang == "pt" else "Level %d / %d" % [up["level"], up["max_level"]]
	else:
		level_label.text = "Tomo Único" if lang == "pt" else "Unique Tome"

	if is_max:
		buy_button.text = "Comprado" if lang == "pt" else "Owned"
		buy_button.disabled = true
	else:
		var curr_icon = "📜" if up["currency"] == "culture" else "✒️"
		buy_button.text = "Adquirir: %s %d" % [curr_icon, cost] if lang == "pt" else "Acquire: %s %d" % [curr_icon, cost]
		buy_button.disabled = !can_afford

func _on_buy_pressed() -> void:
	if GameManager.buy_upgrade(upgrade_key):
		SoundManager.play_upgrade_buy()
		purchased.emit(upgrade_key)

func _on_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.1)

func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
