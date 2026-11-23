extends RefCounted
## Textes de l'écran « Comment jouer » : une page par sujet (titre + texte BBCode).
## Les chiffres viennent des réglages du jeu (CombatConfig, DeckRules…) : les pages restent
## justes quand on rééquilibre, sans retoucher les textes.

const HEADING_COLOR: String = "#ffc84d"
const KEY_COLOR: String = "#66e6ff"


class Page:
	var title: String
	var body: String

	func _init(p_title: String, p_body: String) -> void:
		title = p_title
		body = p_body


static func build_pages() -> Array[Page]:
	return [
		Page.new("But du jeu", _goal()),
		Page.new("Une manche", _round()),
		Page.new("Cartes et mana", _cards_and_mana()),
		Page.new("Jouer une carte", _playing_a_card()),
		Page.new("Alliances et échanges", _alliances_and_trades()),
		Page.new("Entre les manches", _between_rounds()),
		Page.new("Decks", _decks()),
		Page.new("Classes", _classes()),
		Page.new("Touches", _controls()),
		Page.new("Pour les testeurs", _testers()),
	]


# --- Pages ------------------------------------------------------------------

static func _goal() -> String:
	return "\n".join([
		"Rise est une [b]course à 8 joueurs[/b]. Chaque joueur a son propre terrain : son héros y combat [b]automatiquement[/b] une file de monstres.",
		"",
		"Tu ne contrôles pas les attaques de ton héros : tu joues des [b]cartes[/b] pour l'aider à aller plus vite, ou pour freiner les autres.",
		"",
		_heading("Gagner"),
		_bullet("La partie dure [b]%d manches[/b]." % CombatConfig.MAX_ROUNDS),
		_bullet("Monstres à vaincre par manche : [b]%s[/b]." % _join_ints(CombatConfig.MONSTERS_BY_ROUND, " puis ")),
		_bullet("Le premier joueur qui a vaincu tous ses monstres termine 1er, le suivant 2e, etc."),
		_bullet("Points selon la place : [b]%s[/b]." % _join_ints(CombatConfig.POINTS_BY_RANK, ", ")),
		_bullet("La manche s'arrête quand il ne reste qu'un joueur en course : il marque [b]0 point[/b]."),
		_bullet("Après la dernière manche, le joueur qui a le plus de points gagne la partie."),
		"",
		"Les monstres deviennent plus forts à chaque manche.",
	])


static func _round() -> String:
	return "\n".join([
		_heading("Préparation"),
		"Au début de la partie, tu as [b]%d s[/b] pour regarder tes cartes, proposer des alliances et des échanges. Les combats n'ont pas commencé : tu ne peux pas encore jouer de carte." % int(CombatConfig.PREPARATION_DURATION),
		"",
		_heading("Combat"),
		_bullet("Ton héros et le monstre s'attaquent tout seuls."),
		_bullet("Quand un monstre tombe, le suivant arrive après une courte pause (%s s)." % _number(CombatConfig.MONSTER_BREATHER_DURATION)),
		_bullet("Si ton héros meurt, il revient après [b]%s s[/b] : tu perds du temps, pas la manche." % _number(CombatConfig.RESPAWN_DELAY)),
		_bullet("Les coups critiques infligent ×%s dégâts." % _number(CombatConfig.CRITICAL_MULTIPLIER)),
		"",
		_heading("Suivre la course"),
		_bullet("Les onglets en haut montrent les terrains des 8 joueurs : clique sur un onglet pour regarder ce terrain."),
		_bullet("Le [b]classement en direct[/b] (%s) indique où en est chacun : monstre en cours et PV retirés." % _key("Tab")),
	])


