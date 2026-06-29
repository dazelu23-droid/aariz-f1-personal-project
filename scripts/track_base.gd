class_name TrackBase
extends Node3D

const CAR_SCENE := preload("res://scenes/racing_car.tscn")
const FINISH_LINE_SCENE := preload("res://scenes/finish_line.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/checkpoint.tscn")

@onready var track_root: Node3D = $TrackRoot
@onready var border_root: Node3D = $BorderRoot
@onready var fill_root: Node3D = $FillRoot
@onready var scenery_root: Node3D = $SceneryRoot
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var race_timer: Node = $RaceTimer

var _car: RigidBody3D
var _respawn_transform: Transform3D
var _has_respawn_checkpoint := false


func _ready() -> void:
	GraphicsSetup.apply(world_environment, get_theme())
	GraphicsSetup.setup_sun(sun, get_theme())
	_build_track()
	_apply_world_scale()
	_setup_checkpoints()
	_setup_finish_line()
	_spawn_car()
	_setup_hud()
	race_timer.arm()


func get_theme() -> String:
	return "racing"


func get_world_scale() -> float:
	return 8.0


func get_track_center_offset() -> Vector3:
	return Vector3.ZERO


func get_ground_color() -> Color:
	return Color(0.32, 0.55, 0.34)


func get_ground_size() -> float:
	return 320.0


func _build_track() -> void:
	pass


func _apply_world_scale() -> void:
	var s := get_world_scale()
	var scale_vec := Vector3(s, s, s)
	var origin := get_track_center_offset() * s
	for root in [track_root, border_root, fill_root, scenery_root]:
		root.scale = scale_vec
		root.position = origin


func _add_track_ground() -> void:
	var size := get_ground_size()
	MeshFactory.add_ground(self, get_ground_color(), size)
	MeshFactory.add_horizon_skirt(self, get_horizon_color(), size * 1.35)


func get_horizon_color() -> Color:
	return get_ground_color().lerp(Color(0.45, 0.5, 0.55), 0.25)


func _set_spawn(local_pos: Vector3, face_negative_z: bool = true) -> void:
	var s := get_world_scale()
	var centered := local_pos + get_track_center_offset()
	# Road slabs live on track_root (scaled); car sits on TrackBase in world space.
	const ROAD_TOP_LOCAL := 0.14
	const CAR_BOTTOM_OFFSET := 0.05
	var road_y := ROAD_TOP_LOCAL * s + CAR_BOTTOM_OFFSET
	spawn_point.position = Vector3(centered.x * s, road_y, centered.z * s)
	spawn_point.rotation_degrees.y = 0.0 if face_negative_z else 180.0


func _setup_finish_line() -> void:
	var finish := FINISH_LINE_SCENE.instantiate() as Area3D
	finish.timer_path = race_timer.get_path()
	var s := get_world_scale()
	finish.position = spawn_point.position
	finish.rotation = spawn_point.rotation
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.2 * s, 1.6, 1.2 * s)
	var col := CollisionShape3D.new()
	col.shape = shape
	finish.add_child(col)
	add_child(finish)


func _spawn_car() -> void:
	_car = CAR_SCENE.instantiate()
	_car.collision_layer = 2
	_car.collision_mask = 1
	add_child(_car)
	_car.global_transform = spawn_point.global_transform

	var camera := $FollowCamera as FollowCamera
	if camera:
		camera.set_target(_car)


func _setup_hud() -> void:
	var hud := $HUD
	if hud:
		hud.track_name = get_track_name()
		hud.timer_path = race_timer.get_path()


func get_track_name() -> String:
	return "Track"


func get_path_layout() -> Dictionary:
	return {}


func register_checkpoint(checkpoint_transform: Transform3D) -> void:
	_respawn_transform = checkpoint_transform
	_has_respawn_checkpoint = true


func get_respawn_transform() -> Transform3D:
	if _has_respawn_checkpoint:
		return _respawn_transform
	return spawn_point.global_transform


func _local_path_to_world_transform(local_pos: Vector3, travel_dir: Vector3) -> Transform3D:
	var s := get_world_scale()
	var centered := local_pos + get_track_center_offset()
	const ROAD_TOP_LOCAL := 0.14
	const CAR_BOTTOM_OFFSET := 0.05
	var road_y := ROAD_TOP_LOCAL * s + CAR_BOTTOM_OFFSET
	var world_pos := Vector3(centered.x * s, road_y, centered.z * s)
	var flat_dir := Vector3(travel_dir.x, 0.0, travel_dir.z)
	if flat_dir.length_squared() < 0.0001:
		flat_dir = Vector3(0.0, 0.0, -1.0)
	else:
		flat_dir = flat_dir.normalized()
	var basis := Basis.looking_at(flat_dir, Vector3.UP)
	return Transform3D(basis, world_pos)


func _setup_checkpoints() -> void:
	var layout := get_path_layout()
	var samples: Array = layout.get("samples", [])
	if samples.size() < 3:
		return

	var tile: float = layout.get("tile", 2.0)
	var spacing := maxi(3, int(round(5.0 / tile)))
	var start_skip := maxi(spacing * 2, int(round(8.0 / tile)))
	var s := get_world_scale()
	var start_local: Vector3 = samples[0] if samples[0] is Vector3 else Vector3.ZERO

	var container := Node3D.new()
	container.name = "Checkpoints"
	add_child(container)

	var index := 0
	var sample_idx := start_skip
	while sample_idx < samples.size() - 1:
		var local_pos: Vector3 = samples[sample_idx]
		if local_pos.distance_to(start_local) < 4.5:
			sample_idx += spacing
			continue
		var next_pos: Vector3 = samples[mini(sample_idx + 1, samples.size() - 1)]
		var travel_dir := next_pos - local_pos
		if travel_dir.length_squared() < 0.001 and sample_idx + 2 < samples.size():
			next_pos = samples[sample_idx + 2]
			travel_dir = next_pos - local_pos
		if travel_dir.length_squared() < 0.001:
			sample_idx += spacing
			continue

		var checkpoint := CHECKPOINT_SCENE.instantiate() as Area3D
		checkpoint.name = "Checkpoint_%d" % index
		checkpoint.track_base_path = get_path()
		checkpoint.transform = _local_path_to_world_transform(local_pos, travel_dir)

		var collision := checkpoint.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collision and collision.shape is BoxShape3D:
			var shape := collision.shape as BoxShape3D
			var road_width: float = layout.get("width", 3.0)
			shape.size = Vector3(road_width * s * 1.1, 2.0, road_width * s * 1.1)

		container.add_child(checkpoint)
		index += 1
		sample_idx += spacing


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/track_select.tscn")
