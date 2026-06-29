extends Node

## Press F3 while racing to toggle visible collision shapes (debug builds only).

var _shapes_visible := false


func _ready() -> void:
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			_toggle_collision_shapes()


func _toggle_collision_shapes() -> void:
	_shapes_visible = not _shapes_visible
	get_tree().debug_collisions_hint = _shapes_visible
	print("Collision shapes: ", "ON" if _shapes_visible else "OFF", " (F3)")
