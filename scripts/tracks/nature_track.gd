extends TrackBase

const NATURE := "res://assets/nature-kit/Models/FBX format/"
const _RoadBuilder := preload("res://scripts/road_builder.gd")
const _SceneryBuilder := preload("res://scripts/scenery_builder.gd")


func get_theme() -> String:
	return "nature"


func get_track_name() -> String:
	return "Forest Trail"


func get_world_scale() -> float:
	return 5.0


func get_track_center_offset() -> Vector3:
	return Vector3(-7.0, 0.0, 6.0)


func get_ground_color() -> Color:
	return Color(0.2, 0.4, 0.22)


func get_ground_size() -> float:
	return 260.0


func _build_track() -> void:
	_add_track_ground()
	var spawn_local: Vector3 = _RoadBuilder.build_nature_circuit(
		track_root, border_root, fill_root, NATURE
	)
	_SceneryBuilder.populate_nature(scenery_root, NATURE)
	_set_spawn(Vector3(spawn_local.x, 0.38, spawn_local.z), true)
