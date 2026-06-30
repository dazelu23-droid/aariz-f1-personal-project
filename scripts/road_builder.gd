class_name RoadBuilder
extends RefCounted

const SLAB_H := 0.14
const KIT_TILE := 1.0
const RACING_TRACK_WIDTH := 5.5
const CURB_H := 0.076
const CURB_W := 0.14

static var _placed_road_aabbs: Array = []
static var _placed_kit_cells: Dictionary = {}
static var _collision_cells: Dictionary = {}
static var _collision_cell_size: float = 0.55


static func _reset_road_overlap_tracker() -> void:
	_placed_road_aabbs.clear()
	_placed_kit_cells.clear()
	_collision_cells.clear()


static func _begin_road_build(tile: float) -> void:
	_reset_road_overlap_tracker()
	_collision_cell_size = clampf(tile * 0.42, 0.48, 0.62)


static func build_racing_circuit(
	track: Node3D,
	border: Node3D,
	fill: Node3D,
	kit: String
) -> Vector3:
	var tile := 2.0
	_begin_road_build(KIT_TILE if kit != "" else tile)
	var width := RACING_TRACK_WIDTH
	var waypoints: Array = _chamfer_waypoints(_racing_circuit_waypoints(), 5.0)
	var layout: Dictionary = _build_waypoint_circuit(
		track, border, waypoints, tile, width, true, MeshFactory.ASPHALT, kit
	)
	MeshFactory.add_start_finish_line(
		track, waypoints[0] + Vector3(0.5, SLAB_H + 0.02, -1.6), width
	)
	_place_path_guides(track, layout, kit)
	var road: Dictionary = layout["bounds"]
	_fill_ground_excluding(
		fill,
		road.min_x - 40,
		road.max_x + 40,
		road.min_z - 40,
		road.max_z + 40,
		1.0,
		road,
		kit + "grass.glb",
		Color(-1, -1, -1),
		-0.16 if kit != "" else -0.03
	)
	return waypoints[0] + Vector3(0.5, 0.0, -2.0)


static func _racing_circuit_waypoints() -> Array:
	# ~560 local units — about a 60 s lap at world scale 5 with average race speed.
	return [
		Vector3(0, 0, 0),
		Vector3(0, 0, -72),
		Vector3(140, 0, -72),
		Vector3(140, 0, 72),
		Vector3(0, 0, 72),
		Vector3(0, 0, 0),
	]


static func get_racing_layout() -> Dictionary:
	var tile := 2.0
	var waypoints: Array = _chamfer_waypoints(_racing_circuit_waypoints(), 5.0)
	var layout := _preview_waypoint_layout(waypoints, tile * 0.5)
	layout["tile"] = tile
	layout["width"] = RACING_TRACK_WIDTH
	layout["waypoints"] = waypoints
	return layout


static func build_city_circuit(
	track: Node3D,
	border: Node3D,
	fill: Node3D,
	kit: String
) -> Vector3:
	var tile := 2.0
	_begin_road_build(KIT_TILE if kit != "" else tile)
	var width := 3.2
	var waypoints: Array = _chamfer_waypoints(_city_street_waypoints(), 2.2)
	var layout: Dictionary = _build_waypoint_circuit(
		track, border, waypoints, tile, width, true, MeshFactory.ASPHALT, kit
	)
	_place_path_guides(track, layout, kit)
	MeshFactory.add_start_finish_line(
		track, waypoints[0] + Vector3(0.5, SLAB_H + 0.02, -1.6), width
	)
	_fill_ground_excluding(
		fill,
		layout.bounds.min_x - 36,
		layout.bounds.max_x + 36,
		layout.bounds.min_z - 36,
		layout.bounds.max_z + 36,
		2.0,
		layout.bounds,
		"",
		MeshFactory.CONCRETE
	)
	return waypoints[0] + Vector3(0.5, 0.0, -2.0)