static func _cards_and_mana() -> String:
	return "\n".join([
		_heading("Ta main"),
		_bullet("Ton deck de %d cartes est mélangé au début de la partie. Tu commences avec [b]%d cartes[/b] en main." % [DeckRules.DECK_SIZE, CombatConfig.STARTING_HAND_SIZE]),
		_bullet("Une carte jouée est [b]consommée[/b] : elle ne revient pas pendant la partie."),
		_bullet("Tu ne pioches pas pendant une manche : de nouvelles cartes arrivent entre les manches."),
		"",
		_heading("Mana"),
		_bullet("Chaque carte a un [b]coût en mana[/b], affiché sur la carte."),
		_bullet("Tu commences avec [b]%s mana[/b], maximum [b]%s[/b]." % [_number(CombatConfig.MANA_START), _number(CombatConfig.MANA_MAX)]),
		_bullet("Le mana remonte de [b]%s par seconde[/b] pendant les combats." % _number(CombatConfig.MANA_PER_SECOND)),
		_bullet("Une barre pleine ne se remplit plus : un mana qui déborde est perdu. Ne le garde pas trop longtemps."),
		_bullet("Les cartes trop chères pour ton mana actuel sont grisées."),
		"",
		_heading("Types de cartes"),
		_bullet("[b]Cartes de classe[/b] : propres à ta classe."),
		_bullet("[b]Ultime[/b] : une seule par deck, plus chère et plus puissante."),
		_bullet("[b]Cartes neutres[/b] : utilisables par toutes les classes."),
		_bullet("[b]Cartes de podium[/b] : uniques, gagnées par les 3 premiers d'une manche."),
		"",
		_heading("Bonus de rattrapage"),
		"Une carte offensive qui vise directement un joueur [b]mieux classé[/b] que toi est plus forte : +%d %% par place d'avance, jusqu'à +%d %%. Les valeurs affichées sur la carte en tiennent compte." % [roundi(CatchUpBoost.BONUS_PER_PLACE * 100.0), roundi(CatchUpBoost.MAX_BONUS * 100.0)],
	])


static func _playing_a_card() -> String:
	return "\n".join([
		_heading("Étapes"),
		_bullet("[b]Clique sur une carte[/b] de ta main."),
		_bullet("Si elle a besoin d'une cible, [b]clique sur la cible[/b] : une unité (héros, compagnon ou monstre) ou un terrain, selon la carte."),
		_bullet("Pour viser un adversaire, [b]change d'onglet[/b] avant de cliquer, ou utilise les touches %s." % _key("1 à 8")),
		_bullet("Certaines cartes s'appliquent tout de suite, sans cible."),
		_bullet("%s ou %s annule le choix de cible." % [_key("Clic droit"), _key("Échap")]),
		"",
		_heading("Où jouer ses cartes"),
		_bullet("Sur [b]ton monstre[/b] : dégâts, poisons, malus. Tu avances plus vite."),
		_bullet("Sur [b]ton héros[/b] : bonus de dégâts, soins, protections."),
		_bullet("Sur [b]un adversaire[/b] : ralentir son héros, voler son mana, bloquer ses cartes…"),
		"",
		_heading("Restrictions"),
		_bullet("Tu ne peux pas attaquer ton allié."),
		_bullet("Certaines cartes rendent un terrain impossible à cibler pendant quelques secondes (Invisibilité, Duel pour l'honneur)."),
		_bullet("Survole une carte pour lire son effet. Les statuts actifs apparaissent sous chaque unité."),
	])


static func _alliances_and_trades() -> String:
	return "\n".join([
		"[b]Clic droit sur l'onglet d'un joueur[/b] pour ouvrir son menu : voir son terrain, proposer un échange, proposer une alliance.",
		"",
		_heading("Échanges"),
		_bullet("Tu peux proposer des cartes de ta main et/ou des points, et demander des cartes ou des points en retour."),
		_bullet("Une offre expire au bout de [b]%d s[/b]. Clic droit sur l'onglet du joueur pour l'annuler." % int(CombatConfig.TRADE_OFFER_TIMEOUT)),
		_bullet("Si une carte de l'offre est jouée entre-temps, l'offre est annulée."),
		_bullet("Un joueur qui a fini sa manche ne peut plus recevoir d'offre."),
		"",
		_heading("Alliances"),
		_bullet("[b]Une seule alliance par manche[/b], même si tu l'as rompue."),
		_bullet("À la fin de la manche, deux alliés reçoivent chacun la [b]moyenne de leurs points[/b] (arrondie au-dessus)."),
		_bullet("Tu ne peux pas attaquer ton allié, et il ne peut pas t'attaquer."),
		_bullet("Rompre l'alliance te coûte [b]%d points[/b], donnés à ton ancien allié." % CombatConfig.ALLIANCE_BREAK_COST),
		"",
		"Une alliance avec un joueur moins bien placé te fait perdre des points, mais elle peut t'éviter d'être pris pour cible.",
	])


