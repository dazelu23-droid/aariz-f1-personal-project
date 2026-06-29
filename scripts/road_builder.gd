class_name RoadBuilder
extends RefCounted

const SLAB_H := 0.14
const CURB_H := 0.076
const CURB_W := 0.14


static func build_racing_circuit(
	track: Node3D,
	border: Node3D,
	fill: Node3D,
	kit: String
) -> Vector3:
	var tile := 2.0
	var width := 3.0
	var north := 10
	var east := 8
	var south := 10
	var west := 10
	var road: Dictionary = get_racing_layout()["bounds"]

	MeshFactory.add_start_finish_line(track, Vector3(0.5, SLAB_H + 0.02, -2.2), width)
	_place_decal(track, kit, "roadStraightArrow.glb", Vector3(0, 0, -2), 0.0)

	for i in range(1, north):
		_tile(track, border, Vector3(0, 0, -i * tile), 0.0, false, tile, width, true)
	_tile(track, border, Vector3(0, 0, -north * tile + tile), 0.0, true, tile, width, true)
	for i in range(east - 1):
		_tile(track, border, Vector3(2.0 + i * tile, 0, -north * tile), -90.0, false, tile, width, true)
	_tile(track, border, Vector3(2.0 + (east - 1) * tile, 0, -north * tile), -90.0, true, tile, width, true)
	var east_x := 2.0 + (east - 1) * tile
	for i in range(south - 1):
		_tile(track, border, Vector3(east_x, 0, -north * tile + tile + i * tile), 180.0, false, tile, width, true)
	_tile(track, border, Vector3(east_x, 0, -north * tile + south * tile), 180.0, true, tile, width, true)
	for i in range(west - 1):
		_tile(track, border, Vector3(east_x - tile - i * tile, 0, -north * tile + south * tile + tile), 90.0, false, tile, width, true)
	_tile(track, border, Vector3(0, 0, -north * tile + south * tile + tile), 90.0, true, tile, width, true)

	_fence_racing(border, kit, tile, width, north, east)
	_fill_ground_excluding(fill, road.min_x - 8, road.max_x + 8, road.min_z - 8, road.max_z + 8, 1.0, road, kit + "grass.glb")
	return Vector3(0.5, 0.0, -3.0)


static func get_racing_layout() -> Dictionary:
	var tile := 2.0
	var north := 10
	var east := 8
	var south := 10
	var west := 10
	var north_end := -north * tile
	var east_x := 2.0 + (east - 1) * tile
	var south_end := -north * tile + south * tile
	return {
		"tile": tile,
		"north": north,
		"east": east,
		"south": south,
		"west": west,
		"bounds": {
			"min_x": -1.0,
			"max_x": east_x + 1.5,
			"min_z": north_end - 1.5,
			"max_z": south_end + tile + 1.5,
		},
	}


static func build_city_circuit(
	track: Node3D,
	border: Node3D,
	fill: Node3D,
	kit: String
) -> Vector3:
	var tile := 2.0
	var width := 3.2
	var waypoints: Array = _city_street_waypoints()
	var layout: Dictionary = _build_waypoint_circuit(
		track, border, waypoints, tile, width, true, MeshFactory.ASPHALT, kit
	)
	MeshFactory.add_start_finish_line(
		track, waypoints[0] + Vector3(0.5, SLAB_H + 0.02, -1.6), width
	)
	_fill_ground_excluding(
		fill,
		layout.bounds.min_x - 20,
		layout.bounds.max_x + 20,
		layout.bounds.min_z - 20,
		layout.bounds.max_z + 20,
		2.0,
		layout.bounds,
		"",
		MeshFactory.CONCRETE
	)
	return waypoints[0] + Vector3(0.5, 0.0, -2.0)


static func get_city_layout() -> Dictionary:
	return _preview_waypoint_layout(_city_street_waypoints(), 2.0)


static func _city_street_waypoints() -> Array:
	# Grid-style downtown loop with many 90-degree street corners.
	return [
		Vector3(0, 0, 0),
		Vector3(0, 0, -14),
		Vector3(10, 0, -20),
		Vector3(22, 0, -20),
		Vector3(30, 0, -12),
		Vector3(30, 0, 2),
		Vector3(30, 0, 16),
		Vector3(20, 0, 22),
		Vector3(8, 0, 22),
		Vector3(-4, 0, 16),
		Vector3(-12, 0, 6),
		Vector3(-12, 0, -6),
		Vector3(-6, 0, -14),
		Vector3(0, 0, 0),
	]


