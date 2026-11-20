class_name TradeInbox
extends VBoxContainer
## Colonne de tuiles sur le côté droit : une par offre reçue en attente (5 au maximum).

signal offer_selected(offer: TradeOffer)

var _chips: Dictionary[int, TradeNotificationChip] = {}


func add_offer(offer: TradeOffer, sender: PlayerState) -> void:
	var chip := TradeNotificationChip.new()
	add_child(chip)
	chip.setup(offer, sender)
	chip.pressed.connect(offer_selected.emit.bind(offer))
	_chips[offer.id] = chip


func remove_offer(offer_id: int) -> void:
	if not _chips.has(offer_id):
		return
	_chips[offer_id].queue_free()
	_chips.erase(offer_id)


func clear() -> void:
	for chip: TradeNotificationChip in _chips.values():
		chip.queue_free()
	_chips.clear()
