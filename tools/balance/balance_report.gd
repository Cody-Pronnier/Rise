class_name BalanceReport
extends RefCounted
## Rassemble les parties simulées (une série par réglage testé), écrit les CSV et le résumé console.
## CSV au format Excel français : séparateur « ; » et virgule décimale.

const SEPARATOR: String = ";"

## Une entrée par série : { "label", "settings", "games", "timeouts", "recorders" }.
var _series: Array[Dictionary] = []


func add_series(label: String, settings: String, recorders: Array[MatchRecorder], timeouts: int) -> void:
	_series.append({ "label": label, "settings": settings, "recorders": recorders, "timeouts": timeouts })


# --- Résumés ------------------------------------------------------------------

## Par série et par classe : sièges, taux de victoire, place moyenne, points, temps, cartes, mana, morts.
func class_summary() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for series: Dictionary in _series:
		var by_class: Dictionary = {}
		for recorder: MatchRecorder in series["recorders"]:
			_add_final_rows(by_class, recorder.player_rows)
			_add_round_rows(by_class, recorder.round_player_rows)
		for class_id: StringName in by_class:
			rows.append(_class_row(series, class_id, by_class[class_id]))
	return rows


## Par série et par manche : durée moyenne, premier arrivé, écart premier/dernier, cartes, mana perdu.
func round_summary() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for series: Dictionary in _series:
		var by_round: Dictionary = {}
		for recorder: MatchRecorder in series["recorders"]:
			for row: Dictionary in recorder.round_rows:
				var bucket: Dictionary = by_round.get_or_add(row["round"], { "count": 0, "duration": 0.0, "first": 0.0, "gap": 0.0 })
				bucket["count"] += 1
				bucket["duration"] += row["duration"]
				bucket["first"] += row["first_finish"]
				bucket["gap"] += row["gap"]
			_add_round_player_totals(by_round, recorder.round_player_rows)
		for round_number: int in by_round:
			rows.append(_round_row(series, round_number, by_round[round_number]))
	return rows


## Par classe et par carte : ce que la carte apporte quand elle est dans le deck.
## « ecart » = taux de victoire avec la carte − taux sans, chez les joueurs de la même classe.
## Il n'a de sens qu'avec des decks qui varient (--decks random) : sinon toutes les cartes
## sont dans tous les decks et l'écart reste vide.
func card_summary() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for series: Dictionary in _series:
		var class_totals: Dictionary = {}
		var with_card: Dictionary = {}
		var plays: Dictionary = {}
		var targets: Dictionary = {}
		for recorder: MatchRecorder in series["recorders"]:
			_add_deck_presence(recorder, class_totals, with_card)
			for card_id: StringName in recorder.card_plays:
				plays[card_id] = plays.get(card_id, 0) + recorder.card_plays[card_id]
			_add_targets(recorder, targets)
		var games: float = maxf(series["recorders"].size(), 1.0)
		for key: String in with_card:
			var class_id: StringName = StringName(key.get_slice("|", 0))
			var card_id: StringName = StringName(key.get_slice("|", 1))
			var row: Dictionary = _card_row(series, class_id, card_id, with_card[key], class_totals[class_id], plays.get(card_id, 0) / games)
			_add_target_shares(row, targets.get(card_id, {}))
			rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _card_sort_key(a) > _card_sort_key(b))
	return rows


func _add_targets(recorder: MatchRecorder, targets: Dictionary) -> void:
	for card_id: StringName in recorder.card_targets:
		var totals: Dictionary = targets.get_or_add(card_id, {})
		for kind: String in recorder.card_targets[card_id]:
			totals[kind] = totals.get(kind, 0) + recorder.card_targets[card_id][kind]


## Part de chaque type de cible (0 à 1) : où la carte est jouée, toutes classes confondues.
func _add_target_shares(row: Dictionary, counts: Dictionary) -> void:
	var total: float = 0.0
	for kind: String in counts:
		total += counts[kind]
	for kind: String in MatchRecorder.TARGET_KINDS:
		row[kind] = counts.get(kind, 0) / maxf(total, 1.0)


## Compte, par classe, les joueurs (et leurs victoires) qui avaient chaque carte dans leur deck.
func _add_deck_presence(recorder: MatchRecorder, class_totals: Dictionary, with_card: Dictionary) -> void:
	for row: Dictionary in recorder.player_rows:
		var class_id: StringName = row["class"]
		var totals: Dictionary = class_totals.get_or_add(class_id, { "seats": 0, "wins": 0.0 })
		totals["seats"] += 1
		totals["wins"] += row["win_share"]
		var deck: Dictionary = recorder.player_decks.get(row["player"], {})
		for card_id: StringName in deck:
			var bucket: Dictionary = with_card.get_or_add("%s|%s" % [class_id, card_id], { "seats": 0, "wins": 0.0, "copies": 0 })
			bucket["seats"] += 1
			bucket["wins"] += row["win_share"]
			bucket["copies"] += deck[card_id]


