class_name Screen
extends Control
## Classe de base de tous les écrans.
## Un écran ne connaît pas les autres écrans : il demande seulement à naviguer vers un Id.

enum Id { MAIN_MENU, LOBBY_BROWSER, LOBBY, CLASS_SELECT, COMBAT, OPTIONS, REWARDS, CODEX, DECKS }

@warning_ignore("unused_signal")
signal navigation_requested(screen_id: Id)
