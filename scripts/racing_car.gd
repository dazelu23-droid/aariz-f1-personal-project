extends RigidBody3D

const MAX_SPEED := 40.0
const MAX_REVERSE_SPEED := 18.0
const ACCELERATION := 26.0
const REVERSE_ACCEL := 18.0
const BRAKE_FORCE := 58.0
const STEER_SPEED := 5.0
const GRIP := 0.96
const COAST_DRAG := 0.993

var is_ai := false
var car_visual_index := -1
var speed_mult := 1.0
var accel_mult := 1.0
var steer_mult := 1.0
var _ai_throttle := 0.0
var _ai_steer := 0.0


func _ready() -> void:
	gravity_scale = 1.0
	linear_damp = 0.04
	angular_damp = 1.1
	contact_monitor = true
	max_contacts_reported = 8
	sleeping = false
	can_sleep = false
	continuous_cd = true
	var road_grip := PhysicsMaterial.new()
	road_grip.friction = 1.05
	road_grip.bounce = 0.0
	road_grip.absorbent = true
	physics_material_override = road_grip


func apply_ai_profile(profile: Dictionary) -> void:
	speed_mult = profile.get("speed_mult", 1.0)
	accel_mult = profile.get("accel_mult", 1.0)
	steer_mult = profile.get("steer_mult", 1.0)


func set_ai_input(throttle: float, steer: float) -> void:
	_ai_throttle = throttle
	_ai_steer = steer


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var road_y := _get_road_surface_height()
	var origin := state.transform.origin
	origin.y = road_y
	state.transform.origin = origin

	var euler := state.transform.basis.get_euler(EULER_ORDER_YXZ)
	state.transform.basis = Basis.from_euler(Vector3(0.0, euler.y, 0.0))

	var linear := state.linear_velocity
	linear.y = 0.0
	state.linear_velocity = linear

	var angular := state.angular_velocity
	angular.x = 0.0
	angular.z = 0.0
	state.angular_velocity = angular


func _get_road_surface_height() -> float:
	var track := get_tree().current_scene
	if track and track.has_method("get_road_surface_height"):
		return track.get_road_surface_height(global_position)
	return global_position.y


func _physics_process(delta: float) -> void:
	var throttle := 0.0
	var steer := 0.0
	if is_ai:
		throttle = _ai_throttle
		steer = _ai_steer
	else:
		throttle = Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
		steer = Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right")
		if Input.is_action_just_pressed("reset_car"):
			_reset_car()

	var max_speed := MAX_SPEED * speed_mult
	var acceleration := ACCELERATION * accel_mult
	var steer_speed := STEER_SPEED * steer_mult

	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		return
	forward = forward.normalized()

	var horizontal_velocity := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var speed := horizontal_velocity.length()
	var forward_speed := horizontal_velocity.dot(forward)
	var is_reversing := forward_speed < -0.8

	if throttle > 0.0:
		if is_reversing:
			apply_central_force(forward * BRAKE_FORCE * throttle * mass)
		else:
			apply_central_force(forward * acceleration * throttle * mass)
	elif throttle < 0.0:
		if forward_speed > 1.2:
			apply_central_force(forward * BRAKE_FORCE * throttle * mass)
		else:
			apply_central_force(-forward * REVERSE_ACCEL * absf(throttle) * mass)

	if speed > 0.8 and absf(steer) > 0.01:
		var low_speed_boost := clampf(1.35 - speed / max_speed * 0.45, 0.72, 1.35)
		var reverse_steer := 1.15 if is_reversing else 1.0
		apply_torque(
			Vector3.UP * steer * steer_speed * low_speed_boost * reverse_steer * mass * delta * 60.0
		)

	if forward_speed > max_speed:
		var capped := forward * max_speed + horizontal_velocity - forward * forward_speed
		linear_velocity.x = capped.x
		linear_velocity.z = capped.z
	elif forward_speed < -MAX_REVERSE_SPEED:
		var capped := forward * -MAX_REVERSE_SPEED + horizontal_velocity - forward * forward_speed
		linear_velocity.x = capped.x
		linear_velocity.z = capped.z

	if speed > 1.0 and not is_reversing:
		var target_velocity := forward * forward_speed
		var blended := horizontal_velocity.lerp(target_velocity, GRIP * delta * 15.0)
		linear_velocity.x = blended.x
		linear_velocity.z = blended.z

	if absf(throttle) < 0.05:
		linear_velocity.x *= COAST_DRAG
		linear_velocity.z *= COAST_DRAG


func _reset_car() -> void:
	var scene_root := get_tree().current_scene
	if scene_root and scene_root.has_method("get_respawn_transform"):
		global_transform = scene_root.get_respawn_transform()
	elif scene_root:
		var spawn := scene_root.get_node_or_null("SpawnPoint")
		if spawn:
			global_transform = spawn.global_transform
		else:
			global_position = Vector3(0, 0.6, 0)
			rotation = Vector3.ZERO
	else:
		global_position = Vector3(0, 0.6, 0)
		rotation = Vector3.ZERO
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
