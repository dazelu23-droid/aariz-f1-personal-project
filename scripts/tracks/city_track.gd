extends TrackBase

const RACING_KIT := "res://assets/racing-kit/Models/GLTF format/"
const ROADS := "res://assets/city-kit-roads/Models/OBJ format/"
const BUILDINGS := "res://assets/city-kit-commercial/Models/OBJ format/"
const _RoadBuilder := preload("res://scripts/road_builder.gd")
const _SceneryBuilder := preload("res://scripts/scenery_builder.gd")


func get_theme() -> String:
	return "city"


func get_track_name() -> String:
	return "City Streets"


func get_path_layout() -> Dictionary:
	return _RoadBuilder.get_city_layout()


func get_world_scale() -> float:
	return 5.0


func get_track_center_offset() -> Vector3:
	var layout: Dictionary = _RoadBuilder.get_city_layout()
	var bounds: Dictionary = layout.bounds
	return Vector3(-(bounds.min_x + bounds.max_x) * 0.5, 0.0, -(bounds.min_z + bounds.max_z) * 0.5)


func get_ground_color() -> Color:
	return Color(0.32, 0.35, 0.38)


func get_ground_size() -> float:
	var layout: Dictionary = _RoadBuilder.get_city_layout()
	var bounds: Dictionary = layout.bounds
	return maxf(bounds.max_x - bounds.min_x, bounds.max_z - bounds.min_z) + 240.0


func get_horizon_color() -> Color:
	return Color(0.24, 0.26, 0.3)


func _add_track_ground() -> void:
	var ground := MeshFactory.add_ground(self, get_ground_color(), get_ground_size())
	MeshFactory.add_horizon_skirt(self, get_horizon_color(), get_ground_size() * 1.35)
	MeshFactory.add_surface_slab(
		self,
		Vector3(0, -0.15, 0),
		Vector3(get_ground_size() * 0.92, 0.2, get_ground_size() * 0.92),
		0.0,
		Color(0.3, 0.33, 0.36),
		false
	)


func _build_track() -> void:
	_add_track_ground()
	var spawn_local: Vector3 = _RoadBuilder.build_city_circuit(
		track_root, border_root, fill_root, RACING_KIT
	)
	_SceneryBuilder.populate_city(scenery_root, ROADS, BUILDINGS)
	_set_spawn(Vector3(spawn_local.x, 0.42, spawn_local.z), true)
