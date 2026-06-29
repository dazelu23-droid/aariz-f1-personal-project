class_name SceneryBuilder
extends RefCounted


static func populate_racing(props: Node3D, kit: String) -> void:
	var road := {"min_x": -1.0, "max_x": 12.0, "min_z": -13.0, "max_z": 3.0}
	_fill_grid(props, kit + "grass.glb", -4, 15, -15, 5, 1.2, road)
	_place_start_line(props, kit, road)
	_place_pit_complex(props, kit, road)
	_place_grandstands(props, kit, road)
	_place_corners(props, kit, road)
	_place_back_straight(props, kit, road)


static func populate_city(props: Node3D, roads: String, buildings: String, racing_kit: String = "") -> void:
	var road := {"min_x": -1.0, "max_x": 24.0, "min_z": -19.0, "max_z": 11.0}

	_place_city_blocks(props, buildings, road)
	_place_city_skyline(props, buildings, road)
	_place_city_streets(props, roads, road)
	if racing_kit != "":
		_place_city_racing_props(props, racing_kit, road)


static func _place_city_blocks(props: Node3D, buildings: String, road: Dictionary) -> void:
	var blocks := [
		"building-a.obj", "building-b.obj", "building-c.obj", "building-d.obj",
		"building-e.obj", "building-f.obj", "building-g.obj", "building-h.obj",
		"building-i.obj", "building-j.obj", "building-k.obj", "building-l.obj",
		"building-m.obj", "building-n.obj",
	]
	var x := -16
	while x <= 27:
		var z := -20
		while z <= 12:
			var pos := Vector3(x, 0, z)
			if not _on_road_expanded(pos, road, 1.5) and (x + z) % 2 == 0:
				var edge := _road_edge_distance(pos, road)
				if edge > 2.0 and edge < 9.0:
					var model: String = blocks[(x * 3 + z) % blocks.size()]
					_place(props, buildings, model, pos, float((x + z) * 17.0))
			z += 1
		x += 1


static func _place_city_skyline(props: Node3D, buildings: String, road: Dictionary) -> void:
	var towers := [
		"building-skyscraper-a.obj", "building-skyscraper-b.obj", "building-skyscraper-c.obj",
		"building-skyscraper-d.obj", "building-skyscraper-e.obj",
	]
	for x in range(-17, 29, 2):
		_place_if_clear(props, buildings, towers[abs(x) % towers.size()], Vector3(x, 0, -19), 0.0, road)
		_place_if_clear(props, buildings, towers[(abs(x) + 1) % towers.size()], Vector3(x, 0, 11), 180.0, road)
	for z in range(-19, 12, 2):
		_place_if_clear(props, buildings, towers[abs(z) % towers.size()], Vector3(-17, 0, z), 90.0, road)
		_place_if_clear(props, buildings, towers[(abs(z) + 2) % towers.size()], Vector3(28, 0, z), -90.0, road)


static func _place_city_streets(props: Node3D, roads: String, road: Dictionary) -> void:
	for x in range(-14, 26, 3):
		_place_if_clear(props, roads, "light-square.obj", Vector3(x, 0, 9), 0.0, road)
		_place_if_clear(props, roads, "light-curved.obj", Vector3(x, 0, -17), 0.0, road)
	for z in range(-18, 10, 3):
		_place_if_clear(props, roads, "construction-barrier.obj", Vector3(-12, 0, z), 90.0, road)
		_place_if_clear(props, roads, "construction-cone.obj", Vector3(24, 0, z), 0.0, road)
	_place_if_clear(props, roads, "road-bridge.obj", Vector3(25, 0, -6), -90.0, road)
	_place_if_clear(props, roads, "bridge-pillar.obj", Vector3(25, 0, -4), 0.0, road)
	_place_if_clear(props, roads, "bridge-pillar-wide.obj", Vector3(25, 0, -8), 0.0, road)
	_place_if_clear(props, roads, "sign-highway-detailed.obj", Vector3(-11, 0, -2), 90.0, road)


static func _place_city_racing_props(props: Node3D, kit: String, road: Dictionary) -> void:
	_place_if_clear(props, kit, "grandStandCovered.glb", Vector3(3.0, 0, -4.0), -90.0, road)
	_place_if_clear(props, kit, "grandStand.glb", Vector3(3.0, 0, -8.0), -90.0, road)
	_place_if_clear(props, kit, "grandStandRound.glb", Vector3(3.0, 0, -12.0), -90.0, road)
	_place_if_clear(props, kit, "grandStandCoveredRound.glb", Vector3(24.0, 0, -14.0), -90.0, road)
	_place_if_clear(props, kit, "billboard.glb", Vector3(24.5, 0, -6.0), -90.0, road)
	_place_if_clear(props, kit, "billboard.glb", Vector3(24.5, 0, 2.0), -90.0, road)
	_place_if_clear(props, kit, "tentClosed.glb", Vector3(-2.5, 0, -6.0), 90.0, road)
	_place_if_clear(props, kit, "tentLong.glb", Vector3(-2.5, 0, -10.0), 90.0, road)
	for z_off in [-4.0, -8.0, -12.0, 4.0, 8.0]:
		_place_if_clear(props, kit, "barrierWall.glb", Vector3(24.8, 0, z_off), -90.0, road)


static func _road_edge_distance(pos: Vector3, road: Dictionary) -> float:
	var dx := 0.0
	if pos.x < road.min_x:
		dx = road.min_x - pos.x
	elif pos.x > road.max_x:
		dx = pos.x - road.max_x
	var dz := 0.0
	if pos.z < road.min_z:
		dz = road.min_z - pos.z
	elif pos.z > road.max_z:
		dz = pos.z - road.max_z
	if dx > 0.0 and dz > 0.0:
		return sqrt(dx * dx + dz * dz)
	return maxf(dx, dz)


