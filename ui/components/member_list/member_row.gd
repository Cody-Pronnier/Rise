class_name MemberRow
extends PanelContainer
## Carte d'une place du salon, façon RTS :
## - un joueur : avatar, nom, badge d'hôte, état « prêt » ;
## - un bot : avatar bleu, badge BOT, bouton « Retirer » pour l'hôte ;
## - une place libre : bouton « + Ajouter un bot » pour l'hôte.

signal action_pressed

const RADIUS: int = 10
const AVATAR_RADIUS: int = 20
const AVATAR_SATURATION: float = 0.55
const AVATAR_VALUE: float = 0.75
const READY_COLOR := Color(0.25, 0.6, 0.32)
const WAITING_COLOR := Color(0.25, 0.24, 0.32)
const BOT_COLOR := Color(0.3, 0.45, 0.7)
const EMPTY_TEXT_COLOR := Color(0.45, 0.43, 0.55)

@onready var _avatar: Panel = %Avatar
@onready var _avatar_label: Label = %AvatarLabel
@onready var _avatar_image: TextureRect = %AvatarImage
@onready var _name_label: Label = %NameLabel
@onready var _host_badge: Label = %HostBadge
@onready var _ready_badge: Label = %ReadyBadge
@onready var _action_button: Button = %ActionButton

## Joueur dont on attend l'avatar Steam (0 pour un bot ou une place libre).
var _avatar_steam_id: int = 0


func _ready() -> void:
	SteamService.avatar_loaded.connect(_on_avatar_loaded)
	UiStyle.style_button(_action_button, false)
	_action_button.add_theme_font_size_override("font_size", 13)
	_action_button.pressed.connect(action_pressed.emit)


## À appeler après add_child() pour que les nœuds @onready soient prêts.
func display(member: LobbyMember) -> void:
	_set_name(member.display_name, Color.WHITE)
	_show_avatar(member.display_name.left(1).to_upper(), _avatar_color(member.steam_id))
	_show_steam_avatar(member.steam_id)
	_host_badge.visible = member.is_host
	_show_badge("PRÊT" if member.is_ready else "EN ATTENTE", READY_COLOR if member.is_ready else WAITING_COLOR)
	_action_button.hide()
	_apply_panel_style(Color(READY_COLOR, 0.8) if member.is_ready else Color(UiStyle.SECONDARY_BORDER, 0.5), UiStyle.PANEL_DARK)


func display_bot(bot_name: String, can_remove: bool) -> void:
	_set_name(bot_name, Color(0.75, 0.85, 1.0))
	_show_avatar("B", BOT_COLOR)
	_show_steam_avatar(0)
	_host_badge.hide()
	_show_badge("BOT", BOT_COLOR)
	_show_action("Retirer", can_remove)
	_apply_panel_style(Color(BOT_COLOR, 0.7), UiStyle.PANEL_DARK)


func display_open(can_add_bot: bool) -> void:
	_set_name("Place libre", EMPTY_TEXT_COLOR)
	_show_steam_avatar(0)
	_avatar.hide()
	_host_badge.hide()
	_ready_badge.hide()
	_show_action("+ Ajouter un bot", can_add_bot)
	_apply_panel_style(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0.2))


# --- Interne ----------------------------------------------------------------

func _set_name(text: String, color: Color) -> void:
	_name_label.text = text
	_name_label.add_theme_color_override("font_color", color)


func _show_avatar(initial: String, color: Color) -> void:
	_avatar_label.text = initial
	_avatar.add_theme_stylebox_override("panel", UiStyle.box(color, AVATAR_RADIUS, Color(0, 0, 0, 0.6), 2))
	_avatar.show()


## L'initiale colorée reste affichée tant que l'avatar Steam n'est pas arrivé.
func _show_steam_avatar(steam_id: int) -> void:
	_avatar_steam_id = steam_id
	var texture: Texture2D = SteamService.get_avatar(steam_id) if steam_id != 0 else null
	_set_avatar_texture(texture)
	if steam_id != 0 and texture == null:
		SteamService.request_avatar(steam_id)


func _set_avatar_texture(texture: Texture2D) -> void:
	_avatar_image.texture = texture
	_avatar_image.visible = texture != null
	_avatar_label.visible = texture == null


func _on_avatar_loaded(steam_id: int, texture: Texture2D) -> void:
	if steam_id == _avatar_steam_id and steam_id != 0:
		_set_avatar_texture(texture)


func _show_badge(text: String, color: Color) -> void:
	_ready_badge.show()
	_ready_badge.text = text
	_ready_badge.add_theme_stylebox_override("normal", UiStyle.with_margins(UiStyle.box(color, 6), 10.0, 3.0))


func _show_action(text: String, is_visible: bool) -> void:
	_action_button.text = text
	_action_button.visible = is_visible


func _apply_panel_style(border: Color, background: Color) -> void:
	add_theme_stylebox_override("panel", UiStyle.with_margins(UiStyle.box(background, RADIUS, border, 1), 14.0, 8.0))


## Couleur stable par joueur, tirée de son identifiant Steam.
func _avatar_color(steam_id: int) -> Color:
	var hue: float = float(posmod(hash(steam_id), 360)) / 360.0
	return Color.from_hsv(hue, AVATAR_SATURATION, AVATAR_VALUE)
