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
	var road := {"min_x": -1.0, "max_x": 12.0, "min_z": -13.0, "max_z": 3.0}

	MeshFactory.add_start_finish_line(track, Vector3(0.5, SLAB_H + 0.02, -2.2), width)
	_place_decal(track, kit, "roadStraightArrow.glb", Vector3(0, 0, -2), 0.0)

	for i in range(1, 6):
		_tile(track, border, Vector3(0, 0, -i * tile), 0.0, false, tile, width, true)
	_tile(track, border, Vector3(0, 0, -10), 0.0, true, tile, width, true)
	for i in range(4):
		_tile(track, border, Vector3(2.0 + i * tile, 0, -12), -90.0, false, tile, width, true)
	_tile(track, border, Vector3(10, 0, -12), -90.0, true, tile, width, true)
	for i in range(5):
		_tile(track, border, Vector3(11, 0, -10 + i * tile), 180.0, false, tile, width, true)
	_tile(track, border, Vector3(11, 0, 0), 180.0, true, tile, width, true)
	for i in range(5):
		_tile(track, border, Vector3(9 - i * tile, 0, 2), 90.0, false, tile, width, true)
	_tile(track, border, Vector3(0, 0, 0), 90.0, true, tile, width, true)

	_fence_racing(border, kit, tile, width)
	_fill_ground_excluding(fill, -5, 16, -16, 6, 1.0, road, kit + "grass.glb")
	return Vector3(0.5, 0.0, -3.0)


static func build_city_circuit(
	track: Node3D,
	border: Node3D,
	fill: Node3D,
	kit: String
) -> Vector3:
	var tile := 2.0
	var north := 8
	var east := 10
	var south := 8
	var west := 10
	var road := _kit_road_bounds(tile, north, east, south, west)

	_build_kit_rect_circuit(track, kit, tile, north, east, south, west)
	_place_city_track_barriers(border, kit, tile, north, east, south, west)
	_fill_ground_excluding(fill, -18, 28, -22, 10, 2.0, road, "", MeshFactory.CONCRETE)
	return Vector3(0.5, 0.0, -1.0)


static func _build_kit_rect_circuit(
	track: Node3D,
	kit: String,
	tile: float,
	north: int,
	east: int,
	south: int,
	west: int
) -> void:
	_place_kit_road(track, kit, "roadStart.glb", Vector3.ZERO, 0.0)
	_place_kit_road(track, kit, "roadStraightArrow.glb", Vector3(0, 0, -tile), 0.0)

	for i in range(1, north + 1):
		_place_kit_road(track, kit, "roadStraightLong.glb", Vector3(0, 0, -i * tile), 0.0)
	_place_kit_road(track, kit, "roadCornerLargeBorder.glb", Vector3(0, 0, -north * tile), 0.0)

	var north_end := -north * tile
	var east_z := north_end - tile
	for i in range(east):
		_place_kit_road(track, kit, "roadStraightLong.glb", Vector3(tile + i * tile, 0, east_z), -90.0)
	_place_kit_road(
		track, kit, "roadCornerLargeBorder.glb", Vector3(tile + east * tile, 0, east_z), -90.0
	)

	var east_end := tile + east * tile
	var south_x := east_end + 1.0
	for i in range(south):
		_place_kit_road(
			track, kit, "roadStraightLong.glb", Vector3(south_x, 0, north_end + i * tile), 180.0
		)
	_place_kit_road(
		track, kit, "roadCornerLargeBorder.glb", Vector3(south_x, 0, north_end + south * tile), 180.0
	)

	var south_end := north_end + south * tile
	var west_z := south_end + tile
	for i in range(west):
		_place_kit_road(
			track, kit, "roadStraightLong.glb", Vector3(south_x - tile - i * tile, 0, west_z), 90.0
		)
	_place_kit_road(track, kit, "roadCornerLargeBorder.glb", Vector3.ZERO, 90.0)