static func _between_rounds() -> String:
	return "\n".join([
		"Après chaque manche, avant la suivante :",
		"",
		_heading("Nouvelles cartes"),
		_bullet("Tu tires [b]%d cartes[/b] de ton deck et tu en gardes [b]%d[/b]. Les autres sont défaussées." % [CombatConfig.DECK_CARDS_OFFERED, CombatConfig.DECK_CARDS_KEPT]),
		"",
		_heading("Boutique"),
		_bullet("%d cartes te sont proposées, à [b]%d points[/b] chacune." % [CombatConfig.SHOP_OFFER_SIZE, CombatConfig.SHOP_CARD_COST]),
		_bullet("[b]%d achats au plus[/b] pendant toute la partie. Un achat coûte des points de classement : choisis bien." % CombatConfig.MAX_SHOP_PURCHASES),
		"",
		_heading("Podium"),
		_bullet("Les %d premiers de la manche choisissent chacun une carte de podium, le 1er en premier." % CombatConfig.PODIUM_SIZE),
		"",
		"Clique sur [b]Prêt[/b] quand tu as fini. La manche suivante commence quand tout le monde est prêt.",
	])


static func _decks() -> String:
	return "\n".join([
		"Dans [b]Mes decks[/b] (menu principal), tu peux construire tes propres decks.",
		"",
		_bullet("Exactement [b]%d cartes[/b]." % DeckRules.DECK_SIZE),
		_bullet("Cartes de ta classe et cartes neutres."),
		_bullet("[b]%d exemplaires[/b] au plus d'une même carte, [b]%d ultime[/b] au plus." % [DeckRules.MAX_COPIES, DeckRules.MAX_ULTIMATES]),
		"",
		"Sans deck personnalisé, chaque classe a un deck de départ prêt à jouer.",
		"",
		"Le [b]Codex[/b] montre toutes les cartes de chaque classe, les cartes neutres et les cartes de podium.",
	])


static func _classes() -> String:
	var lines: PackedStringArray = ["Classes jouables pour l'instant :", ""]
	for class_data: ClassData in ClassCatalog.get_all():
		lines.append(_heading(class_data.display_name))
		lines.append(class_data.description)
		if not class_data.passive_description.is_empty():
			lines.append("[i]Mécanique unique : %s[/i]" % class_data.passive_description)
		lines.append("")
	lines.append("Le détail des cartes de chaque classe est dans le [b]Codex[/b].")
	return "\n".join(lines)


static func _controls() -> String:
	return "\n".join([
		_heading("Souris"),
		_bullet("%s sur une carte : la sélectionner." % _key("Clic gauche")),
		_bullet("%s sur une unité ou un terrain : choisir la cible." % _key("Clic gauche")),
		_bullet("%s : annuler le choix de cible." % _key("Clic droit")),
		_bullet("%s sur l'onglet d'un joueur : échange, alliance, voir son terrain." % _key("Clic droit")),
		"",
		_heading("Clavier"),
		_bullet("%s (en AZERTY : %s) : afficher le terrain du 1er au 8e onglet." % [_key("1 à 8"), _key("& é \" ' ( - è _")]),
		_bullet("%s : afficher ou masquer le classement en direct." % _key("Tab")),
		_bullet("%s : annuler le choix de cible, sinon ouvrir le menu." % _key("Échap")),
		"",
		"Attention : la partie [b]continue[/b] pendant que le menu est ouvert.",
	])


static func _testers() -> String:
	return "\n".join([
		"Merci de tester Rise ! C'est un [b]prototype[/b] : les équilibrages changent souvent et il reste des bugs.",
		"",
		_heading("Ce qui m'aide le plus"),
		_bullet("[b]Bugs[/b] : ce que tu faisais, ce que tu attendais, ce qui s'est passé. Une capture d'écran aide beaucoup."),
		_bullet("[b]Cartes[/b] : celles qui te semblent trop fortes, inutiles ou pas claires à lire."),
		_bullet("[b]Rythme[/b] : as-tu le temps de réfléchir ? Les manches sont-elles trop longues ou trop courtes ?"),
		_bullet("[b]Interface[/b] : ce que tu n'as pas compris ou pas trouvé."),
		"",
		"Pour t'entraîner seul contre des bots, choisis [b]Entraînement[/b] dans le menu principal.",
	])


# --- Mise en forme ----------------------------------------------------------

static func _heading(text: String) -> String:
	return "[font_size=22][color=%s]%s[/color][/font_size]" % [HEADING_COLOR, text]


static func _bullet(text: String) -> String:
	return "  •  " + text


static func _key(text: String) -> String:
	return "[color=%s][b]%s[/b][/color]" % [KEY_COLOR, text]


## 0.3 → « 0,3 » ; 5.0 → « 5 ».
static func _number(value: float) -> String:
	return String.num(value, 2).replace(".", ",")


static func _join_ints(values: Array[int], separator: String) -> String:
	var parts: PackedStringArray = []
	for value: int in values:
		parts.append(str(value))
	return separator.join(parts)