static func get_city_layout() -> Dictionary:
	var layout := _preview_waypoint_layout(_chamfer_waypoints(_city_street_waypoints(), 2.2), 2.0)
	layout["width"] = 3.2
	return layout


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
	var start_anchor: Vector3 = waypoints[0]
	var place_tile := KIT_TILE if kit != "" else tile

	for seg_idx in range(waypoints.size() - 1):
		var a: Vector3 = waypoints[seg_idx]
		var b: Vector3 = waypoints[seg_idx + 1]
		var delta := b - a
		var seg_len := delta.length()
		if seg_len < 0.05:
			continue
		var dir := delta / seg_len
		var rot := _direction_to_rot(dir)
		var next_rot := rot
		if seg_idx < waypoints.size() - 2:
			var nb: Vector3 = waypoints[seg_idx + 2]
			var nd := nb - b
			if nd.length_squared() > 0.01:
				next_rot = _direction_to_rot(nd.normalized())
		var steps := maxi(1, int(round(seg_len / place_tile)))
		for step in range(steps):
			var t0 := float(step) / float(steps)
			var t1 := float(step + 1) / float(steps)
			var anchor := a + dir * (seg_len * t0)
			var center := a.lerp(b, (t0 + t1) * 0.5)
			var is_corner := step == steps - 1 and rot != next_rot
			_tile(
				track, border, anchor, rot, is_corner, tile, width, use_curbs, surface, kit, start_anchor, place_tile
			)
			samples.append(center)
		samples.append(b)

	var layout := _layout_from_samples(samples, tile)
	_finish_road_collision(track)
	return layout


static func _place_path_guides(
	track: Node3D,
	layout: Dictionary,
	kit: String,
	line_color: Color = MeshFactory.LINE_WHITE
) -> void:
	var samples: Array = layout.get("samples", [])
	if samples.size() < 2:
		return
	var marker_idx := 0
	for i in range(0, samples.size() - 1, 2):
		var a: Vector3 = samples[i]
		var b: Vector3 = samples[i + 1]
		if a.distance_squared_to(b) < 0.02:
			continue
		var dir := (b - a).normalized()
		var rot := _direction_to_rot(dir)
		var p := a.lerp(b, 0.5)
		if kit == "":
			MeshFactory.add_visual_marker(
				track,
				p + Vector3(0.0, SLAB_H + 0.018, 0.0),
				Vector3(0.12, 0.02, 0.55),
				rot,
				line_color
			)
		marker_idx += 1


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
	_begin_road_build(tile)
	var width := 2.6
	var waypoints: Array = _chamfer_waypoints(_nature_trail_waypoints(), 1.6)
	var layout: Dictionary = _build_waypoint_circuit(
		track, border, waypoints, tile, width, false, MeshFactory.DIRT, ""
	)
	_fill_ground_excluding(
		fill,
		layout.bounds.min_x - 28,
		layout.bounds.max_x + 28,
		layout.bounds.min_z - 28,
		layout.bounds.max_z + 28,
		1.0,
		layout.bounds,
		nature + "ground_grass.fbx"
	)
	return waypoints[0] + Vector3(0.5, 0.0, -0.5)


static func get_nature_layout() -> Dictionary:
	var layout: Dictionary = _preview_waypoint_layout(_chamfer_waypoints(_nature_trail_waypoints(), 1.6), 1.25)
	layout["width"] = 2.6
	return layout


static func _chamfer_waypoints(points: Array, radius: float) -> Array:
	if points.size() < 3:
		return points.duplicate()
	var out: Array = []
	for i in range(points.size() - 1):
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		if i == 0:
			out.append(a)
		if i >= points.size() - 2:
			out.append(b)
			continue
		var c: Vector3 = points[i + 2]
		var v1 := (b - a).normalized()
		var v2 := (c - b).normalized()
		if absf(v1.dot(v2)) > 0.92:
			out.append(b)
			continue
		var r := minf(radius, minf(a.distance_to(b) * 0.42, b.distance_to(c) * 0.42))
		out.append(b - v1 * r)
		for step in range(1, 4):
			var t := float(step) / 4.0
			var p1 := b - v1 * r
			var p2 := b + v2 * r
			out.append(p1.lerp(p2, t).lerp(b, 1.0 - absf(t - 0.5) * 1.6))
		out.append(b + v2 * r)
	return out