static func _nature_trail_waypoints() -> Array:
	return [
		Vector3(0, 0, 0),
		Vector3(0, 0, -10),
		Vector3(6, 0, -15),
		Vector3(14, 0, -14),
		Vector3(18, 0, -6),
		Vector3(16, 0, 4),
		Vector3(10, 0, 12),
		Vector3(0, 0, 14),
		Vector3(-8, 0, 10),
		Vector3(-12, 0, 2),
		Vector3(-8, 0, -6),
		Vector3(0, 0, 0),
	]


static func _build_waypoint_circuit(
	track: Node3D,
	border: Node3D,
	waypoints: Array,
	tile: float,
	width: float,
	use_curbs: bool,
	surface: Color,
	kit: String = ""
) -> Dictionary:
	var samples: Array = []
	if waypoints.is_empty():
		return _layout_from_samples(samples, tile)

	samples.append(waypoints[0])
	if kit != "":
		_place_kit_road(track, kit, "roadStart.glb", waypoints[0], 0.0)
		_place_kit_road(track, kit, "roadStraightArrow.glb", waypoints[0] + Vector3(0, 0, -tile), 0.0)

	for seg_idx in range(waypoints.size() - 1):
		var a: Vector3 = waypoints[seg_idx]
		var b: Vector3 = waypoints[seg_idx + 1]
		var delta := b - a
		var seg_len := delta.length()
		if seg_len < 0.05:
			continue
		var dir := delta / seg_len
		var rot := _direction_to_rot(dir)
		var steps := maxi(1, int(round(seg_len / tile)))
		for step in range(steps):
			var t0 := float(step) / float(steps)
			var t1 := float(step + 1) / float(steps)
			var anchor := a + dir * (seg_len * t0)
			var center := a.lerp(b, (t0 + t1) * 0.5)
			var is_corner := seg_idx > 0 and step == 0
			_tile(track, border, anchor, rot, is_corner, tile, width, use_curbs, surface)
			samples.append(center)
		samples.append(b)

	return _layout_from_samples(samples, tile)


static func _preview_waypoint_layout(waypoints: Array, tile: float) -> Dictionary:
	var samples: Array = []
	if waypoints.is_empty():
		return _layout_from_samples(samples, tile)
	samples.append(waypoints[0])
	for seg_idx in range(waypoints.size() - 1):
		var a: Vector3 = waypoints[seg_idx]
		var b: Vector3 = waypoints[seg_idx + 1]
		var delta := b - a
		var seg_len := delta.length()
		if seg_len < 0.05:
			continue
		var dir := delta / seg_len
		var steps := maxi(1, int(round(seg_len / tile)))
		for step in range(steps):
			var t0 := float(step) / float(steps)
			var t1 := float(step + 1) / float(steps)
			samples.append(a.lerp(b, (t0 + t1) * 0.5))
		samples.append(b)
	return _layout_from_samples(samples, tile)


static func _direction_to_rot(dir: Vector3) -> float:
	if absf(dir.z) >= absf(dir.x):
		return 0.0 if dir.z < 0.0 else 180.0
	return -90.0 if dir.x > 0.0 else 90.0


static func _layout_from_samples(samples: Array, tile: float) -> Dictionary:
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for point in samples:
		var p: Vector3 = point
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_z = minf(min_z, p.z)
		max_z = maxf(max_z, p.z)
	var margin := 4.0
	return {
		"tile": tile,
		"samples": samples,
		"bounds": {
			"min_x": min_x - margin,
			"max_x": max_x + margin,
			"min_z": min_z - margin,
			"max_z": max_z + margin,
		},
	}


static func build_nature_circuit(
	track: Node3D,
	border: Node3D,
	fill: Node3D,
	nature: String
) -> Vector3:
	var tile := 1.25
	var width := 2.6
	var waypoints: Array = _nature_trail_waypoints()
	var layout: Dictionary = _build_waypoint_circuit(
		track, border, waypoints, tile, width, false, MeshFactory.DIRT
	)
	_fill_ground_excluding(
		fill,
		layout.bounds.min_x - 16,
		layout.bounds.max_x + 16,
		layout.bounds.min_z - 16,
		layout.bounds.max_z + 16,
		1.0,
		layout.bounds,
		nature + "ground_grass.fbx"
	)
	return waypoints[0] + Vector3(0.5, 0.0, -0.5)


static func get_nature_layout() -> Dictionary:
	var layout: Dictionary = _preview_waypoint_layout(_nature_trail_waypoints(), 1.25)
	layout["width"] = 2.6
	return layout


