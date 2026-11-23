extends SceneTree
## Simulateur d'équilibrage : enchaîne des parties de 8 bots sans interface, le plus vite possible,
## puis écrit des CSV et un résumé dans la console.
##
## Lancement (depuis le dossier du projet, après l'avoir ouvert une fois dans l'éditeur) :
##   godot --headless --path . --script res://tools/balance/balance_sim.gd -- --games 500
##
## Options (après le « -- ») :
##   --games N          parties par série (défaut 200)
##   --seed N           graine de départ : mêmes options + même graine = mêmes parties (défaut 1)
##   --bots smart|simple  style des bots (défaut smart)
##   --classes a,b,c    classes en jeu (défaut : les classes activées dans ClassCatalog)
##   --decks starter|random  decks de départ, ou decks aléatoires valides pour juger chaque carte (défaut starter)
##   --set NOM=VALEUR   change un réglage de CombatConfig pour toutes les séries (répétable)
##   --sweep NOM=v1,v2  une série par valeur, pour comparer des réglages (répétable : toutes les combinaisons)
##   --dt N             pas de simulation en secondes (défaut 0.05, comme en jeu)
##   --out DOSSIER      dossier des CSV (défaut res://balance_results)
## Listes : MONSTERS_BY_ROUND=3;3;5
## Stats d'un personnage : archer.attack_damage=6.5 (max_health, attack_damage, attack_interval, crit_chance)
##
## Exemple : comparer trois vitesses de mana avec 300 parties chacune :
##   godot --headless --path . --script res://tools/balance/balance_sim.gd -- --games 300 --sweep MANA_PER_SECOND=0.3,0.4,0.5

const DEFAULT_GAMES: int = 200
const DEFAULT_SEED: int = 1
const DEFAULT_DT: float = 0.05
const DEFAULT_OUT: String = "res://balance_results"
## Une partie plus longue que ça (en secondes simulées) est arrêtée : un réglage la bloque sans doute.
const MAX_GAME_SECONDS: float = 3600.0

var _games: int = DEFAULT_GAMES
var _seed: int = DEFAULT_SEED
var _dt: float = DEFAULT_DT
var _out: String = DEFAULT_OUT
var _bot_style: BotPlayer.Style = BotPlayer.Style.SMART
var _random_decks: bool = false
var _class_ids: Array[StringName] = []
var _fixed_settings: Array[String] = []
var _sweeps: Array[String] = []


func _initialize() -> void:
	var error: String = _parse_arguments(OS.get_cmdline_user_args())
	if not error.is_empty():
		printerr(error)
		quit(1)
		return
	BalanceOverrides.remember_defaults()
	var report := BalanceReport.new()
	var started: int = Time.get_ticks_msec()
	for combination: PackedStringArray in _sweep_combinations():
		error = _run_series(report, combination)
		if not error.is_empty():
			printerr(error)
			quit(1)
			return
	var directory: String = ProjectSettings.globalize_path(_out)
	report.write_csv_files(directory)
	report.print_summary()
	print("")
	print("Terminé en %.1f s. CSV écrits dans %s" % [(Time.get_ticks_msec() - started) / 1000.0, directory])
	quit()


# --- Séries -----------------------------------------------------------------

## Une série = des parties avec les mêmes réglages. Les graines sont les mêmes d'une série à l'autre,
## pour que les différences viennent des réglages et pas du hasard.
func _run_series(report: BalanceReport, sweep_values: PackedStringArray) -> String:
	BalanceOverrides.restore_defaults()
	var assignments: PackedStringArray = PackedStringArray(_fixed_settings)
	assignments.append_array(sweep_values)
	for assignment: String in assignments:
		var parts: PackedStringArray = assignment.split("=", true, 1)
		var error: String = BalanceOverrides.apply(parts[0], parts[1] if parts.size() > 1 else "")
		if not error.is_empty():
			return error
	var label: String = "base" if sweep_values.is_empty() else " ".join(sweep_values)
	print("Série « %s » : %d parties…" % [label, _games])
	var recorders: Array[MatchRecorder] = []
	var timeouts: int = 0
	for game_index: int in _games:
		var recorder: MatchRecorder = _simulate_game(_seed + game_index)
		if recorder == null:
			timeouts += 1
		else:
			recorders.append(recorder)
		_print_progress(game_index + 1)
	report.add_series(label, _describe_settings(), recorders, timeouts)
	return ""


