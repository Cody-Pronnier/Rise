class_name MerchantClass
extends RefCounted
## Marchand : gagne de l'or avec le temps et recrute un mercenaire qui se bat à sa place.
## Ses cartes « équipement » renforcent le mercenaire ; son ultime recrute un champion légendaire.

const PORTRAIT: Texture2D = preload("res://assets/characters/merchant.svg")
const MERCENARY_PORTRAIT: Texture2D = preload("res://assets/characters/mercenary.svg")
const CHAMPION_PORTRAIT: Texture2D = preload("res://assets/characters/champion.svg")
const ID: StringName = &"merchant"
const UNIT := CardData.TargetMode.UNIT
const SELF := CardData.TargetMode.SELF
const MERCENARY: StringName = &"mercenary"
const COLOR := Color(0.95, 0.62, 0.2)
const PASSIVE_TEXT: String = "Gagne 1,5 or par seconde (25 au départ). Bouton « Recruter » : un mercenaire pour 25 or, un seul à la fois. Tant qu'il est debout, le Marchand ne frappe plus et les cartes adverses ne peuvent pas le viser."


static func build() -> ClassData:
	var character: UnitData = UnitData.create("Marchand", 100.0, 5.0, 1.0, 0.05, COLOR, PORTRAIT)
	var mercenary: UnitData = UnitData.create("Mercenaire", 100.0, 8.0, 1.0, 0.1, Color(0.6, 0.55, 0.5), MERCENARY_PORTRAIT).with_tag(MERCENARY)
	var data: ClassData = ClassData.create(ID, "Marchand", "Accumule de l'or et paie des mercenaires pour se battre à sa place.", character, _build_cards())
	return data.with_passive(func() -> ClassPassive: return MerchantPassive.new(mercenary), PASSIVE_TEXT)


static func _build_cards() -> Array[CardData]:
	var champion: UnitData = UnitData.create("Champion légendaire", 240.0, 15.0, 0.9, 0.15, Color(1.0, 0.8, 0.35), CHAMPION_PORTRAIT).with_tag(MERCENARY)
	var cards: Array[CardData] = [
		CardFactory.card(&"merchant_sharpened_blade", "Lame affûtée",
			"Équipement : +50 % de dégâts pendant 15 s.",
			UNIT, [EffectFactory.status(StatusLibrary.sharpened_blade())], true),
		CardFactory.card(&"merchant_plate_armor", "Armure de plates",
			"Équipement : 40 % de dégâts reçus en moins pendant 15 s.",
			UNIT, [EffectFactory.status(StatusLibrary.plate_armor())], true),
		CardFactory.card(&"merchant_swift_boots", "Bottes de célérité",
			"Équipement : +50 % de vitesse d'attaque pendant 15 s.",
			UNIT, [EffectFactory.status(StatusLibrary.swift_boots())], true),
		CardFactory.card(&"merchant_fat_contract", "Contrat juteux",
			"Gagne 20 or tout de suite (Marchand uniquement).",
			SELF, [EffectFactory.gain_gold(20)], true),
		CardFactory.card(&"merchant_bribe", "Pot-de-vin",
			"La cible inflige 30 % de dégâts en moins et attaque 40 % moins vite pendant 6 s.",
			UNIT, [EffectFactory.status(StatusLibrary.bribed())], false),
		CardFactory.ultimate(&"merchant_legendary_champion", "Champion légendaire",
			"Congédie ton mercenaire et recrute un champion légendaire (240 PV, 15 dégâts).",
			SELF, [EffectFactory.recruit(champion)], true),
	]
	return cards