static func _tile(
	track: Node3D,
	border: Node3D,
	anchor: Vector3,
	rotation_y_deg: float,
	is_corner: bool,
	tile: float,
	width: float,
	f1_curbs: bool,
	surface_color: Color = MeshFactory.ASPHALT
) -> void:
	var spec := _slab_spec(anchor, rotation_y_deg, is_corner, tile, width)
	MeshFactory.add_surface_slab(track, spec.center, spec.size, rotation_y_deg, surface_color)
	if f1_curbs:
		MeshFactory.add_track_line(track, spec.line_center, spec.line_size, rotation_y_deg)
		_place_curbs(border, spec, rotation_y_deg)


static func _slab_spec(anchor: Vector3, rot: float, corner: bool, tile: float, width: float) -> Dictionary:
	if tile > 1.5:
		return _slab_spec_large(anchor, rot, corner, tile, width)
	return _slab_spec_small(anchor, rot, corner, tile, width)


static func _slab_spec_large(anchor: Vector3, rot: float, corner: bool, tile: float, width: float) -> Dictionary:
	if corner:
		return {
			"center": anchor + Vector3(0.5, SLAB_H * 0.5, -1.0),
			"size": Vector3(width + 0.2, SLAB_H, width + 0.2),
			"line_center": anchor + Vector3(0.5, SLAB_H + 0.015, -1.0),
			"line_size": Vector3(0.1, 0.02, width * 0.55),
		}
	var norm := int(rot) % 360
	if norm < 0:
		norm += 360
	match norm:
		0:
			return {
				"center": anchor + Vector3(0.5, SLAB_H * 0.5, -1.0),
				"size": Vector3(width, SLAB_H, tile + 0.08),
				"line_center": anchor + Vector3(0.5, SLAB_H + 0.015, -1.0),
				"line_size": Vector3(0.1, 0.02, tile),
			}
		270:
			return {
				"center": anchor + Vector3(1.0, SLAB_H * 0.5, -0.5),
				"size": Vector3(tile + 0.08, SLAB_H, width),
				"line_center": anchor + Vector3(1.0, SLAB_H + 0.015, -0.5),
				"line_size": Vector3(tile, 0.02, 0.1),
			}
		180:
			return {
				"center": anchor + Vector3(0.5, SLAB_H * 0.5, 1.0),
				"size": Vector3(width, SLAB_H, tile + 0.08),
				"line_center": anchor + Vector3(0.5, SLAB_H + 0.015, 1.0),
				"line_size": Vector3(0.1, 0.02, tile),
			}
		_:
			return {
				"center": anchor + Vector3(-1.0, SLAB_H * 0.5, -0.5),
				"size": Vector3(tile + 0.08, SLAB_H, width),
				"line_center": anchor + Vector3(-1.0, SLAB_H + 0.015, -0.5),
				"line_size": Vector3(tile, 0.02, 0.1),
			}


static func _slab_spec_small(anchor: Vector3, rot: float, corner: bool, tile: float, width: float) -> Dictionary:
	if corner:
		return {
			"center": anchor + Vector3(0.5, SLAB_H * 0.5, -0.5),
			"size": Vector3(width + 0.12, SLAB_H, width + 0.12),
			"line_center": anchor + Vector3(0.5, SLAB_H + 0.015, -0.5),
			"line_size": Vector3(0.08, 0.02, width * 0.45),
		}
	var norm := int(rot) % 360
	if norm < 0:
		norm += 360
	match norm:
		0:
			return {
				"center": anchor + Vector3(0.5, SLAB_H * 0.5, -0.5),
				"size": Vector3(width, SLAB_H, tile + 0.06),
				"line_center": anchor + Vector3(0.5, SLAB_H + 0.015, -0.5),
				"line_size": Vector3(0.08, 0.02, tile),
			}
		270:
			return {
				"center": anchor + Vector3(0.5, SLAB_H * 0.5, -0.5),
				"size": Vector3(tile + 0.06, SLAB_H, width),
				"line_center": anchor + Vector3(0.5, SLAB_H + 0.015, -0.5),
				"line_size": Vector3(tile, 0.02, 0.08),
			}
		180:
			return {
				"center": anchor + Vector3(0.5, SLAB_H * 0.5, 0.5),
				"size": Vector3(width, SLAB_H, tile + 0.06),
				"line_center": anchor + Vector3(0.5, SLAB_H + 0.015, 0.5),
				"line_size": Vector3(0.08, 0.02, tile),
			}
		_:
			return {
				"center": anchor + Vector3(-0.5, SLAB_H * 0.5, -0.5),
				"size": Vector3(tile + 0.06, SLAB_H, width),
				"line_center": anchor + Vector3(-0.5, SLAB_H + 0.015, -0.5),
				"line_size": Vector3(tile, 0.02, 0.08),
			}


