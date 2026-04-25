extends CanvasLayer

const secrets_path = "user://achievements.thss"

const SECRET_NOTIFICATION = preload("res://components/secrets_manager/achievement.wav")
const NOTIFICATION_ERROR = preload("res://components/secrets_manager/notification_error.wav")

var secrets: Dictionary = {}
var toast_queue: Array[Array] = []

var _save_queued: bool
var _is_free: bool = true
var _has_cheated: bool = false

@onready var label: Label = $Label
@onready var ninepatch: NinePatchRect = $Label/NinePatchRect
@onready var marker_2d: Marker2D = $Marker2D

var tween_disappear: Tween

signal secret_set(_name: String)

func _init() -> void:
	var new_save_path = OS.get_user_data_dir().path_join("saves")
	if DirAccess.dir_exists_absolute(new_save_path):
		return
	
	var _err = DirAccess.make_dir_recursive_absolute(new_save_path)
	if _err:
		printerr("Failed to create saves folder: " + error_string(_err))
		breakpoint
		return


func _ready() -> void:
	load_secrets()
	reparent.call_deferred(GlobalViewport.vp, false)
	
	# This is an example achievement ported from MFCE; uncomment for it to work!
	
	#Data.life_added.connect(func():
		#if Data.values.lives >= 99:
			#set_secret("got 100 extra lives at once", true)
	#)


func _physics_process(delta: float) -> void:
	# Save earned achievements to disk
	if _save_queued:
		_save_queued = false
		SettingsManager.save_data(secrets, secrets_path, "Achievements")
	# Achievement popup queue logic
	if _is_free && toast_queue.size() > 0:
		_is_free = false
		var _toast = toast_queue.pop_back()
		show_achievement(_toast.pop_front(), _toast.pop_front(), _toast.pop_front())

## Set the secret to a Variant (usually just True)
func set_secret(secret: String, value: Variant, save: bool = true, show_toast: bool = true, toast_text: String = "") -> void:
	if secret in secrets && (
		typeof(secrets[secret]) == TYPE_BOOL &&
		typeof(value) == TYPE_BOOL &&
		secrets[secret] == value
	):
		print("[Secrets Manager] Save cancelled, %s already exists!" % secret)
		return
	if is_console_enabled():
		print("[Secrets Manager] Console tweak is enabled! Didn't set %s to %s" % [str(value), secret])
		return
	if !secret in secrets && show_toast && SettingsManager.get_tweak("secrets_notification", true):
		queue_achievement(secret if !toast_text else toast_text)
	secrets[secret] = value
	secret_set.emit(secret)
	if save: save_secrets()

## Check if the secret exists and evaluates to True
func has_secret(secret: String) -> bool:
	return secret in secrets && secrets[secret]

## Get the secret Variant as it is stored, or null if it doesn't exist
func get_secret(secret: String) -> Variant:
	if secret in secrets:
		return secrets[secret]
	return null

## Check if it's post-endgame (usually bonus content is unlocked by checking this method)
func is_endgame() -> bool:
	return has_secret("story mode completed")

## Queue an Achievement Unlocked toast.
## Do not use directly unless you know what you are doing.
func queue_achievement(text: String, title: String = "achievement unlocked!", emit_sound: bool = true) -> void:
	var _toast := [text, title, emit_sound]
	toast_queue.append(_toast)

## Show an Achievement Unlocked toast immediately.
## Do not use directly unless you know what you are doing.
func show_achievement(text: String, title: String, emit_sound: bool) -> void:
	if emit_sound:
		Audio.play_1d_sound(SECRET_NOTIFICATION, true, { ignore_pause = true, bus = "1D Sound" })
	label.text = ""
	label.size.x = 192
	label.position.y = marker_2d.position.y + label.size.y + 8
	label.modulate.a = 1.0
	label.modulate.g = 1.0
	label.modulate.b = 1.0
	label.text = "%s
%s" % [title, text]
	
	if tween_disappear && tween_disappear.is_valid():
		tween_disappear.kill()
	var tw = create_tween().set_parallel()
	tw.tween_property(label, "position:y", marker_2d.position.y, 0.8)
	tw.tween_property(label, "modulate:a", marker_2d.modulate.a, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(5.0, true, false, true).timeout
	if len(toast_queue) == 0:
		tween_disappear = create_tween()
		tween_disappear.tween_property(label, "modulate:a", 0.0, 2.0)
	
	_is_free = true

## Show an Achievement Failed toast immediately. Does not support queues.
func show_failure(text: String, title: String = "achievement failed") -> void:
	if is_console_enabled() || !SettingsManager.get_tweak("secrets_notification", false):
		return
	Audio.play_1d_sound(NOTIFICATION_ERROR, true, {ignore_pause = true, volume = -4, bus = "1D Sound" })
	_is_free = false
	label.text = ""
	label.size.x = 192
	label.position.y = marker_2d.position.y + label.size.y + 8
	label.modulate.a = 1.0
	label.modulate.g = 0.4
	label.modulate.b = 0.333
	label.text = "%s
%s" % [title, text]
	
	if tween_disappear && tween_disappear.is_valid():
		tween_disappear.kill()
	var tw = create_tween().set_parallel()
	tw.tween_property(label, "position:y", marker_2d.position.y, 0.8)
	tw.tween_property(label, "modulate:a", marker_2d.modulate.a, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(5.0, true, false, true).timeout
	if len(toast_queue) == 0:
		tween_disappear = create_tween()
		tween_disappear.tween_property(label, "modulate:a", 0.0, 2.0)
	
	_is_free = true


## Load achievement data from disk.
func load_secrets() -> void:
	var data: Dictionary = SettingsManager.load_data(secrets_path, "Achievements")
	if data.is_empty():
		print("[Secrets Manager] No achievements found.")
		return
	
	secrets = data
	print("[Secrets Manager] Achievements loaded.")

## Used to queue a save of achievement data to disk.
func save_secrets() -> void:
	_save_queued = true

## Used to prevent achievements from working if the console is enabled.
## Only effective in exported builds.
func is_console_enabled() -> bool:
	return SettingsManager.get_tweak("console_enabled", false) || Console.command_executed || _has_cheated
