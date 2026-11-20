class_name GameConfig
extends RefCounted
## Constantes globales du jeu. Aucune logique ici, seulement des valeurs.

## 480 = Spacewar, l'App ID de test de Valve. À remplacer par ton App ID Steam.
const STEAM_APP_ID: int = 480

const MAX_PLAYERS: int = 8
const MIN_PLAYERS: int = 2
const MAX_LOBBY_RESULTS: int = 50
const MAX_LOBBY_NAME_LENGTH: int = 32

## Avec l'App ID 480, tous les jeux de test partagent les mêmes lobbies :
## ce tag permet de ne voir que les salons de NOTRE jeu.
const LOBBY_GAME_TAG_KEY: String = "game_tag"
const LOBBY_GAME_TAG_VALUE: String = "rise_dev"

## Clés des données de lobby (partagées par tout le salon).
const LOBBY_NAME_KEY: String = "name"
const LOBBY_STATE_KEY: String = "state"
const LOBBY_STATE_STARTING: String = "starting"
const LOBBY_MAX_PLAYERS_KEY: String = "max_players"
const LOBBY_BOTS_KEY: String = "bots"
const LOBBY_VISIBILITY_KEY: String = "visibility"
## "1" si un mot de passe est demandé. Le mot de passe lui-même n'est connu que de l'hôte.
const LOBBY_LOCKED_KEY: String = "locked"
## Amis invités par l'hôte depuis le jeu : ils entrent sans mot de passe (ids séparés par des virgules).
const LOBBY_INVITED_KEY: String = "invited"

## Clés des données de membre (propres à chaque joueur).
const MEMBER_READY_KEY: String = "ready"
## Preuve que le joueur connaît le mot de passe (voir LobbyPassword).
const MEMBER_PASSWORD_PROOF_KEY: String = "pw_proof"

## Mot de passe du salon.
const MAX_PASSWORD_LENGTH: int = 32
const MAX_PASSWORD_ATTEMPTS: int = 3
## Temps laissé à un joueur pour saisir le mot de passe avant d'être renvoyé.
const PASSWORD_GRACE_SECONDS: float = 60.0
