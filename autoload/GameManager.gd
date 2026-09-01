extends Node

# GameManager.gd - Central state, single Ink currency, and roguelike draft upgrade system

signal points_updated(points: float)
signal coffee_buff_started(multiplier: float, duration: float)
signal coffee_buff_ended()
signal sheet_started(sheet_index: int, is_special: bool, special_type: String)
signal sheet_completed(sheet_index: int, sheet_score: int)
signal paper_crumpled(reason: String)
signal upgrade_purchased(upgrade_id: String, new_level: int)
signal draft_upgrades_rolled(draft_list: Array)

const SAVE_PATH = "user://typeclicker_save.json"

# Single Currency & Lifetime Stats
var points: float = 0.0
var career_words_typed: int = 0
var career_sheets_completed: int = 0
var career_crumpled_papers: int = 0
var highest_run_score: int = 0

# Current Run State
var is_run_active: bool = false
var sheets_completed_in_run: int = 0
var current_sheet_words_typed: int = 0
var words_per_sheet: int = 5
var current_sheet_score: int = 0
var is_special_sheet: bool = false
var special_sheet_type: String = ""

# Coffee Buff
var is_coffee_active: bool = false
var coffee_time_remaining: float = 0.0
var coffee_duration_base: float = 15.0

# Settings
var language: String = "pt"
var sfx_volume: float = 0.8
var sound_enabled: bool = true

# Upgrades Core State (All using Ink Points - 1 Word = 1 Ink Drop Base Economy)
var upgrades = {
	"long_word_bonus": {
		"level": 0,
		"max_level": 1,
		"base_cost": 20,
		"cost_scale": 1.0,
		"currency": "points",
		"base_val": 1.0,
		"val_per_lvl": 1.0 # Gives 2x points for 7+ letter words
	},
	"thinking_time": {
		"level": 0,
		"max_level": 8,
		"base_cost": 6,
		"cost_scale": 1.45,
		"currency": "points",
		"base_val": 0.5,
		"val_per_lvl": 0.15
	},
	"writing_time_base": {
		"level": 0,
		"max_level": 8,
		"base_cost": 8,
		"cost_scale": 1.45,
		"currency": "points",
		"base_val": 10.0,
		"val_per_lvl": 2.0
	},
	"writing_time_per_word": {
		"level": 0,
		"max_level": 8,
		"base_cost": 12,
		"cost_scale": 1.5,
		"currency": "points",
		"base_val": 0.0,
		"val_per_lvl": 0.35
	},
	"letter_score_multiplier": {
		"level": 0,
		"max_level": 5,
		"base_cost": 15,
		"cost_scale": 1.55,
		"currency": "points",
		"base_val": 1.0,
		"val_per_lvl": 0.25
	},
	"sheet_multiplier_bonus": {
		"level": 0,
		"max_level": 8,
		"base_cost": 20,
		"cost_scale": 1.6,
		"currency": "points",
		"base_val": 1.0,
		"val_per_lvl": 0.25
	},
	"special_sheet_chance": {
		"level": 0,
		"max_level": 5,
		"base_cost": 30,
		"cost_scale": 1.7,
		"currency": "points",
		"base_val": 0.0,
		"val_per_lvl": 0.06
	},
	"waitress_frequency": {
		"level": 0,
		"max_level": 6,
		"base_cost": 18,
		"cost_scale": 1.5,
		"currency": "points",
		"base_val": 1.0,
		"val_per_lvl": 0.35
	},
	"coffee_power": {
		"level": 0,
		"max_level": 6,
		"base_cost": 25,
		"cost_scale": 1.6,
		"currency": "points",
		"base_val": 2.0,
		"val_per_lvl": 0.5
	},
	"lexicon_literature": { "level": 0, "max_level": 1, "base_cost": 12, "cost_scale": 1.0, "currency": "points", "category_key": "literature" },
	"lexicon_engineering": { "level": 0, "max_level": 1, "base_cost": 20, "cost_scale": 1.0, "currency": "points", "category_key": "engineering" },
	"lexicon_poetry": { "level": 0, "max_level": 1, "base_cost": 28, "cost_scale": 1.0, "currency": "points", "category_key": "poetry" },
	"lexicon_gastronomy": { "level": 0, "max_level": 1, "base_cost": 38, "cost_scale": 1.0, "currency": "points", "category_key": "gastronomy" },
	"lexicon_philosophy": { "level": 0, "max_level": 1, "base_cost": 50, "cost_scale": 1.0, "currency": "points", "category_key": "philosophy" }
}

