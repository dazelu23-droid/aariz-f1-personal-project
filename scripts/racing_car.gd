extends RigidBody3D

const MAX_SPEED := 62.0
const ACCELERATION := 28.0
const BRAKE_FORCE := 65.0
const STEER_SPEED := 3.6
const GRIP := 0.94
const COAST_DRAG := 0.992

var _speed := 0.0


func _ready() -> void:
	gravity_scale = 1.0
	linear_damp = 0.05
	angular_damp = 1.4
	contact_monitor = true
	max_contacts_reported = 4
	sleeping = false


func _physics_process(delta: float) -> void:
	var throttle := Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
	var steer := Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right")

	if Input.is_action_just_pressed("reset_car"):
		_reset_car()

	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		return
	forward = forward.normalized()

	var horizontal_velocity := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	_speed = horizontal_velocity.length()

	if throttle > 0.0:
		apply_central_force(forward * ACCELERATION * throttle * mass)
	elif throttle < 0.0:
		apply_central_force(forward * BRAKE_FORCE * throttle * mass)

	if _speed > 1.5 and absf(steer) > 0.01:
		var steer_factor := clampf(_speed / MAX_SPEED, 0.4, 1.0)
		apply_torque(Vector3.UP * steer * STEER_SPEED * steer_factor * mass * delta * 60.0)

	if _speed > MAX_SPEED:
		var capped := horizontal_velocity.normalized() * MAX_SPEED
		linear_velocity.x = capped.x
		linear_velocity.z = capped.z

	if _speed > 1.0:
		var target_velocity := forward * _speed
		var blended := horizontal_velocity.lerp(target_velocity, GRIP * delta * 14.0)
		linear_velocity.x = blended.x
		linear_velocity.z = blended.z

	if absf(throttle) < 0.05:
		linear_velocity.x *= COAST_DRAG
		linear_velocity.z *= COAST_DRAG


func _reset_car() -> void:
	var scene_root := get_tree().current_scene
	var spawn := scene_root.get_node_or_null("SpawnPoint") if scene_root else null
	if spawn:
		global_transform = spawn.global_transform
	else:
		global_position = Vector3(0, 0.6, 0)
		rotation = Vector3.ZERO
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