static func _place_curbs(border: Node3D, spec: Dictionary, rot: float) -> void:
	var size: Vector3 = spec.size
	var center: Vector3 = spec.center
	var half_w := size.x * 0.5
	var half_l := size.z * 0.5
	var y := CURB_H * 0.5
	var long_len := maxf(size.x, size.z)
	var norm := int(rot) % 360
	if norm < 0:
		norm += 360

	match norm:
		0:
			MeshFactory.add_curb(border, center + Vector3(-half_w - 0.07, y, 0), Vector3(CURB_W, CURB_H, long_len), 0, MeshFactory.CURB_RED)
			MeshFactory.add_curb(border, center + Vector3(half_w + 0.07, y, 0), Vector3(CURB_W, CURB_H, long_len), 0, MeshFactory.CURB_WHITE)
		270:
			MeshFactory.add_curb(border, center + Vector3(0, y, -half_w - 0.07), Vector3(long_len, CURB_H, CURB_W), 0, MeshFactory.CURB_RED)
			MeshFactory.add_curb(border, center + Vector3(0, y, half_w + 0.07), Vector3(long_len, CURB_H, CURB_W), 0, MeshFactory.CURB_WHITE)
		180:
			MeshFactory.add_curb(border, center + Vector3(half_w + 0.07, y, 0), Vector3(CURB_W, CURB_H, long_len), 0, MeshFactory.CURB_RED)
			MeshFactory.add_curb(border, center + Vector3(-half_w - 0.07, y, 0), Vector3(CURB_W, CURB_H, long_len), 0, MeshFactory.CURB_WHITE)
		_:
			MeshFactory.add_curb(border, center + Vector3(0, y, half_w + 0.07), Vector3(long_len, CURB_H, CURB_W), 0, MeshFactory.CURB_RED)
			MeshFactory.add_curb(border, center + Vector3(0, y, -half_w - 0.07), Vector3(long_len, CURB_H, CURB_W), 0, MeshFactory.CURB_WHITE)


static func _fence_racing(
	border: Node3D,
	kit: String,
	tile: float,
	width: float,
	north: int,
	east: int
) -> void:
	var outer := width * 0.5 + 0.2
	var cx := tile * 0.5
	var north_end := -north * tile
	var east_x := 2.0 + (east - 1) * tile
	for z in range(0, int(north_end) - 1, -int(tile)):
		_place_decal(border, kit, "fenceStraight.glb", Vector3(cx + outer, 0, z), 0.0)
	for x in range(2, int(east_x) + 1, int(tile)):
		_place_decal(border, kit, "fenceStraight.glb", Vector3(x, 0, north_end - outer + 0.5), 90.0)
	for z in range(0, int(north_end) - 1, -int(tile)):
		_place_decal(border, kit, "fenceStraight.glb", Vector3(east_x + outer - 0.5, 0, z), 0.0)
	for x in range(int(east_x) - 1, -1, -int(tile)):
		_place_decal(border, kit, "fenceStraight.glb", Vector3(x, 0, north_end + tile + outer - 0.5), 90.0)


static func _fill_ground_excluding(
	fill: Node3D,
	min_x: float,
	max_x: float,
	min_z: float,
	max_z: float,
	step: float,
	road: Dictionary,
	asset: String = "",
	flat_color: Color = Color(-1, -1, -1)
) -> void:
	var x := min_x
	while x <= max_x:
		var z := min_z
		while z <= max_z:
			var pos := Vector3(x, -0.03, z)
			if not _on_road(pos, road):
				if flat_color.r >= 0.0:
					MeshFactory.add_surface_slab(
						fill, pos + Vector3(0, -0.02, 0), Vector3(step, 0.08, step), 0.0, flat_color
					)
				elif asset != "" and ResourceLoader.exists(asset):
					MeshFactory.place_piece(fill, asset, "", pos, 0.0, false)
			z += step
		x += step


static func _on_road(pos: Vector3, road: Dictionary) -> bool:
	return (
		pos.x >= road.min_x and pos.x <= road.max_x
		and pos.z >= road.min_z and pos.z <= road.max_z
	)


static func _place_kit_road(
	track: Node3D,
	folder: String,
	file: String,
	pos: Vector3,
	rot: float,
	with_collision: bool = true
) -> void:
	var path := folder + file
	if ResourceLoader.exists(path):
		MeshFactory.place_piece(track, path, "", pos, rot, with_collision)


static func _place_decal(track: Node3D, folder: String, file: String, pos: Vector3, rot: float) -> void:
	_place_kit_road(track, folder, file, pos, rot, false)
