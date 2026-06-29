extends TrackBase

const KIT := "res://assets/racing-kit/Models/GLTF format/"
const _RoadBuilder := preload("res://scripts/road_builder.gd")
const _SceneryBuilder := preload("res://scripts/scenery_builder.gd")


func get_theme() -> String:
	return "racing"


func get_track_name() -> String:
	return "Grand Prix Circuit"


func get_world_scale() -> float:
	return 4.0


func get_track_center_offset() -> Vector3:
	return Vector3(-5.5, 0.0, 5.0)


func get_ground_color() -> Color:
	return Color(0.2, 0.44, 0.22)


func get_ground_size() -> float:
	return 140.0


func _add_track_ground() -> void:
	MeshFactory.add_ground(self, get_ground_color(), get_ground_size())


func _build_track() -> void:
	_add_track_ground()
	var spawn_local: Vector3 = _RoadBuilder.build_racing_circuit(
		track_root, border_root, fill_root, KIT
	)
	_SceneryBuilder.populate_racing(scenery_root, KIT)
	_set_spawn(Vector3(spawn_local.x, 0.42, spawn_local.z), true)
