extends Area3D

@export var timer_path: NodePath

var _timer: RaceTimer
var _car_inside := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	if timer_path != NodePath():
		_timer = get_node(timer_path) as RaceTimer


func _physics_process(_delta: float) -> void:
	if _timer == null:
		return

	var inside := false
	for body in get_overlapping_bodies():
		if body is RigidBody3D and body.is_in_group("player_car"):
			inside = true
			break

	if inside and not _car_inside:
		_timer.on_finish_line_crossed()
	_car_inside = inside
