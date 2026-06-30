extends TrackBase

const NATURE := "res://assets/nature-kit/Models/FBX format/"
const _RoadBuilder := preload("res://scripts/road_builder.gd")
const _SceneryBuilder := preload("res://scripts/scenery_builder.gd")
const _AIDriver := preload("res://scripts/ai_driver.gd")

var _ai_cars: Array[RigidBody3D] = []


func get_theme() -> String:
	return "nature"


func get_track_name() -> String:
	return "Forest Trail"


func get_path_layout() -> Dictionary:
	return _RoadBuilder.get_nature_layout()


func get_finish_line_pose() -> Dictionary:
	return _RoadBuilder.get_nature_finish_pose()


func get_world_scale() -> float:
	return 5.0


func get_track_center_offset() -> Vector3:
	var layout: Dictionary = _RoadBuilder.get_nature_layout()
	var bounds: Dictionary = layout.bounds
	return Vector3(-(bounds.min_x + bounds.max_x) * 0.5, 0.0, -(bounds.min_z + bounds.max_z) * 0.5)


func get_ground_color() -> Color:
	return Color(0.16, 0.38, 0.2)


func get_ground_size() -> float:
	var layout: Dictionary = _RoadBuilder.get_nature_layout()
	var bounds: Dictionary = layout.bounds
	var span: float = maxf(bounds.max_x - bounds.min_x, bounds.max_z - bounds.min_z)
	return span * get_world_scale() + 320.0


func _add_track_ground() -> void:
	var size := get_ground_size()
	MeshFactory.add_ground(self, get_ground_color(), size)


func get_road_surface_height(at_global: Vector3 = Vector3.ZERO) -> float:
	const ROAD_TOP_LOCAL := 0.14
	const CAR_RIDE_HEIGHT := 0.05
	var s := get_world_scale()
	if at_global == Vector3.ZERO:
		return ROAD_TOP_LOCAL * s + CAR_RIDE_HEIGHT

	var local := global_to_track_local(at_global)
	var samples: Array = get_path_layout().get("samples", [])
	if samples.is_empty():
		return ROAD_TOP_LOCAL * s + CAR_RIDE_HEIGHT

	var best_dist := INF
	var best_y := 0.0
	for sample in samples:
		if sample is not Vector3:
			continue
		var point: Vector3 = sample
		var dist := Vector2(local.x - point.x, local.z - point.z).length_squared()
		if dist < best_dist:
			best_dist = dist
			best_y = point.y

	return (best_y + ROAD_TOP_LOCAL) * s + CAR_RIDE_HEIGHT


func _build_track() -> void:
	_add_track_ground()
	var spawn_local: Vector3 = _RoadBuilder.build_nature_circuit(
		track_root, border_root, fill_root, NATURE
	)
	_SceneryBuilder.populate_nature(scenery_root, NATURE)
	_set_spawn(Vector3(spawn_local.x, 0.38, spawn_local.z), true)


func _spawn_car() -> void:
	_car = CAR_SCENE.instantiate()
	_car.collision_layer = 2
	_car.collision_mask = 0
	_car.add_to_group("player_car")
	add_child(_car)
	_car.global_transform = spawn_point.global_transform

	var camera := $FollowCamera as FollowCamera
	if camera:
		camera.set_target(_car)

	_spawn_ai_opponents()


func _spawn_ai_opponents() -> void:
	var count := GameSettings.ai_opponent_count
	if count <= 0:
		return

	var layout := get_path_layout()
	var samples: Array = layout.get("samples", [])
	if samples.size() < 8:
		return

	var profile: Dictionary = GameSettings.get_ai_difficulty_profile()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var spacing := maxi(3, int(round(6.0 / layout.get("tile", 1.25))))

	for i in count:
		var car := CAR_SCENE.instantiate() as RigidBody3D
		car.is_ai = true
		car.car_visual_index = GameSettings.random_car_index(rng)
		car.apply_ai_profile(profile)
		car.collision_layer = 2
		car.collision_mask = 0
		car.add_to_group("ai_car")

		var sample_idx := (i + 1) * spacing
		if sample_idx >= samples.size() - 1:
			sample_idx = (i + 1) % (samples.size() - 1)
		var local_pos: Vector3 = samples[sample_idx]
		var next_pos: Vector3 = samples[mini(sample_idx + 1, samples.size() - 1)]
		var travel_dir := next_pos - local_pos
		car.global_transform = _local_path_to_world_transform(local_pos, travel_dir)

		var driver := _AIDriver.new()
		driver.setup(car, samples, profile, self)
		car.add_child(driver)
		add_child(car)
		_ai_cars.append(car)
