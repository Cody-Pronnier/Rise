class_name PlayerCountOptions
extends RefCounted
## Remplit et lit un OptionButton « 2 joueurs » … « 8 joueurs ».


static func fill(option: OptionButton, selected_count: int) -> void:
	option.clear()
	for count: int in range(GameConfig.MIN_PLAYERS, GameConfig.MAX_PLAYERS + 1):
		option.add_item("%d joueurs" % count, count)
	select(option, selected_count)


static func select(option: OptionButton, count: int) -> void:
	var index: int = option.get_item_index(count)
	if index != -1:
		option.select(index)


static func selected_count(option: OptionButton) -> int:
	return option.get_selected_id()
