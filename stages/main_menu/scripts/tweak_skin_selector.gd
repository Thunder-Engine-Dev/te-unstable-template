extends "res://stages/main_menu/scripts/tweak_category_sel.gd"

const SKIN_PACK_SELECTION = preload("res://stages/main_menu/objects/character_editor/skin_pack_selection.tscn")
@export_color_no_alpha var COLOR_SELECTED_SKIN := Color(0.88, 0.749027, 0.4664, 1)

func _on_button_selection_entered() -> void:
	get_tree().call_group(&"_skin_selection", &"queue_free")

	set_skin_pack_none_color()

	var _arr := PackedStringArray(SkinsManager.custom_sprite_frames.keys())
	_arr.sort()
	for i in _arr.size():
		if _arr[i].is_empty():
			continue
		if _arr[i].begins_with("."):
			continue
		if _arr[i] == "none":
			continue
		var _skin_sel: Control = SKIN_PACK_SELECTION.instantiate()
		var label: Label = _skin_sel.get_node("Label")
		label.text = "%s" % [_arr[i].replacen("_", " ")]

		_skin_sel.skin_id = _arr[i]
		if _arr[i] == SkinsManager.current_skin:
			label.add_theme_color_override(&"font_color", COLOR_SELECTED_SKIN)
		_skin_sel.add_to_group(&"_skin_selection")
		move_to.add_child(_skin_sel)
		move_to.move_child(_skin_sel, move_to.get_child_count() - 2)

	move_to._update_selectors()

func set_skin_pack_none_color() -> void:
	var skin_none_sel: Label = move_to.get_node("SkinPackNone/Label")
	if SkinsManager.current_skin.is_empty():
		skin_none_sel.add_theme_color_override(&"font_color", COLOR_SELECTED_SKIN)
	else:
		skin_none_sel.remove_theme_color_override(&"font_color")

func _on_exit_selection_entered() -> void:
	SettingsManager._process_settings()
	SkinsManager.load_external_textures()

func _handle_select(mouse_input: bool = false) -> void:
	if !focused || !get_parent().focused:
		return
	_on_button_selection_entered()
	super(mouse_input)

func _physics_process(delta: float) -> void:
	var par_focused: bool = get_parent().focused
	if focused && par_focused && get_window().has_focus() && Input.is_action_just_pressed(trigger_action):
		_handle_select(false)

	if focused && Input.is_action_just_pressed(&"ui_select") && par_focused && tweak_description_text:
		$"../..".emit_signal(&"_show_desc", tweak_description_text, $Label.text)

	if !valu:
		return
	if focused && !is_blocked:
		_timer += delta * 10
		valu.modulate.a = min((cos(_timer) / 2.5) + 0.6, 1.0)
		valu.remove_theme_color_override(&"font_color")
		_update_text()
	elif par_focused:
		valu.modulate.a = 1.0
		valu.text = SettingsManager.settings.skin
		if valu.text && !valu.text in SkinsManager.custom_textures:
			valu.text = "<< missing >>"
		if valu.text.is_empty():
			valu.text = "none"
		valu.add_theme_color_override(&"font_color", Color(0.8, 1.0, 0.9))