static func _kit_road_bounds(tile: float, north: int, east: int, south: int, west: int) -> Dictionary:
	var north_end := -north * tile
	var east_z := north_end - tile
	var east_end := tile + east * tile
	var south_end := north_end + south * tile
	var west_z := south_end + tile
	return {
		"min_x": -1.0,
		"max_x": east_end + 2.0,
		"min_z": east_z - 1.0,
		"max_z": west_z + 1.0,
		"north_end": north_end,
		"east_z": east_z,
		"east_end": east_end,
		"south_x": east_end + 1.0,
		"south_end": south_end,
		"west_z": west_z,
	}


static func _place_city_track_barriers(
	border: Node3D,
	kit: String,
	tile: float,
	north: int,
	east: int,
	south: int,
	west: int
) -> void:
	var bounds := _kit_road_bounds(tile, north, east, south, west)
	var offset := 1.35
	for i in range(north):
		var z := -tile - i * tile
		_place_kit_road(border, kit, "barrierRed.glb", Vector3(-offset, 0, z), 0.0, false)
		_place_kit_road(border, kit, "barrierWhite.glb", Vector3(0.35, 0, z), 0.0, false)
	for i in range(east):
		var x := tile + i * tile
		_place_kit_road(border, kit, "barrierRed.glb", Vector3(x, 0, bounds.east_z - offset), 90.0, false)
	for i in range(south):
		var z: float = bounds.north_end + i * tile
		_place_kit_road(border, kit, "barrierWhite.glb", Vector3(bounds.south_x + offset - tile, 0, z), 0.0, false)
	for i in range(west):
		var x: float = bounds.south_x - tile - i * tile
		_place_kit_road(border, kit, "barrierRed.glb", Vector3(x, 0, bounds.west_z + offset), 90.0, false)
	_place_kit_road(border, kit, "lightColored.glb", Vector3(-1.2, 0, -tile), 90.0, false)
	_place_kit_road(border, kit, "flagCheckers.glb", Vector3(-1.2, 0, -tile * 2.0), 90.0, false)


static func build_nature_circuit(
	track: Node3D,
	border: Node3D,
	fill: Node3D,
	nature: String
) -> Vector3:
	var tile := 1.0
	var width := 2.4
	var road := {"min_x": -0.5, "max_x": 7.5, "min_z": -5.5, "max_z": 1.5}

	for i in range(4):
		_tile(track, border, Vector3(0, 0, -i), 0.0, false, tile, width, false, MeshFactory.DIRT)
	_tile(track, border, Vector3(0, 0, -4), 0.0, true, tile, width, false, MeshFactory.DIRT)
	for i in range(5):
		_tile(track, border, Vector3(1 + i, 0, -5), -90.0, false, tile, width, false, MeshFactory.DIRT)
	_tile(track, border, Vector3(6, 0, -5), -90.0, true, tile, width, false, MeshFactory.DIRT)
	for i in range(4):
		_tile(track, border, Vector3(7, 0, -4 + i), 180.0, false, tile, width, false, MeshFactory.DIRT)
	_tile(track, border, Vector3(7, 0, 0), 180.0, true, tile, width, false, MeshFactory.DIRT)
	for i in range(5):
		_tile(track, border, Vector3(6 - i, 0, 1), 90.0, false, tile, width, false, MeshFactory.DIRT)
	_tile(track, border, Vector3(0, 0, 1), 90.0, true, tile, width, false, MeshFactory.DIRT)

	_fill_ground_excluding(fill, -10, 14, -12, 8, 1.0, road, nature + "ground_grass.fbx")
	return Vector3(0.5, 0.0, -0.5)


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


static func _fence_racing(border: Node3D, kit: String, tile: float, width: float) -> void:
	var outer := width * 0.5 + 0.2
	var cx := tile * 0.5
	for z in range(0, -11, -int(tile)):
		_place_decal(border, kit, "fenceStraight.glb", Vector3(cx + outer, 0, z), 0.0)
	for x in range(2, 11, int(tile)):
		_place_decal(border, kit, "fenceStraight.glb", Vector3(x, 0, -12 - outer + 0.5), 90.0)
	for z in range(0, -11, -int(tile)):
		_place_decal(border, kit, "fenceStraight.glb", Vector3(11 + outer - 0.5, 0, z), 0.0)
	for x in range(9, -1, -int(tile)):
		_place_decal(border, kit, "fenceStraight.glb", Vector3(x, 0, 2 + outer - 0.5), 90.0)


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