func _card_row(series: Dictionary, class_id: StringName, card_id: StringName, with_bucket: Dictionary, totals: Dictionary, plays_per_game: float) -> Dictionary:
	var seats_with: int = with_bucket["seats"]
	var seats_without: int = totals["seats"] - seats_with
	var rate_with: float = with_bucket["wins"] / maxf(seats_with, 1.0)
	var row: Dictionary = {
		"serie": series["label"],
		"classe": String(class_id),
		"carte": String(card_id),
		"presence_decks": float(seats_with) / maxf(totals["seats"], 1.0),
		"copies_moyennes": float(with_bucket["copies"]) / maxf(seats_with, 1.0),
		"victoires_avec": rate_with,
		"victoires_sans": "",
		"ecart": "",
		"jouee_par_partie": plays_per_game,
	}
	if seats_without > 0:
		var rate_without: float = (totals["wins"] - with_bucket["wins"]) / seats_without
		row["victoires_sans"] = rate_without
		row["ecart"] = rate_with - rate_without
	return row


## Tri : par série, puis par classe, puis de la carte qui aide le plus à celle qui aide le moins.
func _card_sort_key(row: Dictionary) -> String:
	var gap: float = row["ecart"] if row["ecart"] is float else 0.0
	return "%s|%s|%07d" % [row["serie"], row["classe"], roundi((gap + 1.0) * 100000.0)]


# --- Sorties ----------------------------------------------------------------