static func _tile(
	track: Node3D,
	border: Node3D,
	anchor: Vector3,
	rotation_y_deg: float,
	is_corner: bool,
	tile: float,
	width: float,
	f1_curbs: bool,
	surface_color: Color = MeshFactory.ASPHALT,
	kit: String = "",
	start_anchor: Vector3 = Vector3.ZERO,
	place_tile: float = -1.0
) -> void:
	if place_tile < 0.0:
		place_tile = KIT_TILE if kit != "" else tile
	var spec := _slab_spec(anchor, rotation_y_deg, is_corner, place_tile, width)
	var covered := _road_already_covered(spec, rotation_y_deg)
	if kit != "":
		MeshFactory.add_surface_slab(
			track, spec.center, spec.size, rotation_y_deg, surface_color, false
		)
		if not _kit_already_placed(anchor):
			var piece := "roadStraight.glb"
			if anchor.distance_squared_to(start_anchor) < 0.05:
				piece = "roadStart.glb"
			_place_kit_road(
				track, kit, piece, anchor, rotation_y_deg, false, _road_piece_scale(rotation_y_deg, width)
			)
			_register_kit_cell(anchor)
	else:
		MeshFactory.add_surface_slab(
			track, spec.center, spec.size, rotation_y_deg, surface_color, false
		)
	_stamp_spec_to_collision_grid(spec, rotation_y_deg)
	if not covered:
		_register_road_aabb(spec, rotation_y_deg)
	if f1_curbs and kit == "":
		MeshFactory.add_track_line(track, spec.line_center, spec.line_size, rotation_y_deg)


static func _aabb_from_spec(spec: Dictionary, rot_y: float) -> Dictionary:
	var size: Vector3 = spec.size
	var center: Vector3 = spec.center
	var half_x := size.x * 0.5
	var half_z := size.z * 0.5
	var norm := int(rot_y) % 360
	if norm < 0:
		norm += 360
	if norm == 90 or norm == 270:
		half_x = size.z * 0.5
		half_z = size.x * 0.5
	return {
		"min_x": center.x - half_x,
		"max_x": center.x + half_x,
		"min_z": center.z - half_z,
		"max_z": center.z + half_z,
	}


static func _aabb_overlaps(a: Dictionary, b: Dictionary, margin: float = 0.12) -> bool:
	return (
		a.min_x < b.max_x - margin
		and a.max_x > b.min_x + margin
		and a.min_z < b.max_z - margin
		and a.max_z > b.min_z + margin
	)


static func _road_already_covered(spec: Dictionary, rot_y: float) -> bool:
	var aabb := _aabb_from_spec(spec, rot_y)
	for existing in _placed_road_aabbs:
		if _aabb_overlaps(aabb, existing):
			return true
	return false


static func _kit_cell_key(anchor: Vector3) -> String:
	return "%d,%d" % [int(round(anchor.x / KIT_TILE)), int(round(anchor.z / KIT_TILE))]


static func _kit_already_placed(anchor: Vector3) -> bool:
	return _placed_kit_cells.has(_kit_cell_key(anchor))


static func _register_kit_cell(anchor: Vector3) -> void:
	_placed_kit_cells[_kit_cell_key(anchor)] = true


static func _register_road_aabb(spec: Dictionary, rot_y: float) -> void:
	_placed_road_aabbs.append(_aabb_from_spec(spec, rot_y))


static func _stamp_spec_to_collision_grid(spec: Dictionary, rot_y: float) -> void:
	var size: Vector3 = spec.size
	var center: Vector3 = spec.center
	var half_x := size.x * 0.5 + 0.06
	var half_z := size.z * 0.5 + 0.06
	var aabb := _aabb_from_spec(spec, rot_y)
	var cs := _collision_cell_size
	var min_ix := int(floor(aabb.min_x / cs))
	var max_ix := int(floor(aabb.max_x / cs))
	var min_iz := int(floor(aabb.min_z / cs))
	var max_iz := int(floor(aabb.max_z / cs))
	var rot_rad := deg_to_rad(-rot_y)
	for ix in range(min_ix, max_ix + 1):
		for iz in range(min_iz, max_iz + 1):
			var px := (float(ix) + 0.5) * cs
			var pz := (float(iz) + 0.5) * cs
			var local := Vector3(px - center.x, 0.0, pz - center.z).rotated(Vector3.UP, rot_rad)
			if absf(local.x) <= half_x and absf(local.z) <= half_z:
				_collision_cells["%d,%d" % [ix, iz]] = true


