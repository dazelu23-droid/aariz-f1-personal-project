class_name SceneryBuilder
extends RefCounted


static func populate_racing(props: Node3D, kit: String) -> void:
	var layout := RoadBuilder.get_racing_layout()
	var road: Dictionary = layout["bounds"]
	_fill_grid(props, kit + "grass.glb", road.min_x - 30, road.max_x + 30, road.min_z - 30, road.max_z + 30, 1.2, road)
	_place_racing_backdrop(props, kit, road)
	_place_start_line(props, kit)
	_place_pit_complex(props, kit, layout)
	_place_grandstands(props, kit, layout)


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
			_place_city_building_safe(props, buildings, p + perp * wall_gap, idx, samples, false)
			_place_city_building_safe(props, buildings, p - perp * wall_gap, idx + 1, samples, false)
			_place_city_building_safe(props, buildings, p + perp * far_gap, idx + 2, samples, true)
			_place_city_building_safe(props, buildings, p - perp * far_gap, idx + 3, samples, true)
			idx += 4


static func _place_city_building_safe(
	props: Node3D,
	buildings: String,
	pos: Vector3,
	idx: int,
	samples: Array,
	tall: bool = false
) -> void:
	if samples.size() > 1 and _near_path(pos, samples, 5.2 if tall else 4.2):
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
	var road_width: float = layout.get("width", 2.8)
	_fill_grid(
		props,
		nature + "ground_grass.fbx",
		road.min_x - 40,
		road.max_x + 40,
		road.min_z - 40,
		road.max_z + 40,
		1.0,
		road
	)
	_place_nature_lake(props, nature, samples, road_width)
	_scatter_nature_props(props, nature, road, samples, road_width)


