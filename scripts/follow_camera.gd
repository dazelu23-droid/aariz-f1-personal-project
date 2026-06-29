class_name FollowCamera
extends Camera3D

@export var target_path: NodePath
@export var follow_distance := 16.0
@export var follow_height := 6.0
@export var look_ahead := 10.0
@export var smooth_speed := 8.0

var _target: Node3D


func _ready() -> void:
	if target_path != NodePath():
		_target = get_node_or_null(target_path)


func set_target(target: Node3D) -> void:
	_target = target


func _physics_process(delta: float) -> void:
	if _target == null:
		return

	var forward := -_target.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var desired := _target.global_position - forward * follow_distance
	desired.y = _target.global_position.y + follow_height
	global_position = global_position.lerp(desired, smooth_speed * delta)

	var look_at_pos := _target.global_position + forward * look_ahead
	look_at(look_at_pos, Vector3.UP)