static func _finish_road_collision(track: Node3D) -> void:
	if _collision_cells.is_empty():
		return
	MeshFactory.add_merged_road_collision(track, _collision_cells, _collision_cell_size, SLAB_H)
	_collision_cells.clear()


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
				"size": Vector3(width, SLAB_H, tile + 0.16),
				"line_center": anchor + Vector3(0.5, SLAB_H + 0.015, -1.0),
				"line_size": Vector3(0.1, 0.02, tile),
			}
		270:
			return {
				"center": anchor + Vector3(1.0, SLAB_H * 0.5, -0.5),
				"size": Vector3(tile + 0.16, SLAB_H, width),
				"line_center": anchor + Vector3(1.0, SLAB_H + 0.015, -0.5),
				"line_size": Vector3(tile, 0.02, 0.1),
			}
		180:
			return {
				"center": anchor + Vector3(0.5, SLAB_H * 0.5, 1.0),
				"size": Vector3(width, SLAB_H, tile + 0.16),
				"line_center": anchor + Vector3(0.5, SLAB_H + 0.015, 1.0),
				"line_size": Vector3(0.1, 0.02, tile),
			}
		_:
			return {
				"center": anchor + Vector3(-1.0, SLAB_H * 0.5, -0.5),
				"size": Vector3(tile + 0.16, SLAB_H, width),
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
				"size": Vector3(width, SLAB_H, tile + 0.12),
				"line_center": anchor + Vector3(0.5, SLAB_H + 0.015, -0.5),
				"line_size": Vector3(0.08, 0.02, tile),
			}
		270:
			return {
				"center": anchor + Vector3(0.5, SLAB_H * 0.5, -0.5),
				"size": Vector3(tile + 0.12, SLAB_H, width),
				"line_center": anchor + Vector3(0.5, SLAB_H + 0.015, -0.5),
				"line_size": Vector3(tile, 0.02, 0.08),
			}
		180:
			return {
				"center": anchor + Vector3(0.5, SLAB_H * 0.5, 0.5),
				"size": Vector3(width, SLAB_H, tile + 0.12),
				"line_center": anchor + Vector3(0.5, SLAB_H + 0.015, 0.5),
				"line_size": Vector3(0.08, 0.02, tile),
			}
		_:
			return {
				"center": anchor + Vector3(-0.5, SLAB_H * 0.5, -0.5),
				"size": Vector3(tile + 0.12, SLAB_H, width),
				"line_center": anchor + Vector3(-0.5, SLAB_H + 0.015, -0.5),
				"line_size": Vector3(tile, 0.02, 0.08),
			}


static func _fill_ground_excluding(
	fill: Node3D,
	min_x: float,
	max_x: float,
	min_z: float,
	max_z: float,
	step: float,
	road: Dictionary,
	asset: String = "",
	flat_color: Color = Color(-1, -1, -1),
	fill_y: float = -0.03
) -> void:
	var x := min_x
	while x <= max_x:
		var z := min_z
		while z <= max_z:
			var pos := Vector3(x, fill_y, z)
			if not _on_road(pos, road):
				if flat_color.r >= 0.0:
					MeshFactory.add_surface_slab(
						fill, pos + Vector3(0, -0.02, 0), Vector3(step, 0.08, step), 0.0, flat_color, false
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


static func _road_piece_scale(rotation_y_deg: float, width: float) -> Vector3:
	var norm := int(rotation_y_deg) % 360
	if norm < 0:
		norm += 360
	if norm == 0 or norm == 180:
		return Vector3(width, 1.0, 1.0)
	return Vector3(1.0, 1.0, width)


static func _place_kit_road(
	track: Node3D,
	folder: String,
	file: String,
	pos: Vector3,
	rot: float,
	with_collision: bool = false,
	piece_scale: Vector3 = Vector3.ONE
) -> void:
	var path := folder + file
	if ResourceLoader.exists(path):
		MeshFactory.place_piece(track, path, "", pos, rot, with_collision, piece_scale)


static func _place_decal(track: Node3D, folder: String, file: String, pos: Vector3, rot: float) -> void:
	_place_kit_road(track, folder, file, pos, rot, false)
