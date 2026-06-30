extends Node

var _car: RigidBody3D
var _samples: Array[Vector3] = []
var _target_index := 1
var _profile: Dictionary = {}
var _track_base: Node3D
var _rng := RandomNumberGenerator.new()


func setup(car: RigidBody3D, samples: Array, profile: Dictionary, track_base: Node3D) -> void:
	_car = car
	_profile = profile
	_track_base = track_base
	_samples.clear()
	for sample in samples:
		if sample is Vector3:
			_samples.append(sample)
	_rng.randomize()
	if _samples.size() > 2:
		_target_index = 1


func _physics_process(_delta: float) -> void:
	if _car == null or _samples.size() < 2 or _track_base == null:
		return

	var local_pos: Vector3 = _track_base.global_to_track_local(_car.global_position)
	_advance_target(local_pos)

	var aim := _lookahead_point(local_pos)
	var to_target := aim - local_pos
	to_target.y = 0.0
	if to_target.length_squared() < 0.01:
		_car.set_ai_input(0.2, 0.0)
		return

	var forward := -_car.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		_car.set_ai_input(0.2, 0.0)
		return
	forward = forward.normalized()

	var desired := to_target.normalized()
	var steer_raw := forward.cross(desired).y
	var steer_error: float = _profile.get("steer_error", 0.12)
	var steer := clampf(
		steer_raw * _profile.get("steer_mult", 1.0) + _rng.randf_range(-steer_error, steer_error),
		-1.0,
		1.0
	)

	var throttle := 0.82 * _profile.get("accel_mult", 1.0)
	if absf(steer) > 0.45:
		throttle *= lerpf(1.0, 0.55, _profile.get("corner_caution", 0.5))
	if local_pos.distance_to(_samples[_target_index]) > 18.0:
		throttle = minf(throttle, 0.65)

	_car.set_ai_input(throttle, steer)


func _advance_target(local_pos: Vector3) -> void:
	var guard := 0
	while local_pos.distance_squared_to(_samples[_target_index]) < 5.5 and guard < _samples.size():
		_target_index = (_target_index + 1) % _samples.size()
		guard += 1


func _lookahead_point(local_pos: Vector3) -> Vector3:
	var lookahead: float = _profile.get("lookahead", 6.0)
	var idx := _target_index
	var traveled := local_pos.distance_to(_samples[idx])
	var guard := 0
	while traveled < lookahead and guard < _samples.size():
		var next_idx := (idx + 1) % _samples.size()
		var segment := _samples[idx].distance_to(_samples[next_idx])
		if segment < 0.01:
			break
		if traveled + segment >= lookahead:
			var t := (lookahead - traveled) / segment
			return _samples[idx].lerp(_samples[next_idx], t)
		traveled += segment
		idx = next_idx
		guard += 1
	return _samples[idx]
