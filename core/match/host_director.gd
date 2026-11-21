class_name HostDirector
extends RefCounted
## Décisions réservées à l'hôte (ou au joueur seul en entraînement) :
## choix de classe et chrono, bots, enchaînement résultats → récompenses → manche suivante.
## Il n'applique jamais rien lui-même : il soumet des commandes, que MatchService diffuse et applique.

const CLASS_SELECTION_DURATION: float = 30.0
const RESULTS_DURATION: float = 10.0
const NEXT_ROUND_DELAY: float = 1.5
const BOT_DRAFT_DELAY: float = 1.2

var _session: MatchSession
var _submit: Callable

var _selection_specs: Array[Dictionary] = []
var _class_choices: Dictionary[int, StringName] = {}
## Deck choisi par chaque joueur (ids) ; absent ou invalide = deck de base.
var _deck_choices: Dictionary[int, Array] = {}
var _selection_time_left: float = 0.0
var _match_requested: bool = false

var _bots: Array[BotPlayer] = []
var _bot_traders: Array[BotTrader] = []
var _phase_elapsed: float = 0.0
var _transition_requested: bool = false


func _init(session: MatchSession, submit: Callable) -> void:
	_session = session
	_submit = submit
	_session.round_started.connect(_on_round_started)
	_session.reward_phase_started.connect(_on_reward_phase_started)


# --- Démarrage --------------------------------------------------------------

## Entraînement : les classes sont déjà connues, on lance directement.
func start_match(specs: Array[Dictionary]) -> void:
	_match_requested = true
	_submit.call(MatchCommands.start_match(randi(), specs))


## En ligne : choix de classe secret avec chrono. Les bots choisissent tout de suite.
func begin_class_selection(specs: Array[Dictionary]) -> void:
	_selection_specs = specs
	_selection_time_left = CLASS_SELECTION_DURATION
	_submit.call(MatchCommands.begin_class_selection(specs, CLASS_SELECTION_DURATION))
	for spec: Dictionary in specs:
		if spec["bot"]:
			_lock_choice(spec["id"], ClassCatalog.pick_random().id)


## Choix reçu d'un joueur (le premier choix est définitif). Un deck invalide est remplacé par le deck de base.
func receive_class_choice(player_id: int, class_id: StringName, deck_ids: Array = []) -> void:
	if _session.phase != MatchSession.Phase.CLASS_SELECTION or _class_choices.has(player_id):
		return
	var class_data: ClassData = ClassCatalog.find(class_id)
	if not _is_selection_player(player_id) or class_data == null or not ClassCatalog.is_enabled(class_id):
		return
	if DeckRules.is_valid(class_data, deck_ids):
		_deck_choices[player_id] = deck_ids
	_lock_choice(player_id, class_id)


## Bouton « Continuer » de l'hôte sur l'écran de résultats.
func request_continue() -> void:
	if _session.phase == MatchSession.Phase.RESULTS:
		_advance_after_results()


# --- Avancement -------------------------------------------------------------

func tick(delta: float) -> void:
	match _session.phase:
		MatchSession.Phase.CLASS_SELECTION:
			_tick_class_selection(delta)
		MatchSession.Phase.ROUND:
			_tick_bots(delta)
		MatchSession.Phase.RESULTS:
			_tick_results(delta)
		MatchSession.Phase.REWARDS:
			_tick_rewards(delta)


func _tick_class_selection(delta: float) -> void:
	_selection_time_left -= delta
	if _selection_time_left <= 0.0:
		_request_match_start()


func _tick_bots(delta: float) -> void:
	for bot: BotPlayer in _bots:
		bot.tick(delta)
	for trader: BotTrader in _bot_traders:
		trader.tick(delta)


func _tick_results(delta: float) -> void:
	_phase_elapsed += delta
	if _phase_elapsed >= RESULTS_DURATION:
		_advance_after_results()


## _phase_elapsed sert d'abord de délai avant le choix d'un bot au draft,
## puis de délai avant la manche suivante une fois tout le monde servi.
func _tick_rewards(delta: float) -> void:
	var rewards: RewardPhase = _session.current_rewards
	if rewards.is_complete():
		_tick_next_round_delay(delta)
		return
	_phase_elapsed += delta
	if _is_bot(rewards.draft.current_picker_id()) and _phase_elapsed >= BOT_DRAFT_DELAY:
		_phase_elapsed = 0.0
		_submit_if_any(BotRewardPicker.draft_command(rewards, rewards.draft.current_picker_id()))


# --- Transitions ------------------------------------------------------------

func _lock_choice(player_id: int, class_id: StringName) -> void:
	_class_choices[player_id] = class_id
	_submit.call(MatchCommands.class_locked(player_id))
	if _class_choices.size() == _selection_specs.size():
		_request_match_start()


## Les joueurs sans choix reçoivent une classe au hasard.
func _request_match_start() -> void:
	if _match_requested:
		return
	_match_requested = true
	var specs: Array[Dictionary] = []
	for spec: Dictionary in _selection_specs:
		var final_spec: Dictionary = spec.duplicate()
		var class_id: StringName = _class_choices.get(spec["id"], ClassCatalog.pick_random().id)
		final_spec["class"] = class_id
		if _deck_choices.has(spec["id"]):
			final_spec["deck"] = _deck_choices[spec["id"]]
		if spec["bot"]:
			final_spec["name"] = "%s (%s)" % [spec["name"], ClassCatalog.find(class_id).display_name]
		specs.append(final_spec)
	_submit.call(MatchCommands.start_match(randi(), specs))


func _advance_after_results() -> void:
	if _transition_requested:
		return
	_transition_requested = true
	_submit.call(MatchCommands.end_match() if _session.is_last_round() else MatchCommands.start_rewards())


func _tick_next_round_delay(delta: float) -> void:
	if _transition_requested:
		return
	_phase_elapsed += delta
	if _phase_elapsed >= NEXT_ROUND_DELAY:
		_transition_requested = true
		_submit.call(MatchCommands.start_round(_session.round_index + 1))


# --- Réactions --------------------------------------------------------------

func _on_round_started(_round_index: int) -> void:
	_phase_elapsed = 0.0
	_transition_requested = false
	_bots.clear()
	_bot_traders.clear()
	for player: PlayerState in _session.players:
		if player.is_bot:
			_bots.append(BotPlayer.new(player, _session.current_round, _submit))
			_bot_traders.append(BotTrader.new(player, _session.current_round, _submit))


func _on_reward_phase_started() -> void:
	_phase_elapsed = 0.0
	_transition_requested = false
	_bots.clear()
	_bot_traders.clear()
	for player: PlayerState in _session.players:
		if player.is_bot:
			for command: Dictionary in BotRewardPicker.shop_commands(_session.current_rewards, player.id):
				_submit.call(command)


# --- Outils -----------------------------------------------------------------

func _is_bot(player_id: int) -> bool:
	var player: PlayerState = _session.get_player(player_id)
	return player != null and player.is_bot


func _is_selection_player(player_id: int) -> bool:
	for spec: Dictionary in _selection_specs:
		if spec["id"] == player_id:
			return true
	return false


func _submit_if_any(command: Dictionary) -> void:
	if not command.is_empty():
		_submit.call(command)