func write_csv_files(directory: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	## Sans ce fichier, l'éditeur Godot essaierait d'importer les CSV comme des traductions.
	FileAccess.open(directory.path_join(".gdignore"), FileAccess.WRITE)
	_write_csv(directory.path_join("classes.csv"), class_summary())
	_write_csv(directory.path_join("manches.csv"), round_summary())
	_write_csv(directory.path_join("cartes.csv"), card_summary())
	_write_csv(directory.path_join("parties.csv"), _final_rows())
	_write_csv(directory.path_join("detail_manches.csv"), _detail_rows())


func print_summary() -> void:
	for series: Dictionary in _series:
		print("")
		print("=== Série « %s » — %d parties%s ===" % [series["label"], series["recorders"].size(), _timeout_note(series)])
		print("Réglages : %s" % series["settings"])
		print("%-12s %7s %10s %10s %8s %12s %10s %12s %7s" % ["Classe", "Sièges", "Victoires", "Place moy", "Points", "Temps fin", "Cartes/m", "Mana perdu", "Morts"])
		for row: Dictionary in class_summary():
			if row["serie"] != series["label"]:
				continue
			print("%-12s %7d %9.1f%% %10.2f %8.1f %11.1fs %10.1f %12.1f %7.2f" % [
				row["classe"], row["sieges"], row["taux_victoire"] * 100.0, row["place_moyenne"], row["points_moyens"],
				row["temps_fin_manche"], row["cartes_par_manche"], row["mana_perdu_par_manche"], row["morts_par_manche"],
			])
		print("Équilibre parfait : %.1f%% de victoires et %.2f de place moyenne par classe." % [100.0 / GameConfig.MAX_PLAYERS, (GameConfig.MAX_PLAYERS + 1) / 2.0])
		_print_card_extremes(series["label"])
		for row: Dictionary in round_summary():
			if row["serie"] == series["label"]:
				print("Manche %d : %.1fs en moyenne, premier arrivé à %.1fs, dernier %.1fs après lui, %.1f cartes par joueur, %.1f mana perdu par joueur" % [
					row["manche"], row["duree"], row["premier_arrive"], row["ecart_premier_dernier"], row["cartes_par_joueur"], row["mana_perdu_par_joueur"],
				])


## Avec des decks aléatoires : les 3 cartes qui aident le plus et le moins, par classe.
func _print_card_extremes(label: String) -> void:
	var by_class: Dictionary = {}
	for row: Dictionary in card_summary():
		if row["serie"] == label and row["ecart"] is float:
			by_class.get_or_add(row["classe"], []).append(row)
	for class_id: String in by_class:
		var rows: Array = by_class[class_id]
		print("%s — meilleures cartes : %s" % [class_id, _describe_cards(rows.slice(0, 3))])
		print("%s — moins bonnes : %s" % [class_id, _describe_cards(rows.slice(maxi(rows.size() - 3, 0)))])


func _describe_cards(rows: Array) -> String:
	return ", ".join(PackedStringArray(rows.map(func(row: Dictionary) -> String: return "%s (%+.1f pts)" % [row["carte"], row["ecart"] * 100.0])))


func _timeout_note(series: Dictionary) -> String:
	return " (%d interrompues : trop longues)" % series["timeouts"] if series["timeouts"] > 0 else ""


# --- Calculs ----------------------------------------------------------------

func _add_final_rows(by_class: Dictionary, rows: Array[Dictionary]) -> void:
	for row: Dictionary in rows:
		var bucket: Dictionary = _class_bucket(by_class, row["class"])
		bucket["seats"] += 1
		bucket["wins"] += row["win_share"]
		bucket["rank"] += row["rank"]
		bucket["points"] += row["points"]


func _add_round_rows(by_class: Dictionary, rows: Array[Dictionary]) -> void:
	for row: Dictionary in rows:
		var bucket: Dictionary = _class_bucket(by_class, row["class"])
		bucket["rounds"] += 1
		bucket["round_rank"] += row["rank"]
		bucket["finish_time"] += row["finish_time"]
		bucket["cards"] += row["cards"]
		bucket["mana_wasted"] += row["mana_wasted"]
		bucket["deaths"] += row["deaths"]


func _class_bucket(by_class: Dictionary, class_id: StringName) -> Dictionary:
	return by_class.get_or_add(class_id, {
		"seats": 0, "wins": 0.0, "rank": 0, "points": 0,
		"rounds": 0, "round_rank": 0, "finish_time": 0.0, "cards": 0, "mana_wasted": 0.0, "deaths": 0,
	})


func _class_row(series: Dictionary, class_id: StringName, bucket: Dictionary) -> Dictionary:
	var seats: float = maxf(bucket["seats"], 1.0)
	var rounds: float = maxf(bucket["rounds"], 1.0)
	return {
		"serie": series["label"],
		"reglages": series["settings"],
		"classe": String(class_id),
		"sieges": bucket["seats"],
		"taux_victoire": bucket["wins"] / seats,
		"place_moyenne": bucket["rank"] / seats,
		"points_moyens": bucket["points"] / seats,
		"place_moyenne_manche": bucket["round_rank"] / rounds,
		"temps_fin_manche": bucket["finish_time"] / rounds,
		"cartes_par_manche": bucket["cards"] / rounds,
		"mana_perdu_par_manche": bucket["mana_wasted"] / rounds,
		"morts_par_manche": bucket["deaths"] / rounds,
	}


func _add_round_player_totals(by_round: Dictionary, rows: Array[Dictionary]) -> void:
	for row: Dictionary in rows:
		var bucket: Dictionary = by_round.get_or_add(row["round"], { "count": 0, "duration": 0.0, "first": 0.0, "gap": 0.0 })
		bucket["player_rows"] = bucket.get("player_rows", 0) + 1
		bucket["cards"] = bucket.get("cards", 0) + row["cards"]
		bucket["mana_wasted"] = bucket.get("mana_wasted", 0.0) + row["mana_wasted"]


func _round_row(series: Dictionary, round_number: int, bucket: Dictionary) -> Dictionary:
	var count: float = maxf(bucket["count"], 1.0)
	var player_rows: float = maxf(bucket.get("player_rows", 0), 1.0)
	return {
		"serie": series["label"],
		"reglages": series["settings"],
		"manche": round_number,
		"duree": bucket["duration"] / count,
		"premier_arrive": bucket["first"] / count,
		"ecart_premier_dernier": bucket["gap"] / count,
		"cartes_par_joueur": bucket.get("cards", 0) / player_rows,
		"mana_perdu_par_joueur": bucket.get("mana_wasted", 0.0) / player_rows,
	}


## Résultat final de chaque joueur dans chaque partie.
func _final_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for series: Dictionary in _series:
		var game: int = 0
		for recorder: MatchRecorder in series["recorders"]:
			game += 1
			for row: Dictionary in recorder.player_rows:
				var detail: Dictionary = { "serie": series["label"], "partie": game }
				detail.merge(row)
				rows.append(detail)
	return rows


## Toutes les lignes joueur × manche, pour creuser dans Excel.
func _detail_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for series: Dictionary in _series:
		var game: int = 0
		for recorder: MatchRecorder in series["recorders"]:
			game += 1
			for row: Dictionary in recorder.round_player_rows:
				var detail: Dictionary = { "serie": series["label"], "partie": game }
				detail.merge(row)
				rows.append(detail)
	return rows


func _write_csv(path: String, rows: Array[Dictionary]) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Impossible d'écrire %s" % path)
		return
	if rows.is_empty():
		return
	var columns: Array = rows[0].keys()
	file.store_line(SEPARATOR.join(PackedStringArray(columns.map(func(column: Variant) -> String: return _quote(str(column))))))
	for row: Dictionary in rows:
		file.store_line(SEPARATOR.join(PackedStringArray(columns.map(func(column: Variant) -> String: return _format(row.get(column))))))


func _format(value: Variant) -> String:
	if value is float:
		return ("%.3f" % value).replace(".", ",")
	if value is bool:
		return "1" if value else "0"
	return _quote(str(value))


## Un texte qui contient le séparateur (ex : « MONSTERS_BY_ROUND=3;3;3 ») est mis entre guillemets,
## sinon Excel le couperait en plusieurs colonnes.
func _quote(text: String) -> String:
	if not text.contains(SEPARATOR) and not text.contains("\""):
		return text
	return "\"%s\"" % text.replace("\"", "\"\"")
