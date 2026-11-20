class_name StealCardEffect
extends CardEffect
## Vole une carte au hasard dans la main du joueur ciblé : le lanceur peut la jouer pendant cette manche.


func get_play_error(context: CardContext) -> String:
	if context.target_player == context.caster:
		return "Choisis un autre joueur."
	if context.target_player.hand.is_empty():
		return "Ce joueur n'a plus de cartes en main."
	return ""


func apply(context: CardContext) -> void:
	var card: CardData = GameRandom.pick(context.target_player.hand)
	context.target_player.consume_card(card)
	context.caster.receive_hand_card(card)