static func _on_road_expanded(pos: Vector3, road: Dictionary, margin: float) -> bool:
	return (
		pos.x >= road.min_x - margin and pos.x <= road.max_x + margin
		and pos.z >= road.min_z - margin and pos.z <= road.max_z + margin
	)


static func populate_nature(props: Node3D, nature: String) -> void:
	var road := {"min_x": -0.5, "max_x": 7.5, "min_z": -5.5, "max_z": 1.5}
	_fill_grid(props, nature + "ground_grass.fbx", -8, 12, -10, 6, 1.0, road)

	var trees := [
		Vector3(-2, 0, -2), Vector3(-3, 0, -5), Vector3(8, 0, -4),
		Vector3(8, 0, 2), Vector3(-1, 0, 3), Vector3(3, 0, -6),
		Vector3(2, 0, 0), Vector3(5, 0, -2), Vector3(-5, 0, -8),
		Vector3(10, 0, -7), Vector3(9, 0, 4), Vector3(-4, 0, 5),
	]
	var tree_models := ["tree_default.fbx", "tree_pineDefaultA.fbx", "tree_oak.fbx", "tree_cone.fbx"]
	for i in trees.size():
		if not _on_road(trees[i], road):
			_place(props, nature, tree_models[i % tree_models.size()], trees[i], float(i) * 40.0)

	var nature_props := [
		{"file": "rock_largeA.fbx", "pos": Vector3(-1, 0, -4)},
		{"file": "rock_largeC.fbx", "pos": Vector3(7, 0, -5)},
		{"file": "campfire_stones.fbx", "pos": Vector3(2, 0, -1)},
		{"file": "cactus_short.fbx", "pos": Vector3(8, 0, -6)},
		{"file": "bridge_wood.fbx", "pos": Vector3(11, 0, 0), "rot": -90.0},
	]
	for p in nature_props:
		if not _on_road(p.pos, road):
			_place(props, nature, p.file, p.pos, p.get("rot", 0.0))


static func _place_start_line(props: Node3D, kit: String, road: Dictionary) -> void:
	_place_if_clear(props, kit, "flagCheckers.glb", Vector3(-1.2, 0, -2.5), 90.0, road)
	_place_if_clear(props, kit, "flagGreen.glb", Vector3(-1.2, 0, -3.5), 90.0, road)
	_place_if_clear(props, kit, "lightColored.glb", Vector3(-1.2, 0, -6.0), 90.0, road)


static func _place_pit_complex(props: Node3D, kit: String, road: Dictionary) -> void:
	var garages := ["pitsGarage.glb", "pitsGarage.glb", "pitsGarageClosed.glb", "pitsOffice.glb"]
	for i in range(5):
		var z := -i * 2.0
		_place_if_clear(props, kit, garages[i % garages.size()], Vector3(-2.8, 0, z), 90.0, road)


static func _place_grandstands(props: Node3D, kit: String, road: Dictionary) -> void:
	var models := ["grandStand.glb", "grandStandCovered.glb", "grandStandRound.glb"]
	var z_pos := -2.0
	var idx := 0
	while z_pos >= -10.0:
		_place_if_clear(props, kit, models[idx % 3], Vector3(3.0, 0, z_pos), -90.0, road)
		_place_if_clear(props, kit, models[(idx + 1) % 3], Vector3(-2.0, 0, z_pos), 90.0, road)
		z_pos -= 2.0
		idx += 1
	for z_off in [-8.0, -10.0, -12.0]:
		_place_if_clear(props, kit, "grandStandCoveredRound.glb", Vector3(13.0, 0, z_off), -90.0, road)


static func _place_corners(props: Node3D, kit: String, road: Dictionary) -> void:
	var corners := [
		{"file": "roadCornerLargeSand.glb", "pos": Vector3(-1.0, 0, -11.0), "rot": 0.0},
		{"file": "roadCornerLargeWall.glb", "pos": Vector3(11.0, 0, -13.5), "rot": -90.0},
		{"file": "roadCornerLargeSand.glb", "pos": Vector3(12.5, 0, 1.0), "rot": 180.0},
	]
	for c in corners:
		_place_if_clear(props, kit, c.file, c.pos, c.rot, road)


static func _place_back_straight(props: Node3D, kit: String, road: Dictionary) -> void:
	for z in [-2.0, -6.0, -10.0]:
		_place_if_clear(props, kit, "billboard.glb", Vector3(13.2, 0, z), -90.0, road)


static func _place_if_clear(
	props: Node3D,
	folder: String,
	file: String,
	pos: Vector3,
	rot: float,
	road: Dictionary
) -> void:
	if not _on_road(pos, road):
		_place(props, folder, file, pos, rot)


static func _fill_grid(
	props: Node3D,
	asset: String,
	min_x: float,
	max_x: float,
	min_z: float,
	max_z: float,
	step: float,
	road: Dictionary
) -> void:
	if not ResourceLoader.exists(asset):
		return
	var x := min_x
	while x <= max_x:
		var z := min_z
		while z <= max_z:
			var pos := Vector3(x, -0.02, z)
			if not _on_road(pos, road):
				MeshFactory.place_piece(props, asset, "", pos, 0.0, false)
			z += step
		x += step


static func _on_road(pos: Vector3, road: Dictionary) -> bool:
	return (
		pos.x >= road.min_x and pos.x <= road.max_x
		and pos.z >= road.min_z and pos.z <= road.max_z
	)


static func _place(props: Node3D, folder: String, file: String, position: Vector3, rotation_y_deg: float = 0.0) -> void:
	var path := folder + file
	if ResourceLoader.exists(path):
		MeshFactory.place_piece(props, path, "", position, rotation_y_deg, true)
