extends Node

# WordDatabase.gd - Manages categorized word banks for Portuguese and English

var words_pt = {
	"basic": [
		"sol", "lua", "mar", "rio", "luz", "som", "paz", "cafe", "casa", "arte",
		"doce", "gato", "noite", "vento", "mesa", "olhar", "tempo", "amor", "alma", "brisa",
		"nuvem", "tinta", "letra", "verso", "chuva", "tecla", "sonho", "farol", "campo", "verde",
		"ponto", "folha", "traco", "bule", "tarde", "plena", "canto", "livre", "frase", "texto"
	],
	"literature": [
		"manuscrito", "soliloquio", "antologia", "metafora", "pergaminho", "caligrafia",
		"cronica", "epilogo", "folhetim", "prologo", "poetica", "arquetipo", "alegoria",
		"narrativa", "romance", "retorica", "encadernacao", "erudicao", "memorias", "dialogo",
		"paragrafo", "verbetes", "antiquario", "datilografia", "prosopopeia", "solilóquio"
	],
	"engineering": [
		"engrenagem", "calibracao", "mecanismo", "carretel", "alavanca", "martelo",
		"parafuso", "cilindro", "precisao", "hidraulica", "dinamica", "rolamento",
		"articulacao", "cinematica", "resistencia", "compressao", "estrutura", "engrenar",
		"ferramenta", "manivela", "prototipo", "engenhoso", "maquinario", "friccao"
	],
	"poetry": [
		"crepusculo", "efemero", "sussurro", "melodia", "harmonia", "nostalgia",
		"saudade", "estonteante", "aurora", "inefavel", "ressoar", "alvorecer",
		"resplendor", "serenata", "encantamento", "inspiracao", "sublime", "soneto",
		"devaneio", "luminoso", "aconchego", "estelar", "lirismo", "placididade"
	],
	"gastronomy": [
		"espresso", "torrefacao", "aeropress", "caramelo", "aveludado", "capuccino",
		"infusao", "prensa", "barista", "aroma", "degustacao", "docura",
		"cremoso", "grao", "colheita", "acidez", "moagem", "extracao",
		"chaleira", "xicara", "fumegante", "chocolate", "canela", "especiaria"
	],
	"philosophy": [
		"existencia", "epifania", "consciencia", "dialetica", "racionalismo", "metafisica",
		"virtude", "solipsismo", "ontologia", "imanencia", "transcendencia", "episteme",
		"cognicao", "hermeneutica", "paradigma", "estoicismo", "iluminismo", "percepcao",
		"pensamento", "sabedoria", "aforismo", "contemplacao", "imperativo", "verdade"
	]
}

var words_en = {
	"basic": [
		"sun", "moon", "sea", "sky", "tea", "cup", "ink", "cat", "rain", "desk",
		"lamp", "wind", "warm", "book", "page", "word", "line", "calm", "hope", "type",
		"keys", "read", "poem", "tale", "song", "mind", "pure", "gold", "fire", "star",
		"leaf", "wood", "note", "time", "flow", "dawn", "dusk", "room", "love", "rose"
	],
	"literature": [
		"manuscript", "soliloquy", "anthology", "metaphor", "parchment", "calligraphy",
		"chronicle", "epilogue", "prologue", "poetics", "archetype", "allegory",
		"narrative", "romance", "rhetoric", "binding", "erudition", "memoirs", "dialogue",
		"paragraph", "antiquarian", "typewriter", "folklore", "protagonist"
	],
	"engineering": [
		"gearwheel", "calibration", "mechanism", "spool", "lever", "hammer",
		"screw", "cylinder", "precision", "hydraulics", "dynamics", "bearing",
		"articulation", "kinematics", "resistance", "compression", "structure", "mesh",
		"machine", "crankshaft", "prototype", "ingenious", "machinery", "friction"
	],
	"poetry": [
		"twilight", "ephemeral", "whisper", "melody", "harmony", "nostalgia",
		"longing", "breathtaking", "aurora", "ineffable", "resonate", "sunrise",
		"resplendent", "serenade", "enchantment", "inspiration", "sublime", "sonnet",
		"daydream", "luminous", "coziness", "starlight", "lyricism", "placidity"
	],
	"gastronomy": [
		"espresso", "roasting", "aeropress", "caramel", "velvety", "cappuccino",
		"infusion", "frenchpress", "barista", "aroma", "tasting", "sweetness",
		"creamy", "coffeebean", "harvest", "acidity", "grinding", "extraction",
		"kettle", "teacup", "steaming", "chocolate", "cinnamon", "spice"
	],
	"philosophy": [
		"existence", "epiphany", "consciousness", "dialectic", "rationalism", "metaphysics",
		"virtue", "solipsism", "ontology", "immanence", "transcendence", "episteme",
		"cognition", "hermeneutics", "paradigm", "stoicism", "enlightenment", "perception",
		"thinking", "wisdom", "aphorism", "contemplation", "imperative", "truth"
	]
}

