class_name ClassPassive
extends RefCounted
## Règle propre à une classe, branchée sur le terrain de son joueur pendant une manche.
## Le passif par défaut ne change rien. Les classes à mécanique unique le surchargent :
## - Nécromancien : ne frappe pas, relève un squelette quand il n'a plus d'invocation ;
## - Marchand : gagne de l'or et recrute un mercenaire qui le protège.
## Une nouvelle instance est créée pour chaque terrain (l'état, comme l'or, repart de zéro à chaque manche).
## Tout est déterministe : le passif n'avance que dans tick(), appelé par Field.

## L'état affiché a changé (or, délai d'invocation…).
signal changed

var field: Field


func attach(p_field: Field) -> void:
	field = p_field
	_on_attached()


func tick(_delta: float) -> void:
	pass


## Faux si le personnage ne frappe pas lui-même (il laisse ses invocations se battre).
func character_can_attack() -> bool:
	return true


## Vrai si les cartes des autres joueurs ne peuvent pas viser le personnage.
func shields_character() -> bool:
	return false


## Ligne d'état affichée en combat pour son propre terrain ("" = rien à afficher).
func status_text() -> String:
	return ""


# --- Capacité active (bouton en combat) ---------------------------------------

func has_ability() -> bool:
	return false


func ability_label() -> String:
	return ""


## "" si la capacité peut être utilisée maintenant, sinon la raison.
func get_ability_error() -> String:
	return "Ta classe n'a pas de capacité."


func use_ability() -> void:
	pass


## Phrase de l'historique après « <joueur> » (ex : « a recruté un mercenaire »).
func describe_ability_use() -> String:
	return "a utilisé sa capacité"


# --- Ressources ----------------------------------------------------------------

func uses_gold() -> bool:
	return false


func get_gold() -> int:
	return 0


## Sans effet pour les classes qui n'utilisent pas d'or.
func receive_gold(_amount: int) -> void:
	pass


func _on_attached() -> void:
	pass
