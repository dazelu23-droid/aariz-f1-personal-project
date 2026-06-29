class_name SceneryBuilder
extends RefCounted


static func populate_racing(props: Node3D, kit: String) -> void:
	var road: Dictionary = RoadBuilder.get_racing_layout()["bounds"]
	_fill_grid(props, kit + "grass.glb", road.min_x - 6, road.max_x + 6, road.min_z - 6, road.max_z + 6, 1.2, road)
	_place_start_line(props, kit, road)
	_place_pit_complex(props, kit, road)
	_place_grandstands(props, kit, road)
	_place_corners(props, kit, road)
	_place_back_straight(props, kit, road)


static func populate_city(props: Node3D, roads: String, buildings: String, _racing_kit: String = "") -> void:
	var layout := RoadBuilder.get_city_layout()
	_place_city_canyon_walls(props, buildings, layout)
	_place_city_outer_fill(props, buildings, layout.bounds)
	_place_city_street_lights(props, roads, layout.bounds)


static func _place_city_canyon_walls(props: Node3D, buildings: String, layout: Dictionary) -> void:
	var bounds: Dictionary = layout.bounds
	var tile: float = layout.tile
	var north_end: float = bounds.north_end
	var east_z: float = bounds.east_z
	var east_end: float = bounds.east_end
	var south_x: float = bounds.south_x
	var south_end: float = bounds.south_end
	var west_z: float = bounds.west_z
	var road: Dictionary = bounds
	var step := 1.6
	var wall_gap := 7.5
	var far_gap := 10.5
	var idx := 0

	# North straight — outer canyon walls only (well clear of asphalt).
	var z := 0.5
	while z >= north_end - 0.5:
		_place_city_building_safe(props, buildings, Vector3(-wall_gap, 0, z), idx, road)
		_place_city_building_safe(props, buildings, Vector3(wall_gap + 1.5, 0, z), idx + 1, road)
		_place_city_building_safe(props, buildings, Vector3(-far_gap, 0, z), idx + 2, road, true)
		_place_city_building_safe(props, buildings, Vector3(far_gap + 1.5, 0, z), idx + 3, road, true)
		z -= step
		idx += 4

	# East straight — buildings north of the road only.
	var x := tile
	while x <= east_end + 0.5:
		_place_city_building_safe(props, buildings, Vector3(x, 0, east_z - wall_gap), idx, road)
		_place_city_building_safe(props, buildings, Vector3(x, 0, east_z - far_gap), idx + 1, road, true)
		x += step
		idx += 2

	# South straight — buildings east of the road only.
	z = north_end
	while z <= south_end + 0.5:
		_place_city_building_safe(props, buildings, Vector3(south_x + wall_gap, 0, z), idx, road)
		_place_city_building_safe(props, buildings, Vector3(south_x + far_gap, 0, z), idx + 1, road, true)
		z += step
		idx += 2

	# West straight — buildings south of the road only.
	x = south_x - tile
	while x >= 0.0:
		_place_city_building_safe(props, buildings, Vector3(x, 0, west_z + wall_gap), idx, road)
		_place_city_building_safe(props, buildings, Vector3(x, 0, west_z + far_gap), idx + 1, road, true)
		x -= step
		idx += 2

	# Corner skyscrapers sit on outer wall offsets only.
	var corners := [
		Vector3(-wall_gap, 0, 0.5),
		Vector3(wall_gap + 1.5, 0, north_end - 0.5),
		Vector3(east_end + wall_gap, 0, east_z - wall_gap),
		Vector3(south_x + wall_gap, 0, south_end + 0.5),
		Vector3(0.5, 0, west_z + wall_gap),
	]
	for i in corners.size():
		_place_city_building_safe(props, buildings, corners[i], idx + i, road, true)


static func _place_city_building_safe(
	props: Node3D,
	buildings: String,
	pos: Vector3,
	idx: int,
	road: Dictionary,
	tall: bool = false
) -> void:
	if _on_road_expanded(pos, road, 6.0):
		return
	_place_city_building(props, buildings, pos, idx, tall)


static func _place_city_outer_fill(props: Node3D, buildings: String, road: Dictionary) -> void:
	var towers := [
		"building-skyscraper-a.obj", "building-skyscraper-b.obj", "building-skyscraper-c.obj",
		"building-skyscraper-d.obj", "building-skyscraper-e.obj",
	]
	var low := [
		"low-detail-building-a.obj", "low-detail-building-b.obj", "low-detail-building-c.obj",
		"low-detail-building-d.obj", "low-detail-building-e.obj", "low-detail-building-f.obj",
	]
	var pad := 8.0
	for x in range(int(road.min_x) - 20, int(road.max_x) + 22, 2):
		_place_if_clear(props, buildings, towers[abs(x) % towers.size()], Vector3(x, 0, road.min_z - pad), 0.0, road, 5.0)
		_place_if_clear(props, buildings, towers[(abs(x) + 2) % towers.size()], Vector3(x, 0, road.max_z + pad), 180.0, road, 5.0)
	for z in range(int(road.min_z) - 18, int(road.max_z) + 20, 2):
		_place_if_clear(props, buildings, towers[abs(z) % towers.size()], Vector3(road.min_x - pad, 0, z), 90.0, road, 5.0)
		_place_if_clear(props, buildings, towers[(abs(z) + 1) % towers.size()], Vector3(road.max_x + pad, 0, z), -90.0, road, 5.0)
	for x in range(int(road.min_x) - 8, int(road.max_x) + 10, 4):
		for z in range(int(road.min_z) - 8, int(road.max_z) + 10, 4):
			var pos := Vector3(x, 0, z)
			if _on_road_expanded(pos, road, 7.0):
				continue
			var edge := _road_edge_distance(pos, road)
			if edge < 12.0 or edge > 28.0:
				continue
			_place(props, buildings, low[(x + z) % low.size()], pos, float((x + z) * 23.0))


