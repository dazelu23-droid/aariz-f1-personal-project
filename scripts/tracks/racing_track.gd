extends TrackBase

const KIT := "res://assets/racing-kit/Models/GLTF format/"
const _RoadBuilder := preload("res://scripts/road_builder.gd")
const _SceneryBuilder := preload("res://scripts/scenery_builder.gd")


func get_theme() -> String:
	return "racing"


func get_track_name() -> String:
	return "Grand Prix Circuit"


func get_path_layout() -> Dictionary:
	return _RoadBuilder.get_racing_layout()


func get_world_scale() -> float:
	return 5.0


func get_track_center_offset() -> Vector3:
	var layout: Dictionary = _RoadBuilder.get_racing_layout()
	var bounds: Dictionary = layout.bounds
	return Vector3(-(bounds.min_x + bounds.max_x) * 0.5, 0.0, -(bounds.min_z + bounds.max_z) * 0.5)


func get_ground_color() -> Color:
	return Color(0.24, 0.5, 0.28)


func get_ground_size() -> float:
	var layout: Dictionary = _RoadBuilder.get_racing_layout()
	var bounds: Dictionary = layout.bounds
	return maxf(bounds.max_x - bounds.min_x, bounds.max_z - bounds.min_z) + 200.0


func get_horizon_color() -> Color:
	return Color(0.2, 0.46, 0.26)


func _add_track_ground() -> void:
	MeshFactory.add_ground(self, get_ground_color(), get_ground_size())
	MeshFactory.add_horizon_skirt(self, get_horizon_color(), get_ground_size() * 1.35)


func _build_track() -> void:
	_add_track_ground()
	var spawn_local: Vector3 = _RoadBuilder.build_racing_circuit(
		track_root, border_root, fill_root, KIT
	)
	_SceneryBuilder.populate_racing(scenery_root, KIT)
	_set_spawn(Vector3(spawn_local.x, 0.42, spawn_local.z), true)