# Returns category display data
var category_info = {
	"basic": {
		"name": {"pt": "Vocabulário Cotidiano", "en": "Everyday Words"},
		"culture_multiplier": 1,
		"bonus_points": 0
	},
	"literature": {
		"name": {"pt": "Literatura Antiga", "en": "Classic Literature"},
		"culture_multiplier": 2,
		"bonus_points": 15
	},
	"engineering": {
		"name": {"pt": "Engenharia & Mecânica", "en": "Engineering & Mechanics"},
		"culture_multiplier": 2,
		"bonus_points": 20
	},
	"poetry": {
		"name": {"pt": "Poesia Romântica", "en": "Romantic Poetry"},
		"culture_multiplier": 3,
		"bonus_points": 25
	},
	"gastronomy": {
		"name": {"pt": "Gastronomia & Café", "en": "Gastronomy & Coffee"},
		"culture_multiplier": 3,
		"bonus_points": 30
	},
	"philosophy": {
		"name": {"pt": "Filosofia & Existência", "en": "Philosophy & Existence"},
		"culture_multiplier": 4,
		"bonus_points": 45
	}
}

func get_paced_word(word_index_on_sheet: int, unlocked_categories: Array, language: String = "pt") -> Dictionary:
	var dict = words_pt if language == "pt" else words_en

	var target_category = "basic"
	var filter_length_min = 1
	var filter_length_max = 99
	var is_climax = (word_index_on_sheet >= 4)

	if word_index_on_sheet < 2:
		# 1 & 2: Warm-up short words (3-5 letters)
		target_category = "basic"
		filter_length_min = 3
		filter_length_max = 5
	elif word_index_on_sheet < 4:
		# 3 & 4: Thematic medium words (5-7 letters)
		var themed_candidates = []
		for cat in unlocked_categories:
			if cat != "basic" and dict.has(cat):
				themed_candidates.append(cat)
		if not themed_candidates.is_empty():
			target_category = themed_candidates[randi() % themed_candidates.size()]
		else:
			target_category = "basic"
		filter_length_min = 4
		filter_length_max = 8
	else:
		# 5: Climax grand word (8+ letters)
		var advanced_candidates = []
		for cat in unlocked_categories:
			if dict.has(cat):
				advanced_candidates.append(cat)
		target_category = advanced_candidates[randi() % advanced_candidates.size()]
		filter_length_min = 7
		filter_length_max = 20

	var pool: Array = dict.get(target_category, dict["basic"])
	var matching_words = []
	for w in pool:
		if w.length() >= filter_length_min and w.length() <= filter_length_max:
			matching_words.append(w)

	if matching_words.is_empty():
		matching_words = pool

	var text: String = matching_words[randi() % matching_words.size()]
	var info = category_info.get(target_category, category_info["basic"])

	# Base ink drop calculation: 1 base per word + small cultural prestige bonus for unlocked rich lexicons
	var cat_bonus = 0
	if target_category in ["literature", "engineering"]:
		cat_bonus = 1
	elif target_category in ["poetry", "gastronomy"]:
		cat_bonus = 1
	elif target_category == "philosophy":
		cat_bonus = 2

	if is_climax:
		cat_bonus += 1

	return {
		"text": text.to_lower(),
		"category": target_category,
		"category_name": info["name"][language] + (" [CLÍMAX]" if (is_climax and language == "pt") else (" [CLIMAX]" if is_climax else "")),
		"base_points": 1 + cat_bonus,
		"length": text.length(),
		"is_climax": is_climax
	}

func get_random_word(unlocked_categories: Array, language: String = "pt") -> Dictionary:
	return get_paced_word(0, unlocked_categories, language)
