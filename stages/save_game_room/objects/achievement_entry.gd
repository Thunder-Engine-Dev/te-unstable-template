@tool
extends HBoxContainer

@export var entry_name: String:
	set(to):
		entry_name = to
		if !Engine.is_editor_hint() && hidden_on_init:
			return
		
		(func():
			$Label.text = to
		).call_deferred()
@export var secret_id: String
@export var progress_to: int = 0
@export var hidden_on_init: bool = false

@onready var label: Label = $Label

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if hidden_on_init:
		label.text = "<hidden achievement>"


func show_hidden() -> void:
	await get_tree().physics_frame
	label.text = entry_name
