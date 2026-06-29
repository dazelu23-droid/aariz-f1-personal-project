class_name MeshFactory
extends RefCounted

const ASPHALT := Color(0.16, 0.16, 0.18)
const CONCRETE := Color(0.42, 0.42, 0.44)
const DIRT := Color(0.45, 0.34, 0.22)
const CURB_WHITE := Color(0.92, 0.94, 0.96)
const CURB_RED := Color(0.82, 0.14, 0.12)
const LINE_WHITE := Color(0.95, 0.95, 0.95)


static func create_model(path: String, texture_path: String = "") -> Node3D:
	var resource := load(path)
	if resource == null:
		push_warning("MeshFactory: failed to load %s" % path)
		return Node3D.new()

	if resource is PackedScene:
		return (resource as PackedScene).instantiate()

	var root := Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	var mesh := resource as Mesh
	mesh_instance.mesh = mesh
	_apply_mesh_materials(mesh_instance, mesh, texture_path)
	root.add_child(mesh_instance)
	return root


static func add_static_collision(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.mesh == null:
		return
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.shape = mesh_instance.mesh.create_trimesh_shape()
	body.add_child(collision)
	mesh_instance.add_child(body)


static func place_piece(
	parent: Node3D,
	path: String,
	texture_path: String,
	position: Vector3,
	rotation_y_deg: float = 0.0,
	with_collision: bool = true,
	piece_scale: Vector3 = Vector3.ONE
) -> Node3D:
	var piece := create_model(path, texture_path)
	piece.position = position
	piece.rotation_degrees.y = rotation_y_deg
	piece.scale = piece_scale
	piece.position.y = 0.03
	parent.add_child(piece)

	if with_collision:
		for mesh_node in _find_all_mesh_instances(piece):
			add_static_collision(mesh_node)

	return piece


static func add_ground(parent: Node3D, color: Color, size: float, height: float = 0.4) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector3.ZERO

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size, height, size)
	mesh_instance.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	mesh_instance.material_override = mat
	mesh_instance.position.y = -height * 0.5
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size, height, size)
	collision.shape = shape
	collision.position.y = -height * 0.5
	body.add_child(collision)

	parent.add_child(body)
	return body


static func add_horizon_skirt(parent: Node3D, color: Color, ground_size: float) -> void:
	var skirt_h := 72.0
	var skirt_thick := 48.0
	var half := ground_size * 0.5
	var y := skirt_h * 0.5 - 8.0
	var edges := [
		{"center": Vector3(0.0, y, -half - skirt_thick * 0.5), "size": Vector3(ground_size + skirt_thick * 2.0, skirt_h, skirt_thick)},
		{"center": Vector3(0.0, y, half + skirt_thick * 0.5), "size": Vector3(ground_size + skirt_thick * 2.0, skirt_h, skirt_thick)},
		{"center": Vector3(-half - skirt_thick * 0.5, y, 0.0), "size": Vector3(skirt_thick, skirt_h, ground_size)},
		{"center": Vector3(half + skirt_thick * 0.5, y, 0.0), "size": Vector3(skirt_thick, skirt_h, ground_size)},
	]
	for edge in edges:
		_add_colored_box(parent, edge.center, edge.size, 0.0, color, false)


static func add_visual_marker(
	parent: Node3D,
	center: Vector3,
	size: Vector3,
	rotation_y_deg: float,
	color: Color
) -> void:
	_add_colored_box(parent, center, size, rotation_y_deg, color, false)


static func add_asphalt_slab(
	parent: Node3D,
	center: Vector3,
	size: Vector3,
	rotation_y_deg: float = 0.0
) -> StaticBody3D:
	return add_surface_slab(parent, center, size, rotation_y_deg, ASPHALT)


static func add_surface_slab(
	parent: Node3D,
	center: Vector3,
	size: Vector3,
	rotation_y_deg: float,
	color: Color,
	with_collision: bool = true
) -> StaticBody3D:
	return _add_colored_box(parent, center, size, rotation_y_deg, color, with_collision)


static func add_curb(
	parent: Node3D,
	center: Vector3,
	size: Vector3,
	rotation_y_deg: float,
	color: Color,
	with_collision: bool = false
) -> StaticBody3D:
	return _add_colored_box(parent, center, size, rotation_y_deg, color, with_collision)


static func add_merged_road_collision(
	parent: Node3D,
	cells: Dictionary,
	cell_size: float,
	height: float
) -> void:
	if cells.is_empty():
		return
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var overlap := 0.04
	for key in cells:
		var parts: PackedStringArray = key.split(",")
		var ix := int(parts[0])
		var iz := int(parts[1])
		var center := Vector3(
			(float(ix) + 0.5) * cell_size,
			height * 0.5,
			(float(iz) + 0.5) * cell_size
		)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(cell_size + overlap, height, cell_size + overlap)
		collision.shape = shape
		collision.position = center
		body.add_child(collision)
	parent.add_child(body)


static func add_track_line(
	parent: Node3D,
	center: Vector3,
	size: Vector3,
	rotation_y_deg: float = 0.0
) -> void:
	_add_colored_box(parent, center, size, rotation_y_deg, LINE_WHITE, false)


static func add_start_finish_line(parent: Node3D, center: Vector3, width: float) -> void:
	var stripe_w := width / 8.0
	for i in range(8):
		var color := CURB_WHITE if i % 2 == 0 else Color(0.08, 0.08, 0.08)
		var offset := -width * 0.5 + stripe_w * 0.5 + i * stripe_w
		_add_colored_box(
			parent,
			center + Vector3(offset, 0.0, 0.0),
			Vector3(stripe_w * 0.95, 0.02, 0.35),
			0.0,
			color,
			false
		)


static func _add_colored_box(
	parent: Node3D,
	center: Vector3,
	size: Vector3,
	rotation_y_deg: float,
	color: Color,
	with_collision: bool
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1 if with_collision else 0
	body.collision_mask = 0
	body.position = center
	body.rotation_degrees.y = rotation_y_deg

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	mat.metallic = 0.04
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)

	if with_collision:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)

	parent.add_child(body)
	return body


static func _apply_mesh_materials(
	mesh_instance: MeshInstance3D,
	mesh: Mesh,
	texture_path: String
) -> void:
	var has_surface_material := false
	for i in mesh.get_surface_count():
		var surface_mat := mesh.surface_get_material(i)
		if surface_mat:
			mesh_instance.set_surface_override_material(i, surface_mat)
			has_surface_material = true

	if not has_surface_material and texture_path != "" and ResourceLoader.exists(texture_path):
		var fallback := _make_material(texture_path)
		for i in mesh.get_surface_count():
			mesh_instance.set_surface_override_material(i, fallback)


static func _find_all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var results: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		results.append(node)
	for child in node.get_children():
		results.append_array(_find_all_mesh_instances(child))
	return results


static func _make_material(texture_path: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.72
	mat.metallic = 0.08
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.albedo_texture = load(texture_path)
	return mat
