class_name SceneryBuilder
extends RefCounted


static func populate_racing(props: Node3D, kit: String) -> void:
	var road: Dictionary = RoadBuilder.get_racing_layout()["bounds"]
	_fill_grid(props, kit + "grass.glb", road.min_x - 22, road.max_x + 22, road.min_z - 22, road.max_z + 22, 1.2, road)
	_place_racing_backdrop(props, kit, road)
	_place_start_line(props, kit, road)
	_place_pit_complex(props, kit, road)
	_place_grandstands(props, kit, road)
	_place_corners(props, kit, road)
	_place_back_straight(props, kit, road)


static func _place_racing_backdrop(props: Node3D, kit: String, road: Dictionary) -> void:
	for x in range(int(road.min_x) - 14, int(road.max_x) + 16, 2):
		_place_if_clear(props, kit, "treeLarge.glb", Vector3(x, 0, road.min_z - 16), 0.0, road, 8.0)
		_place_if_clear(props, kit, "treeSmall.glb", Vector3(x, 0, road.max_z + 16), 180.0, road, 8.0)
	for z in range(int(road.min_z) - 14, int(road.max_z) + 16, 2):
		_place_if_clear(props, kit, "treeLarge.glb", Vector3(road.min_x - 16, 0, z), 90.0, road, 8.0)
		_place_if_clear(props, kit, "treeSmall.glb", Vector3(road.max_x + 16, 0, z), -90.0, road, 8.0)


static func populate_city(props: Node3D, roads: String, buildings: String, _racing_kit: String = "") -> void:
	var layout := RoadBuilder.get_city_layout()
	_place_city_canyon_walls(props, buildings, layout)
	_place_city_path_lights(props, roads, layout)
	_place_city_skyline_backdrop(props, buildings, layout.bounds)


static func _place_city_canyon_walls(props: Node3D, buildings: String, layout: Dictionary) -> void:
	var road: Dictionary = layout.bounds
	var samples: Array = layout.get("samples", [])
	var wall_gap := 5.5
	var far_gap := 8.0
	var idx := 0

	if samples.size() < 2:
		return

	for i in range(samples.size() - 1):
		var a: Vector3 = samples[i]
		var b: Vector3 = samples[i + 1]
		if a.distance_squared_to(b) < 0.01:
			continue
		var dir := (b - a).normalized()
		var perp := Vector3(-dir.z, 0.0, dir.x)
		var span := a.distance_to(b)
		var steps := maxi(1, int(span / 1.5))
		for step in range(steps + 1):
			var t := float(step) / float(steps)
			var p := a.lerp(b, t)
			_place_city_building_safe(props, buildings, p + perp * wall_gap, idx, road, false, samples, false)
			_place_city_building_safe(props, buildings, p - perp * wall_gap, idx + 1, road, false, samples, false)
			_place_city_building_safe(props, buildings, p + perp * far_gap, idx + 2, road, true, samples, false)
			_place_city_building_safe(props, buildings, p - perp * far_gap, idx + 3, road, true, samples, false)
			idx += 4


static func _place_city_building_safe(
	props: Node3D,
	buildings: String,
	pos: Vector3,
	idx: int,
	road: Dictionary,
	tall: bool = false,
	samples: Array = [],
	check_path: bool = true
) -> void:
	if _on_road_expanded(pos, road, 4.5):
		return
	if check_path and samples.size() > 1 and _near_path(pos, samples, 4.0):
		return
	_place_city_building(props, buildings, pos, idx, tall)


static func _near_path(pos: Vector3, samples: Array, clearance: float) -> bool:
	for i in range(samples.size() - 1):
		var a: Vector3 = samples[i]
		var b: Vector3 = samples[i + 1]
		if _point_segment_distance(pos, a, b) < clearance:
			return true
	return false


static func _point_segment_distance(point: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq < 0.0001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / len_sq, 0.0, 1.0)
	return point.distance_to(a + ab * t)


static func _place_city_path_lights(props: Node3D, roads: String, layout: Dictionary) -> void:
	var samples: Array = layout.get("samples", [])
	var road: Dictionary = layout.bounds
	for i in range(0, maxi(0, samples.size() - 1), 3):
		var p: Vector3 = samples[i]
		var q: Vector3 = samples[i + 1]
		if p.distance_squared_to(q) < 0.01:
			continue
		var dir := (q - p).normalized()
		var perp := Vector3(-dir.z, 0.0, dir.x)
		var light_pos := p + perp * 4.2
		var rot := rad_to_deg(atan2(dir.x, dir.z))
		_place_if_clear(props, roads, "light-square.obj", light_pos, rot, road, 3.0)


