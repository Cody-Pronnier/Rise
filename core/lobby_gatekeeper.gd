class_name LobbyGatekeeper
extends RefCounted
## Contrôle d'entrée d'un salon protégé, tenu par l'hôte. Ne parle pas à Steam :
## LobbyService lui transmet les arrivées, départs et preuves, et applique ses décisions (signaux).
## Sont admis d'office : l'hôte, les joueurs déjà présents quand le mot de passe est posé,
## et les amis invités par l'hôte depuis le jeu.

signal accepted(steam_id: int)
signal rejected(steam_id: int, attempts_left: int)
signal kick_requested(steam_id: int, reason: String)

const REASON_TOO_MANY_ATTEMPTS: String = "Mot de passe incorrect : trop d'essais."
const REASON_TIMEOUT: String = "Mot de passe non saisi à temps."

var _password: String = ""
var _trusted: Dictionary[int, bool] = {}
var _arrival_times: Dictionary[int, float] = {}
var _attempts: Dictionary[int, int] = {}
## Dernière preuve examinée par joueur, pour ne pas recompter le même essai.
var _last_proofs: Dictionary[int, String] = {}


func has_password() -> bool:
	return not _password.is_empty()


func get_password() -> String:
	return _password


## Les joueurs présents au moment du changement sont admis.
func set_password(password: String, present_members: Array[int]) -> void:
	_password = password
	for steam_id: int in present_members:
		trust(steam_id)


func trust(steam_id: int) -> void:
	_trusted[steam_id] = true
	_arrival_times.erase(steam_id)


func is_trusted(steam_id: int) -> bool:
	return not has_password() or _trusted.has(steam_id)


func on_member_entered(steam_id: int, now: float) -> void:
	if not _trusted.has(steam_id):
		_arrival_times[steam_id] = now


func forget(steam_id: int) -> void:
	_trusted.erase(steam_id)
	_arrival_times.erase(steam_id)
	_attempts.erase(steam_id)
	_last_proofs.erase(steam_id)


func reset() -> void:
	_password = ""
	_trusted.clear()
	_arrival_times.clear()
	_attempts.clear()
	_last_proofs.clear()


## proofs : valeur publiée par chaque membre ("<numéro d'essai>:<empreinte>", vide si rien).
func evaluate(lobby_id: int, proofs: Dictionary[int, String], now: float) -> void:
	if not has_password():
		return
	for steam_id: int in proofs:
		if not _trusted.has(steam_id):
			_evaluate_member(lobby_id, steam_id, proofs[steam_id], now)


func _evaluate_member(lobby_id: int, steam_id: int, proof: String, now: float) -> void:
	if not proof.is_empty() and proof != _last_proofs.get(steam_id, ""):
		_last_proofs[steam_id] = proof
		_judge_proof(lobby_id, steam_id, proof.get_slice(":", 1))
	elif now - _arrival_times.get(steam_id, now) > GameConfig.PASSWORD_GRACE_SECONDS:
		_kick(steam_id, REASON_TIMEOUT)


func _judge_proof(lobby_id: int, steam_id: int, hash: String) -> void:
	if hash == LobbyPassword.proof(lobby_id, steam_id, _password):
		trust(steam_id)
		accepted.emit(steam_id)
		return
	_attempts[steam_id] = _attempts.get(steam_id, 0) + 1
	var attempts_left: int = GameConfig.MAX_PASSWORD_ATTEMPTS - _attempts[steam_id]
	if attempts_left <= 0:
		_kick(steam_id, REASON_TOO_MANY_ATTEMPTS)
	else:
		rejected.emit(steam_id, attempts_left)


func _kick(steam_id: int, reason: String) -> void:
	_arrival_times.erase(steam_id)
	kick_requested.emit(steam_id, reason)