static func _place_nature_lake(
	props: Node3D,
	nature: String,
	samples: Array,
	road_width: float
) -> void:
	var candidates: Array[Vector3] = [
		Vector3(44.0, 0.0, -42.0),
		Vector3(-46.0, 0.0, 40.0),
		Vector3(48.0, 0.0, 36.0),
	]
	var lake_center: Vector3 = candidates[0]
	for candidate in candidates:
		if not _near_path(candidate, samples, road_width * 0.5 + 12.0):
			lake_center = candidate
			break

	const TILE := 1.0
	const LAKE_W := 9
	const LAKE_D := 7
	var origin: Vector3 = lake_center - Vector3(LAKE_W * TILE * 0.5, 0.0, LAKE_D * TILE * 0.5)

	for ix in range(LAKE_W):
		for iz in range(LAKE_D):
			var pos := origin + Vector3(ix * TILE, -0.05, iz * TILE)
			if _near_path(pos, samples, road_width * 0.5 + 5.5):
				continue
			var edge := ix == 0 or iz == 0 or ix == LAKE_W - 1 or iz == LAKE_D - 1
			var tile := "ground_riverSide.fbx" if edge else "ground_riverTile.fbx"
			_place(props, nature, tile, pos, 0.0)

	var shore_models := [
		"rock_largeA.fbx", "rock_largeB.fbx", "rock_largeC.fbx",
		"stone_largeE.fbx", "stone_tallD.fbx", "rock_tallE.fbx",
	]
	var bush_models := ["plant_bush.fbx", "plant_bushSmall.fbx", "grass_large.fbx"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 44012
	var pad := 2.5

	for ix in range(-1, LAKE_W + 1):
		for iz in range(-1, LAKE_D + 1):
			var pos: Vector3 = origin + Vector3(ix * TILE, 0.0, iz * TILE)
			var on_shore := ix < 0 or iz < 0 or ix >= LAKE_W or iz >= LAKE_D
			if not on_shore:
				continue
			if _near_path(pos, samples, road_width * 0.5 + 4.0):
				continue
			var offsets: Array[Vector3] = [
				Vector3(pad, 0, 0), Vector3(-pad, 0, 0), Vector3(0, 0, pad), Vector3(0, 0, -pad),
			]
			for offset in offsets:
				var shore_pos: Vector3 = pos + offset
				if _near_path(shore_pos, samples, road_width * 0.5 + 3.5):
					continue
				if rng.randf() < 0.55:
					var rock: String = shore_models[rng.randi_range(0, shore_models.size() - 1)]
					_place(
						props, nature, rock, shore_pos,
						rng.randf_range(0.0, 360.0),
						Vector3.ONE * rng.randf_range(0.85, 1.25)
					)
				elif rng.randf() < 0.4:
					var bush: String = bush_models[rng.randi_range(0, bush_models.size() - 1)]
					_place(props, nature, bush, shore_pos, rng.randf_range(0.0, 360.0))


static func _scatter_nature_props(
	props: Node3D,
	nature: String,
	road: Dictionary,
	samples: Array,
	road_width: float
) -> void:
	if samples.size() < 2:
		return

	var tree_models := [
		"tree_default.fbx", "tree_pineDefaultA.fbx", "tree_pineDefaultB.fbx",
		"tree_oak.fbx", "tree_cone.fbx", "tree_detailed.fbx",
		"tree_pineTallB.fbx", "tree_pineRoundA.fbx", "tree_small.fbx",
		"tree_thin.fbx", "tree_blocks.fbx", "stump_old.fbx",
	]
	var rock_models := [
		"rock_largeA.fbx", "rock_largeB.fbx", "rock_largeC.fbx",
		"rock_smallA.fbx", "rock_smallB.fbx", "rock_smallC.fbx",
		"rock_tallE.fbx", "rock_smallFlatA.fbx",
		"stone_largeE.fbx", "stone_smallA.fbx", "stone_tallD.fbx",
	]
	var path_clearance: float = road_width * 0.5 + 2.4
	var pad := 6.0
	var min_x: float = road.min_x - pad
	var max_x: float = road.max_x + pad
	var min_z: float = road.min_z - pad
	var max_z: float = road.max_z + pad

	var rng := RandomNumberGenerator.new()
	rng.seed = 90210

	var placed := 0
	var max_props := 340
	var attempts := 0
	var max_attempts := 2400

	while placed < max_props and attempts < max_attempts:
		attempts += 1
		var pos := Vector3(rng.randf_range(min_x, max_x), 0.0, rng.randf_range(min_z, max_z))
		if _near_path(pos, samples, path_clearance):
			continue
		if rng.randf() > 0.48:
			continue

		var use_rock := rng.randf() < 0.38
		var models: Array = rock_models if use_rock else tree_models
		var model: String = models[rng.randi_range(0, models.size() - 1)]
		var rot := rng.randf_range(0.0, 360.0)
		var scale_val := rng.randf_range(0.75, 1.2) if use_rock else rng.randf_range(0.85, 1.35)
		_place(props, nature, model, pos, rot, Vector3.ONE * scale_val)
		placed += 1


static func _place_start_line(props: Node3D, kit: String) -> void:
	_place(props, kit, "flagCheckers.glb", Vector3(-4.5, 0, -2.5), 90.0)
	_place(props, kit, "flagGreen.glb", Vector3(-4.5, 0, -4.0), 90.0)
	_place(props, kit, "lightColored.glb", Vector3(-4.5, 0, -6.5), 90.0)
	_place(props, kit, "lightRed.glb", Vector3(4.5, 0, -2.5), -90.0)


static func _place_pit_complex(props: Node3D, kit: String, layout: Dictionary) -> void:
	var garages := ["pitsGarage.glb", "pitsGarage.glb", "pitsGarageClosed.glb", "pitsOffice.glb"]
	var pit_x := -8.0
	var z := -3.0
	var idx := 0
	while z >= -70.0:
		_place(props, kit, garages[idx % garages.size()], Vector3(pit_x, 0, z), 90.0)
		if idx % 4 == 1:
			_place(props, kit, "barrierRed.glb", Vector3(-5.8, 0, z + 0.6), 90.0)
		z -= 2.6
		idx += 1
	_place(props, kit, "pitsOffice.glb", Vector3(pit_x, 0, -1.5), 90.0)
	_place(props, kit, "flagBlue.glb", Vector3(-5.5, 0, -1.0), 90.0)
	_place(props, kit, "roadStart.glb", Vector3(-6.5, 0, -8.0), 90.0)


static func _place_grandstands(props: Node3D, kit: String, layout: Dictionary) -> void:
	var samples: Array = layout.get("samples", [])
	if samples.size() < 2:
		return

	var road_width: float = layout.get("width", 5.5)
	var models := ["grandStand.glb", "grandStandCovered.glb", "grandStandRound.glb"]
	var side_offset := road_width * 0.5 + 8.0
	var far_offset := road_width * 0.5 + 12.0
	var idx := 0

	for i in range(0, samples.size() - 1, 2):
		var a: Vector3 = samples[i]
		var b: Vector3 = samples[i + 1]
		if a.distance_squared_to(b) < 0.02:
			continue
		var dir := (b - a).normalized()
		var perp := Vector3(-dir.z, 0.0, dir.x)
		var p := a.lerp(b, 0.5)
		var face := rad_to_deg(atan2(dir.x, dir.z))

		var left := p + perp * side_offset
		var right := p - perp * side_offset
		if not _near_path(left, samples, road_width * 0.5 + 5.0):
			_place(props, kit, models[idx % 3], left, face + 90.0)
		if not _near_path(right, samples, road_width * 0.5 + 5.0):
			_place(props, kit, models[(idx + 1) % 3], right, face - 90.0)

		if idx % 3 == 0:
			var far_left := p + perp * far_offset
			var far_right := p - perp * far_offset
			if not _near_path(far_left, samples, road_width * 0.5 + 6.5):
				_place(props, kit, "grandStandCovered.glb", far_left, face + 90.0)
			if not _near_path(far_right, samples, road_width * 0.5 + 6.5):
				_place(props, kit, "grandStandRound.glb", far_right, face - 90.0)

		idx += 1

	_place_grandstand_horizon(props, kit, layout)


static func _place_grandstand_horizon(props: Node3D, kit: String, layout: Dictionary) -> void:
	var road: Dictionary = layout["bounds"]
	var samples: Array = layout.get("samples", [])
	var road_width: float = layout.get("width", 5.5)
	var models := ["grandStand.glb", "grandStandCovered.glb", "grandStandRound.glb", "grandStandCoveredRound.glb"]
	var clearance := road_width * 0.5 + 10.0
	var idx := 0
	var outer := 22.0

	for x in range(int(road.min_x) - 6, int(road.max_x) + 8, 4):
		var north := Vector3(x, 0, road.min_z - outer)
		var south := Vector3(x, 0, road.max_z + outer)
		if not _near_path(north, samples, clearance):
			_place(props, kit, models[idx % models.size()], north, 0.0)
		if not _near_path(south, samples, clearance):
			_place(props, kit, models[(idx + 2) % models.size()], south, 180.0)
		idx += 1

	for z in range(int(road.min_z) - 6, int(road.max_z) + 8, 4):
		var east := Vector3(road.max_x + outer, 0, z)
		var west := Vector3(road.min_x - outer, 0, z)
		if not _near_path(east, samples, clearance):
			_place(props, kit, models[idx % models.size()], east, -90.0)
		if not _near_path(west, samples, clearance):
			_place(props, kit, models[(idx + 1) % models.size()], west, 90.0)
		idx += 1


static func _place_corners(props: Node3D, kit: String, layout: Dictionary) -> void:
	var road: Dictionary = layout["bounds"]
	var corners := [
		{"file": "roadCornerLargeSand.glb", "pos": Vector3(road.min_x + 2.0, 0, road.min_z + 2.0), "rot": 0.0},
		{"file": "roadCornerLargeWall.glb", "pos": Vector3(road.max_x - 2.0, 0, road.min_z + 2.0), "rot": -90.0},
		{"file": "roadCornerLargeSand.glb", "pos": Vector3(road.max_x - 2.0, 0, road.max_z - 2.0), "rot": 180.0},
		{"file": "roadCornerLargeWall.glb", "pos": Vector3(road.min_x + 2.0, 0, road.max_z - 2.0), "rot": 90.0},
	]
	for c in corners:
		_place(props, kit, c.file, c.pos, c.rot)


static func _place_back_straight(props: Node3D, kit: String, layout: Dictionary) -> void:
	var road: Dictionary = layout["bounds"]
	var x: float = road.min_x + 12.0
	while x <= road.max_x - 12.0:
		_place(props, kit, "billboard.glb", Vector3(x, 0, road.min_z - 6.0), 0.0)
		x += 8.0


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


static func _place(props: Node3D, folder: String, file: String, position: Vector3, rotation_y_deg: float = 0.0, piece_scale: Vector3 = Vector3.ONE) -> void:
	var path := folder + file
	if ResourceLoader.exists(path):
		MeshFactory.place_piece(props, path, "", position, rotation_y_deg, false, piece_scale)
