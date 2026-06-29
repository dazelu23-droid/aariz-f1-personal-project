extends Area3D

@export var track_base_path: NodePath


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is RigidBody3D:
		return
	var track: Node = get_node_or_null(track_base_path) if track_base_path != NodePath() else null
	if track == null:
		track = get_tree().current_scene
	if track and track.has_method("register_checkpoint"):
		track.register_checkpoint(global_transform)
