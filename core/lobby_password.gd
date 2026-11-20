class_name LobbyPassword
extends RefCounted
## Vérification du mot de passe d'un salon sans jamais l'écrire dans les données Steam.
## Le joueur publie une preuve (empreinte SHA-256 du salon, de son id Steam et du mot de passe).
## Seul l'hôte connaît le mot de passe et peut recalculer la preuve attendue.
## L'id du joueur est inclus pour qu'on ne puisse pas recopier la preuve d'un autre membre.

const SALT: String = "rise"


static func proof(lobby_id: int, steam_id: int, password: String) -> String:
	return ("%s:%d:%d:%s" % [SALT, lobby_id, steam_id, password]).sha256_text()


static func sanitize(password: String) -> String:
	return password.strip_edges().left(GameConfig.MAX_PASSWORD_LENGTH)
