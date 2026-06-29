extends Area3D

@export var timer_path: NodePath

var _timer


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	if timer_path != NodePath():
		_timer = get_node(timer_path)


func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and _timer:
		_timer.on_finish_line_crossed()