# Roguelite Tomes Catalog
var book_cards_catalog = [
	{
		"upgrade_key": "long_word_bonus",
		"title": {"pt": "Verborragia Erudita", "en": "Grandiloquence"},
		"category": {"pt": "Erudição Rara", "en": "Rare Erudition"},
		"description": {"pt": "Palavras com 7 ou mais letras concedem o DOBRO de tinta (2x).", "en": "Words with 7 or more letters grant DOUBLE ink (2x)."},
		"cover_color": Color(0.85, 0.45, 0.15, 1),
		"symbol": "💎"
	},
	{
		"upgrade_key": "lexicon_poetry",
		"title": {"pt": "Poesias ao Vento", "en": "Poems in the Wind"},
		"category": {"pt": "Acervo Poético", "en": "Poetic Lore"},
		"description": {"pt": "Desbloqueia palavras líricas e românticas com grande bônus de tinta.", "en": "Unlocks lyrical romantic words with massive ink bonus."},
		"cover_color": Color(0.65, 0.35, 0.45, 1),
		"symbol": "🍃"
	},
	{
		"upgrade_key": "lexicon_literature",
		"title": {"pt": "Crônicas Antigas", "en": "Ancient Chronicles"},
		"category": {"pt": "Literatura Clássica", "en": "Classic Lore"},
		"description": {"pt": "Adiciona vocabulário clássico e erudito com tinta extra.", "en": "Adds classic literature vocabulary with bonus ink."},
		"cover_color": Color(0.55, 0.25, 0.22, 1),
		"symbol": "📜"
	},
	{
		"upgrade_key": "lexicon_engineering",
		"title": {"pt": "Mecanismos de Precisão", "en": "Precision Clockwork"},
		"category": {"pt": "Engenharia", "en": "Engineering"},
		"description": {"pt": "Desbloqueia termos mecânicos e engrenagens de alta precisão.", "en": "Unlocks mechanical precision and engineering terms."},
		"cover_color": Color(0.35, 0.42, 0.48, 1),
		"symbol": "⚙️"
	},
	{
		"upgrade_key": "lexicon_gastronomy",
		"title": {"pt": "Segredos do Barista", "en": "Barista Secrets"},
		"category": {"pt": "Gastronomia & Café", "en": "Gastronomy"},
		"description": {"pt": "Adiciona palavras de cafés artesanais e torras especiais.", "en": "Adds artisanal coffee roast and tasting vocabulary."},
		"cover_color": Color(0.62, 0.38, 0.22, 1),
		"symbol": "☕"
	},
	{
		"upgrade_key": "lexicon_philosophy",
		"title": {"pt": "Tratado da Existência", "en": "Treatise of Existence"},
		"category": {"pt": "Filosofia", "en": "Philosophy"},
		"description": {"pt": "Desbloqueia conceitos filosóficos profundos com pontuação épica.", "en": "Unlocks deep philosophical concepts with epic ink points."},
		"cover_color": Color(0.28, 0.25, 0.45, 1),
		"symbol": "✨"
	},
	{
		"upgrade_key": "thinking_time",
		"title": {"pt": "Reflexo da Meia-Noite", "en": "Midnight Reflex"},
		"category": {"pt": "Técnica Mental", "en": "Mind Technique"},
		"description": {"pt": "Aumenta a tolerância de pausa entre cada letra digitada (+0.15s).", "en": "Increases pause tolerance between keystrokes (+0.15s)."},
		"cover_color": Color(0.22, 0.35, 0.42, 1),
		"symbol": "⏳"
	},
	{
		"upgrade_key": "writing_time_base",
		"title": {"pt": "Foco Imperturbável", "en": "Unshakable Focus"},
		"category": {"pt": "Resistência", "en": "Stamina"},
		"description": {"pt": "Aumenta o tempo inicial total de escrita em cada nova folha (+2.0s).", "en": "Increases initial writing timer on every new sheet (+2.0s)."},
		"cover_color": Color(0.38, 0.50, 0.32, 1),
		"symbol": "🕯️"
	},
	{
		"upgrade_key": "writing_time_per_word",
		"title": {"pt": "Fôlego do Romancista", "en": "Novelist Stamina"},
		"category": {"pt": "Fluidez", "en": "Flow"},
		"description": {"pt": "Ganha tempo extra de escrita a cada palavra completada (+0.35s).", "en": "Adds bonus writing time upon completing any word (+0.35s)."},
		"cover_color": Color(0.58, 0.42, 0.25, 1),
		"symbol": "🪶"
	},
	{
		"upgrade_key": "letter_score_multiplier",
		"title": {"pt": "Tinta de Lótus Negra", "en": "Black Lotus Ink"},
		"category": {"pt": "Caligrafia", "en": "Calligraphy"},
		"description": {"pt": "Multiplica o rendimento de tinta de todas as palavras (+25%).", "en": "Multiplies ink yield of all words (+25%)."},
		"cover_color": Color(0.25, 0.20, 0.28, 1),
		"symbol": "✒️"
	},
	{
		"upgrade_key": "sheet_multiplier_bonus",
		"title": {"pt": "Inspiração em Cadeia", "en": "Chain Inspiration"},
		"category": {"pt": "Multiplicador", "en": "Multiplier"},
		"description": {"pt": "Aumenta o multiplicador ganho ao concluir folhas consecutivas.", "en": "Boosts consecutive sheet completion multiplier."},
		"cover_color": Color(0.72, 0.48, 0.20, 1),
		"symbol": "📄"
	},
	{
		"upgrade_key": "special_sheet_chance",
		"title": {"pt": "Pergaminho Imperial", "en": "Imperial Parchment"},
		"category": {"pt": "Papéis Especiais", "en": "Special Papers"},
		"description": {"pt": "Chance de surgirem Folhas Douradas (3x) e Manchadas de Café (2x).", "en": "Chance of rare Golden (3x) or Coffee-Stained sheets."},
		"cover_color": Color(0.75, 0.60, 0.25, 1),
		"symbol": "👑"
	},
	{
		"upgrade_key": "waitress_frequency",
		"title": {"pt": "Café dos Escritores", "en": "Writers Cafe Lounge"},
		"category": {"pt": "Hospitalidade", "en": "Hospitality"},
		"description": {"pt": "Aumenta a frequência com que a atendente aparece oferecendo café.", "en": "Increases spawn chance of the coffee waitress."},
		"cover_color": Color(0.68, 0.32, 0.25, 1),
		"symbol": "🔔"
	},
	{
		"upgrade_key": "coffee_power",
		"title": {"pt": "Torra Blend Supremo", "en": "Supreme Blend Roast"},
		"category": {"pt": "Potência do Café", "en": "Coffee Power"},
		"description": {"pt": "Aumenta o multiplicador do Coffee Rush quando ativo (até 5x).", "en": "Increases Coffee Rush multiplier when active (up to 5x)."},
		"cover_color": Color(0.48, 0.18, 0.15, 1),
		"symbol": "🔥"
	}
]