static func _place_city_skyline_backdrop(props: Node3D, buildings: String, road: Dictionary) -> void:
	var towers := [
		"building-skyscraper-a.obj", "building-skyscraper-b.obj", "building-skyscraper-c.obj",
		"building-skyscraper-d.obj", "building-skyscraper-e.obj",
	]
	var pad := 14.0
	for x in range(int(road.min_x) - 8, int(road.max_x) + 10, 4):
		_place_if_clear(props, buildings, towers[abs(x) % towers.size()], Vector3(x, 0, road.min_z - pad), 0.0, road, 6.0)
		_place_if_clear(props, buildings, towers[(abs(x) + 1) % towers.size()], Vector3(x, 0, road.max_z + pad), 180.0, road, 6.0)
	for z in range(int(road.min_z) - 8, int(road.max_z) + 10, 4):
		_place_if_clear(props, buildings, towers[abs(z) % towers.size()], Vector3(road.min_x - pad, 0, z), 90.0, road, 6.0)
		_place_if_clear(props, buildings, towers[(abs(z) + 2) % towers.size()], Vector3(road.max_x + pad, 0, z), -90.0, road, 6.0)


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
	var layout: Dictionary = RoadBuilder.get_nature_layout()
	var road: Dictionary = layout.bounds
	var samples: Array = layout.get("samples", [])
	_fill_grid(
		props,
		nature + "ground_grass.fbx",
		road.min_x - 24,
		road.max_x + 24,
		road.min_z - 24,
		road.max_z + 24,
		1.0,
		road
	)
	_place_nature_backdrop(props, nature, road)
	_place_nature_trees(props, nature, road, samples)
	_place_nature_rock_borders(props, nature, samples, road)


static func _place_nature_trees(props: Node3D, nature: String, road: Dictionary, samples: Array) -> void:
	var min_x := int(road.min_x) - 10
	var max_x := int(road.max_x) + 10
	var min_z := int(road.min_z) - 10
	var max_z := int(road.max_z) + 10
	var tree_models := ["tree_default.fbx", "tree_pineDefaultA.fbx", "tree_oak.fbx", "tree_cone.fbx"]
	var idx := 0
	for x in range(min_x, max_x, 2):
		for z in range(min_z, max_z, 2):
			var pos := Vector3(x, 0, z)
			if _on_road_expanded(pos, road, 2.5):
				continue
			if samples.size() > 1 and _near_path(pos, samples, 3.2):
				continue
			if (x + z) % 3 != 0:
				continue
			_place(props, nature, tree_models[idx % tree_models.size()], pos, float(idx) * 29.0)
			idx += 1


static func _place_nature_rock_borders(props: Node3D, nature: String, samples: Array, road: Dictionary) -> void:
	if samples.size() < 2:
		return
	var rock_models := [
		"rock_largeA.fbx", "rock_largeB.fbx", "rock_largeC.fbx",
		"rock_smallA.fbx", "rock_smallB.fbx", "rock_smallC.fbx",
	]
	var idx := 0
	for i in range(0, samples.size() - 1, 1):
		var a: Vector3 = samples[i]
		var b: Vector3 = samples[i + 1]
		if a.distance_squared_to(b) < 0.02:
			continue
		var dir := (b - a).normalized()
		var perp := Vector3(-dir.z, 0.0, dir.x)
		for side in [-1.0, 1.0]:
			var p := a.lerp(b, 0.5) + perp * side * 3.8
			if _on_road_expanded(p, road, 2.0):
				continue
			if _near_path(p, samples, 2.4):
				continue
			_place(props, nature, rock_models[idx % rock_models.size()], p, float(idx) * 41.0)
			idx += 1


static func _place_nature_backdrop(props: Node3D, nature: String, road: Dictionary) -> void:
	var tree_models := ["tree_pineDefaultA.fbx", "tree_oak.fbx", "tree_default.fbx"]
	var pad := 18.0
	for x in range(int(road.min_x) - 12, int(road.max_x) + 14, 3):
		_place(props, nature, tree_models[abs(x) % tree_models.size()], Vector3(x, 0, road.min_z - pad), float(x))
		_place(props, nature, tree_models[(abs(x) + 1) % tree_models.size()], Vector3(x, 0, road.max_z + pad), float(x) + 90.0)
	for z in range(int(road.min_z) - 12, int(road.max_z) + 14, 3):
		_place(props, nature, tree_models[abs(z) % tree_models.size()], Vector3(road.min_x - pad, 0, z), float(z))
		_place(props, nature, tree_models[(abs(z) + 2) % tree_models.size()], Vector3(road.max_x + pad, 0, z), float(z) + 45.0)


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
