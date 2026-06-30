extends Node

var _car: RacingCar
var _samples: Array[Vector3] = []
var _target_index := 1
var _profile: Dictionary = {}
var _track_base: Node3D
var _rng := RandomNumberGenerator.new()


func setup(
	car: RacingCar,
	samples: Array,
	profile: Dictionary,
	track_base: Node3D,
	start_index: int = 1
) -> void:
	_car = car
	_profile = profile
	_track_base = track_base
	_samples.clear()
	for sample in samples:
		if sample is Vector3:
			_samples.append(sample)
	_rng.randomize()
	_target_index = clampi(start_index, 1, maxi(1, _samples.size() - 1))


func _physics_process(_delta: float) -> void:
	if _car == null or _samples.size() < 3 or _track_base == null:
		return
	if _track_base.has_method("is_race_started") and not _track_base.is_race_started():
		_car.set_ai_input(0.0, 0.0)
		return
	if _track_base.has_method("is_race_finished") and _track_base.is_race_finished():
		_car.set_ai_input(0.0, 0.0)
		return

	var local_pos: Vector3 = _track_base.global_to_track_local(_car.global_position)
	_advance_along_path(local_pos)

	var aim: Vector3 = _path_aim_point(local_pos)
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
	var steer_error: float = _profile.get("steer_error", 0.12) * 0.35
	var steer := clampf(
		steer_raw * _profile.get("steer_mult", 1.0) + _rng.randf_range(-steer_error, steer_error),
		-1.0,
		1.0
	)

	var throttle: float = 0.88 * _profile.get("accel_mult", 1.0)
	var corner_amount := 1.0 - clampf(absf(steer_raw) * 1.6, 0.0, 1.0)
	throttle *= lerpf(0.5, 1.0, corner_amount)
	if local_pos.distance_to(_samples[_target_index]) > 14.0:
		throttle = minf(throttle, 0.7)

	_car.set_ai_input(throttle, steer)


func _advance_along_path(local_pos: Vector3) -> void:
	var reach: float = 2.8 + _profile.get("steer_error", 0.12) * 2.0
	var guard := 0
	while local_pos.distance_to(_samples[_target_index]) < reach and guard < _samples.size():
		if _target_index >= _samples.size() - 1:
			_target_index = 1
		else:
			_target_index += 1
		guard += 1


func _path_aim_point(local_pos: Vector3) -> Vector3:
	var idx := _target_index
	var next_idx := mini(idx + 1, _samples.size() - 1)
	var seg_start: Vector3 = _samples[idx]
	var seg_end: Vector3 = _samples[next_idx]
	var seg := seg_end - seg_start
	seg.y = 0.0
	var seg_len := seg.length()
	if seg_len < 0.05:
		return seg_end

	var dir := seg / seg_len
	var rel := local_pos - seg_start
	rel.y = 0.0
	var along := clampf(rel.dot(dir), 0.0, seg_len)
	var lookahead: float = _profile.get("lookahead", 6.0)
	var aim_along := clampf(along + lookahead, 0.0, seg_len)
	return seg_start + dir * aim_along