static func _place_city_street_lights(props: Node3D, roads: String, road: Dictionary) -> void:
	for x in range(int(road.min_x) - 4, int(road.max_x) + 6, 6):
		_place_if_clear(props, roads, "light-square.obj", Vector3(x, 0, road.min_z - 5.5), 0.0, road, 4.0)
		_place_if_clear(props, roads, "light-curved.obj", Vector3(x, 0, road.max_z + 5.5), 180.0, road, 4.0)
	for z in range(int(road.min_z) - 4, int(road.max_z) + 6, 6):
		_place_if_clear(props, roads, "light-square.obj", Vector3(road.min_x - 5.5, 0, z), 90.0, road, 4.0)
		_place_if_clear(props, roads, "light-curved.obj", Vector3(road.max_x + 5.5, 0, z), -90.0, road, 4.0)


static func _place_city_building(
	props: Node3D,
	buildings: String,
	pos: Vector3,
	idx: int,
	tall: bool = false
) -> void:
	var regular := [
		"building-a.obj", "building-b.obj", "building-c.obj", "building-d.obj",
		"building-e.obj", "building-f.obj", "building-g.obj", "building-h.obj",
		"building-i.obj", "building-j.obj", "building-k.obj", "building-l.obj",
		"building-m.obj", "building-n.obj",
	]
	var towers := [
		"building-skyscraper-a.obj", "building-skyscraper-b.obj", "building-skyscraper-c.obj",
		"building-skyscraper-d.obj", "building-skyscraper-e.obj",
	]
	var pool: Array = towers if tall else regular
	var model: String = pool[idx % pool.size()]
	_place(props, buildings, model, pos, float((idx * 37 + int(pos.x * 10.0) + int(pos.z * 7.0)) % 360))


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
	var road: Dictionary = RoadBuilder.get_nature_layout()["bounds"]
	_fill_grid(
		props,
		nature + "ground_grass.fbx",
		road.min_x - 10,
		road.max_x + 10,
		road.min_z - 10,
		road.max_z + 10,
		1.0,
		road
	)

	var min_x := int(road.min_x) - 8
	var max_x := int(road.max_x) + 8
	var min_z := int(road.min_z) - 8
	var max_z := int(road.max_z) + 8
	var tree_models := ["tree_default.fbx", "tree_pineDefaultA.fbx", "tree_oak.fbx", "tree_cone.fbx"]
	var idx := 0
	for x in range(min_x, max_x, 2):
		for z in range(min_z, max_z, 2):
			if _on_road_expanded(Vector3(x, 0, z), road, 2.0):
				continue
			if (x + z) % 3 != 0:
				continue
			_place(props, nature, tree_models[idx % tree_models.size()], Vector3(x, 0, z), float(idx) * 29.0)
			idx += 1

	var rock_spots := [
		Vector3(road.min_x - 2, 0, road.min_z + 2),
		Vector3(road.max_x + 1, 0, road.min_z + 1),
		Vector3(road.max_x, 0, road.max_z + 2),
		Vector3(road.min_x - 1, 0, road.max_z),
	]
	for i in rock_spots.size():
		if not _on_road_expanded(rock_spots[i], road, 2.5):
			_place(props, nature, "rock_largeA.fbx" if i % 2 == 0 else "rock_largeC.fbx", rock_spots[i], float(i) * 45.0)


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
	while z_pos >= road.min_z + 2.0:
		_place_if_clear(props, kit, models[idx % 3], Vector3(road.max_x - 2.0, 0, z_pos), -90.0, road, 2.5)
		_place_if_clear(props, kit, models[(idx + 1) % 3], Vector3(road.min_x - 1.5, 0, z_pos), 90.0, road, 2.5)
		z_pos -= 2.0
		idx += 1
	for z_off in [road.min_z + 4.0, road.min_z + 2.0, road.min_z]:
		if z_off > road.min_z - 6.0:
			_place_if_clear(props, kit, "grandStandCoveredRound.glb", Vector3(road.max_x - 1.0, 0, z_off), -90.0, road, 2.5)


static func _place_corners(props: Node3D, kit: String, road: Dictionary) -> void:
	var corners := [
		{"file": "roadCornerLargeSand.glb", "pos": Vector3(road.min_x, 0, road.min_z + 2.0), "rot": 0.0},
		{"file": "roadCornerLargeWall.glb", "pos": Vector3(road.max_x - 2.0, 0, road.min_z), "rot": -90.0},
		{"file": "roadCornerLargeSand.glb", "pos": Vector3(road.max_x - 1.0, 0, road.max_z - 1.0), "rot": 180.0},
	]
	for c in corners:
		_place_if_clear(props, kit, c.file, c.pos, c.rot, road, 2.0)


static func _place_back_straight(props: Node3D, kit: String, road: Dictionary) -> void:
	var z := -2.0
	while z >= road.min_z + 4.0:
		_place_if_clear(props, kit, "billboard.glb", Vector3(road.max_x - 0.5, 0, z), -90.0, road, 2.5)
		z -= 4.0


static func _place_if_clear(
	props: Node3D,
	folder: String,
	file: String,
	pos: Vector3,
	rot: float,
	road: Dictionary,
	margin: float = 1.5
) -> void:
	if not _on_road_expanded(pos, road, margin):
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
