class_name PasswordPrompt
extends Control
## Fenêtre modale qui demande le mot de passe d'un salon protégé.
## Elle masque l'écran derrière elle et ne parle à aucun service : l'écran qui l'utilise
## écoute submitted / cancelled et lui renvoie le verdict (show_error, close).

signal submitted(password: String)
signal cancelled

const ERROR_COLOR := Color(1.0, 0.5, 0.45)

@onready var _panel: PanelContainer = %Panel
@onready var _password_edit: LineEdit = %PasswordEdit
@onready var _status_label: Label = %StatusLabel
@onready var _cancel_button: Button = %CancelButton
@onready var _submit_button: Button = %SubmitButton


func _ready() -> void:
	_apply_styles()
	_password_edit.max_length = GameConfig.MAX_PASSWORD_LENGTH
	_password_edit.text_submitted.connect(_on_text_submitted)
	_submit_button.pressed.connect(_submit)
	_cancel_button.pressed.connect(cancelled.emit)
	hide()


func open() -> void:
	_password_edit.clear()
	_set_status("", UiStyle.TEXT_DIM)
	_set_waiting(false)
	show()
	_password_edit.grab_focus()


func close() -> void:
	hide()


## Mauvais mot de passe : on laisse réessayer.
func show_error(message: String) -> void:
	_set_waiting(false)
	_set_status(message, ERROR_COLOR)
	_password_edit.select_all()
	_password_edit.grab_focus()


func _apply_styles() -> void:
	_panel.add_theme_stylebox_override("panel", UiStyle.menu_panel())
	UiStyle.style_line_edit(_password_edit)
	UiStyle.style_button(_cancel_button, false)
	UiStyle.style_button(_submit_button, true)


func _submit() -> void:
	if _password_edit.text.strip_edges().is_empty():
		return
	_set_waiting(true)
	_set_status("Vérification par l'hôte…", UiStyle.TEXT_DIM)
	submitted.emit(_password_edit.text)


func _set_waiting(waiting: bool) -> void:
	_submit_button.disabled = waiting
	_password_edit.editable = not waiting


func _set_status(message: String, color: Color) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", color)


func _on_text_submitted(_text: String) -> void:
	if not _submit_button.disabled:
		_submit()