var current_draft_cards: Array = []

func _ready() -> void:
	load_game()
	roll_draft_upgrades()

func _process(delta: float) -> void:
	if is_coffee_active:
		coffee_time_remaining -= delta
		if coffee_time_remaining <= 0.0:
			is_coffee_active = false
			coffee_time_remaining = 0.0
			coffee_buff_ended.emit()

# --- Draft / Roleta System ---
func roll_draft_upgrades() -> Array:
	var available_candidates = []

	for card in book_cards_catalog:
		var key = card["upgrade_key"]
		var up = upgrades[key]
		if up["level"] < up["max_level"]:
			available_candidates.append(card)

	available_candidates.shuffle()

	current_draft_cards.clear()
	var pick_count = min(3, available_candidates.size())
	for i in range(pick_count):
		current_draft_cards.append(available_candidates[i])

	draft_upgrades_rolled.emit(current_draft_cards)
	return current_draft_cards

func reroll_draft_with_cost() -> bool:
	var reroll_cost = 2
	if points < reroll_cost:
		return false
	points -= reroll_cost
	points_updated.emit(points)
	roll_draft_upgrades()
	save_game()
	return true

# --- Upgrades Calculations ---
func get_long_word_multiplier(word_length: int) -> float:
	if word_length >= 7 and upgrades["long_word_bonus"]["level"] > 0:
		return 2.0
	return 1.0

func get_thinking_time_limit() -> float:
	var up = upgrades["thinking_time"]
	return up["base_val"] + (up["level"] * up["val_per_lvl"])

func get_writing_time_base() -> float:
	var up = upgrades["writing_time_base"]
	return up["base_val"] + (up["level"] * up["val_per_lvl"])

func get_writing_time_bonus() -> float:
	var up = upgrades["writing_time_per_word"]
	return up["base_val"] + (up["level"] * up["val_per_lvl"])

func get_letter_multiplier() -> float:
	var up = upgrades["letter_score_multiplier"]
	return up["base_val"] + (up["level"] * up["val_per_lvl"])

func get_sheet_multiplier() -> float:
	var base_mult = 1.0 + (sheets_completed_in_run * (0.2 + upgrades["sheet_multiplier_bonus"]["level"] * 0.1))
	if is_special_sheet:
		if special_sheet_type == "golden":
			base_mult *= 3.0
		elif special_sheet_type == "coffee_stained":
			base_mult *= 2.0
	return base_mult

func get_coffee_multiplier() -> float:
	if not is_coffee_active:
		return 1.0
	var up = upgrades["coffee_power"]
	return up["base_val"] + (up["level"] * up["val_per_lvl"])

