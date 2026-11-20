class_name LobbyJoinErrors
extends RefCounted
## Traduit les codes EChatRoomEnterResponse de Steam en messages lisibles.

const SUCCESS: int = 1

const MESSAGES: Dictionary[int, String] = {
	2: "Ce salon n'existe plus.",
	3: "Tu n'as pas la permission de rejoindre ce salon.",
	4: "Ce salon est complet.",
	5: "Erreur inattendue de Steam.",
	6: "Tu es banni de ce salon.",
	7: "Ton compte Steam est limité et ne peut pas rejoindre de salon.",
	8: "Le salon de ce groupe est désactivé.",
	9: "Ton compte est sous restriction communautaire.",
	10: "Un membre du salon t'a bloqué.",
	11: "Tu as bloqué un membre de ce salon.",
}


static func describe(response_code: int) -> String:
	return MESSAGES.get(response_code, "Impossible de rejoindre le salon (code %d)." % response_code)
