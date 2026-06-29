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
	var layout := _build_kit_winding_circuit(track, kit, tile, _city_winding_legs())
	_fill_ground_excluding(
		fill,
		layout.bounds.min_x - 24,
		layout.bounds.max_x + 24,
		layout.bounds.min_z - 24,
		layout.bounds.max_z + 24,
		2.0,
		layout.bounds,
		"",
		MeshFactory.CONCRETE
	)
	return Vector3(0.5, 0.0, -1.0)


static func get_city_layout() -> Dictionary:
	return _preview_kit_layout(2.0, _city_winding_legs())


static func _city_winding_legs() -> Array:
	return [
		{"count": 5, "turn": "right"},
		{"count": 3, "turn": "right"},
		{"count": 4, "turn": "left"},
		{"count": 5, "turn": "right"},
		{"count": 2, "turn": "left"},
		{"count": 4, "turn": "sharp_right"},
		{"count": 3, "turn": "right"},
		{"count": 4, "turn": "left"},
		{"count": 5, "turn": "right"},
		{"count": 3, "turn": "left"},
		{"count": 4, "turn": "right"},
	]


static func _nature_winding_legs() -> Array:
	return [
		{"count": 4, "turn": "right"},
		{"count": 3, "turn": "left"},
		{"count": 5, "turn": "right"},
		{"count": 2, "turn": "sharp_right"},
		{"count": 3, "turn": "right"},
		{"count": 4, "turn": "left"},
		{"count": 4, "turn": "right"},
		{"count": 2, "turn": "left"},
		{"count": 5, "turn": "right"},
		{"count": 3, "turn": "sharp_right"},
		{"count": 4, "turn": "left"},
	]


static func _build_kit_winding_circuit(track: Node3D, kit: String, tile: float, legs: Array) -> Dictionary:
	var heading := 0
	var origin := Vector3.ZERO
	var samples: Array[Vector3] = [origin]

	_place_kit_road(track, kit, "roadStart.glb", origin, _heading_rot(heading))
	_place_kit_road(track, kit, "roadStraightArrow.glb", _kit_straight_position(origin, heading, 0, tile), _heading_rot(heading))
	samples.append(_kit_straight_position(origin, heading, 0, tile))

	for leg in legs:
		var count: int = leg.count
		_place_kit_leg(track, kit, origin, heading, count, tile)
		for i in range(count):
			samples.append(_kit_straight_position(origin, heading, i, tile))
		var corner_pos := _kit_corner_position(origin, heading, count, tile)
		_place_kit_corner_piece(track, kit, corner_pos, heading, leg.get("turn", "right"))
		samples.append(corner_pos)
		heading = _apply_turn(heading, leg.get("turn", "right"))
		origin = corner_pos

	return _layout_from_samples(samples, tile)


static func _preview_kit_layout(tile: float, legs: Array) -> Dictionary:
	var heading := 0
	var origin := Vector3.ZERO
	var samples: Array[Vector3] = [origin]
	for leg in legs:
		for i in range(leg.count):
			samples.append(_kit_straight_position(origin, heading, i, tile))
		var corner_pos := _kit_corner_position(origin, heading, leg.count, tile)
		samples.append(corner_pos)
		heading = _apply_turn(heading, leg.get("turn", "right"))
		origin = corner_pos
	return _layout_from_samples(samples, tile)


static func _place_kit_leg(
	track: Node3D,
	kit: String,
	origin: Vector3,
	heading: int,
	count: int,
	tile: float
) -> void:
	var rot := _heading_rot(heading)
	for i in range(count):
		_place_kit_road(track, kit, "roadStraightLong.glb", _kit_straight_position(origin, heading, i, tile), rot)


static func _kit_straight_position(origin: Vector3, heading: int, index: int, tile: float) -> Vector3:
	match heading:
		0:
			return origin + Vector3(0.0, 0.0, -float(index + 1) * tile)
		1:
			return origin + Vector3(tile + float(index) * tile, 0.0, -tile)
		2:
			return origin + Vector3(1.0, 0.0, tile + float(index) * tile)
		_:
			return origin + Vector3(-tile - float(index) * tile, 0.0, tile)


static func _kit_corner_position(origin: Vector3, heading: int, count: int, tile: float) -> Vector3:
	return _kit_straight_position(origin, heading, count - 1, tile)


static func _place_kit_corner_piece(
	track: Node3D,
	kit: String,
	pos: Vector3,
	heading: int,
	turn: String
) -> void:
	var piece := "roadCornerLargeBorder.glb"
	if turn == "sharp_right" or turn == "sharp_left":
		piece = "roadCornerSmallBorder.glb"
	_place_kit_road(track, kit, piece, pos, _heading_rot(heading))


static func _heading_rot(heading: int) -> float:
	match heading:
		0:
			return 0.0
		1:
			return -90.0
		2:
			return 180.0
		_:
			return 90.0


static func _apply_turn(heading: int, turn: String) -> int:
	match turn:
		"left", "sharp_left":
			return (heading + 3) % 4
		_:
			return (heading + 1) % 4


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
	var layout := _build_slab_winding_circuit(track, border, tile, width, _nature_winding_legs())
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
	return Vector3(0.5, 0.0, -0.5)


static func get_nature_layout() -> Dictionary:
	return _preview_slab_layout(1.25, _nature_winding_legs())


static func _build_slab_winding_circuit(
	track: Node3D,
	border: Node3D,
	tile: float,
	width: float,
	legs: Array
) -> Dictionary:
	var heading := 0
	var origin := Vector3.ZERO
	var samples: Array[Vector3] = [origin]

	for leg in legs:
		var count: int = leg.count
		for i in range(count):
			_tile(
				track,
				border,
				_slab_straight_position(origin, heading, i, tile),
				_heading_rot(heading),
				i == count - 1,
				tile,
				width,
				false,
				MeshFactory.DIRT
			)
			samples.append(_slab_straight_position(origin, heading, i, tile))
		var corner_pos := _slab_corner_position(origin, heading, count, tile)
		heading = _apply_turn(heading, leg.get("turn", "right"))
		origin = corner_pos
		samples.append(corner_pos)

	return _layout_from_samples(samples, tile)


static func _preview_slab_layout(tile: float, legs: Array) -> Dictionary:
	var heading := 0
	var origin := Vector3.ZERO
	var samples: Array[Vector3] = [origin]
	for leg in legs:
		for i in range(leg.count):
			samples.append(_slab_straight_position(origin, heading, i, tile))
		var corner_pos := _slab_corner_position(origin, heading, leg.count, tile)
		heading = _apply_turn(heading, leg.get("turn", "right"))
		origin = corner_pos
		samples.append(corner_pos)
	var layout := _layout_from_samples(samples, tile)
	layout["width"] = 2.6
	return layout


static func _slab_straight_position(origin: Vector3, heading: int, index: int, tile: float) -> Vector3:
	match heading:
		0:
			return origin + Vector3(0.0, 0.0, -float(index) * tile)
		1:
			return origin + Vector3(float(index) * tile, 0.0, 0.0)
		2:
			return origin + Vector3(0.0, 0.0, float(index) * tile)
		_:
			return origin + Vector3(-float(index) * tile, 0.0, 0.0)


static func _slab_corner_position(origin: Vector3, heading: int, count: int, tile: float) -> Vector3:
	return _slab_straight_position(origin, heading, count - 1, tile)


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