func get_waitress_spawn_rate_multiplier() -> float:
	var up = upgrades["waitress_frequency"]
	return up["base_val"] + (up["level"] * up["val_per_lvl"])

func get_unlocked_categories() -> Array:
	var list = ["basic"]
	for key in ["lexicon_literature", "lexicon_engineering", "lexicon_poetry", "lexicon_gastronomy", "lexicon_philosophy"]:
		if upgrades[key]["level"] > 0:
			list.append(upgrades[key]["category_key"])
	return list

# --- Gameplay Flow Methods ---
func start_new_run() -> void:
	is_run_active = true
	sheets_completed_in_run = 0
	current_sheet_words_typed = 0
	current_sheet_score = 0
	start_new_sheet()

func start_new_sheet() -> void:
	current_sheet_words_typed = 0

	var special_chance = upgrades["special_sheet_chance"]["base_val"] + (upgrades["special_sheet_chance"]["level"] * upgrades["special_sheet_chance"]["val_per_lvl"])
	is_special_sheet = randf() < special_chance
	if is_special_sheet:
		var rolls = ["golden", "coffee_stained"]
		special_sheet_type = rolls[randi() % rolls.size()]
	else:
		special_sheet_type = ""

	sheet_started.emit(sheets_completed_in_run + 1, is_special_sheet, special_sheet_type)

func record_word_completed(word_data: Dictionary) -> int:
	var base = word_data.get("base_points", 1)
	var word_len = word_data.get("length", 4)

	var long_word_mult = get_long_word_multiplier(word_len)
	var letter_mult = get_letter_multiplier()
	var coffee_mult = get_coffee_multiplier()
	var sheet_mult = get_sheet_multiplier()

	var word_score = max(1, int(round(base * long_word_mult * letter_mult * coffee_mult * sheet_mult)))

	current_sheet_score += word_score
	current_sheet_words_typed += 1
	career_words_typed += 1

	return word_score

func complete_current_sheet() -> void:
	sheets_completed_in_run += 1
	career_sheets_completed += 1
	sheet_completed.emit(sheets_completed_in_run, current_sheet_score)

	roll_draft_upgrades()
	start_new_sheet()

func crumple_paper(reason: String) -> void:
	is_run_active = false
	career_crumpled_papers += 1

	# Bank points directly into ink wallet
	points += current_sheet_score

	if current_sheet_score > highest_run_score:
		highest_run_score = current_sheet_score

	points_updated.emit(points)

	roll_draft_upgrades()
	paper_crumpled.emit(reason)
	save_game()

func activate_coffee_buff() -> void:
	is_coffee_active = true
	coffee_time_remaining = coffee_duration_base
	var mult = get_coffee_multiplier()
	coffee_buff_started.emit(mult, coffee_duration_base)

# --- Upgrade Purchase ---
func get_upgrade_cost(key: String) -> int:
	var up = upgrades.get(key)
	if not up: return 0
	return int(up["base_cost"] * pow(up["cost_scale"], up["level"]))

func can_afford_upgrade(key: String) -> bool:
	var up = upgrades.get(key)
	if not up or up["level"] >= up["max_level"]:
		return false
	var cost = get_upgrade_cost(key)
	return points >= cost

func buy_upgrade(key: String) -> bool:
	if not can_afford_upgrade(key):
		return false

	var up = upgrades[key]
	var cost = get_upgrade_cost(key)

	points -= cost
	up["level"] += 1
	points_updated.emit(points)
	upgrade_purchased.emit(key, up["level"])

	roll_draft_upgrades()
	save_game()
	return true

# --- Save / Load ---
func save_game() -> void:
	var save_dict = {
		"points": points,
		"career_words_typed": career_words_typed,
		"career_sheets_completed": career_sheets_completed,
		"career_crumpled_papers": career_crumpled_papers,
		"highest_run_score": highest_run_score,
		"language": language,
		"upgrade_levels": {}
	}

	for id in upgrades:
		save_dict["upgrade_levels"][id] = upgrades[id]["level"]

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var json_str = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_str)
	if parsed is Dictionary:
		points = parsed.get("points", 0.0)
		career_words_typed = parsed.get("career_words_typed", 0)
		career_sheets_completed = parsed.get("career_sheets_completed", 0)
		career_crumpled_papers = parsed.get("career_crumpled_papers", 0)
		highest_run_score = parsed.get("highest_run_score", 0)
		language = parsed.get("language", "pt")

		var up_levels = parsed.get("upgrade_levels", {})
		for id in up_levels:
			if upgrades.has(id):
				upgrades[id]["level"] = up_levels[id]

		points_updated.emit(points)