## Simule une partie complète. Renvoie null si elle dépasse MAX_GAME_SECONDS.
## Même schéma que MatchService : le directeur décide, puis les commandes sont appliquées
## à la session, qui avance d'un pas.
func _simulate_game(game_seed: int) -> MatchRecorder:
	seed(game_seed)
	var session := MatchSession.new()
	var queue: Array[Dictionary] = []
	var director := HostDirector.new(session, func(command: Dictionary) -> void: queue.append(command))
	director.bot_style = _bot_style
	var recorder := MatchRecorder.new(session)
	director.start_match(_build_specs())
	var elapsed: float = 0.0
	while session.phase != MatchSession.Phase.FINISHED:
		if elapsed > MAX_GAME_SECONDS:
			return null
		director.tick(_dt)
		var commands: Array[Dictionary] = queue.duplicate()
		queue.clear()
		for command: Dictionary in commands:
			session.apply(command)
		session.step(_dt)
		recorder.step(_dt)
		elapsed += _dt
	return recorder


## 8 bots, classes réparties le plus également possible puis mélangées.
func _build_specs() -> Array[Dictionary]:
	var classes: Array[StringName] = []
	var offset: int = randi() % _class_ids.size()
	for index: int in GameConfig.MAX_PLAYERS:
		classes.append(_class_ids[(offset + index) % _class_ids.size()])
	classes.shuffle()
	var specs: Array[Dictionary] = []
	for index: int in GameConfig.MAX_PLAYERS:
		var spec: Dictionary = LocalMatchFactory.bot_spec(index + 1)
		spec["class"] = classes[index]
		if _random_decks:
			spec["deck"] = RandomDeckBuilder.build(ClassCatalog.find(classes[index]))
		specs.append(spec)
	return specs


## Toutes les combinaisons de --sweep (une seule série vide s'il n'y en a pas).
func _sweep_combinations() -> Array[PackedStringArray]:
	var combinations: Array[PackedStringArray] = [PackedStringArray()]
	for sweep: String in _sweeps:
		var parts: PackedStringArray = sweep.split("=", true, 1)
		var values: PackedStringArray = parts[1].split(",", false) if parts.size() > 1 else PackedStringArray()
		var next: Array[PackedStringArray] = []
		for combination: PackedStringArray in combinations:
			for value: String in values:
				var extended: PackedStringArray = combination.duplicate()
				extended.append("%s=%s" % [parts[0], value.strip_edges()])
				next.append(extended)
		combinations = next
	return combinations


func _describe_settings() -> String:
	var parts: PackedStringArray = [
		"bots=%s" % ("malins" if _bot_style == BotPlayer.Style.SMART else "simples"),
		"decks=%s" % ("aleatoires" if _random_decks else "depart"),
	]
	for setting: String in BalanceOverrides.NAMES:
		parts.append("%s=%s" % [setting, BalanceOverrides.describe(setting)])
	var characters: String = BalanceOverrides.describe_character_overrides()
	if not characters.is_empty():
		parts.append(characters)
	return " ".join(parts)


func _print_progress(done: int) -> void:
	var step: int = maxi(_games / 10, 1)
	if done % step == 0 or done == _games:
		print("  %d / %d" % [done, _games])


# --- Arguments --------------------------------------------------------------

func _parse_arguments(arguments: PackedStringArray) -> String:
	var index: int = 0
	while index < arguments.size():
		var name: String = arguments[index]
		var value: String = ""
		if name.contains("="):
			value = name.substr(name.find("=") + 1)
			name = name.left(name.find("="))
		elif index + 1 < arguments.size():
			index += 1
			value = arguments[index]
		var error: String = _apply_argument(name, value)
		if not error.is_empty():
			return error
		index += 1
	if _class_ids.is_empty():
		for class_data: ClassData in ClassCatalog.get_all():
			_class_ids.append(class_data.id)
	return ""


func _apply_argument(name: String, value: String) -> String:
	match name:
		"--games":
			_games = maxi(value.to_int(), 1)
		"--seed":
			_seed = value.to_int()
		"--dt":
			_dt = maxf(value.to_float(), 0.01)
		"--out":
			_out = value
		"--bots":
			_bot_style = BotPlayer.Style.SIMPLE if value == "simple" else BotPlayer.Style.SMART
		"--decks":
			_random_decks = value == "random"
		"--classes":
			return _parse_classes(value)
		"--set":
			_fixed_settings.append(value)
		"--sweep":
			_sweeps.append(value)
		_:
			return "Option inconnue : %s" % name
	return ""


func _parse_classes(value: String) -> String:
	for class_id: String in value.split(",", false):
		if ClassCatalog.find(StringName(class_id.strip_edges())) == null:
			return "Classe inconnue : %s" % class_id
		_class_ids.append(StringName(class_id.strip_edges()))
	return ""
