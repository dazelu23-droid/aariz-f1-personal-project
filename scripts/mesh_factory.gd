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
	with_collision: bool = false,
	piece_scale: Vector3 = Vector3.ONE,
	rotation_x_deg: float = 0.0,
	collision_box_size: Vector3 = Vector3.ZERO
) -> Node3D:
	var piece := create_model(path, texture_path)
	piece.position = position
	piece.rotation_degrees = Vector3(rotation_x_deg, rotation_y_deg, 0.0)
	piece.scale = piece_scale
	piece.position.y = 0.03
	parent.add_child(piece)

	if with_collision:
		if collision_box_size != Vector3.ZERO:
			_add_local_collision_box(piece, collision_box_size)
		else:
			for mesh_node in _find_all_mesh_instances(piece):
				add_static_collision(mesh_node)

	return piece


static func _add_local_collision_box(parent: Node3D, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(collision)
	parent.add_child(body)


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


static func add_collision_box(
	parent: Node3D,
	center: Vector3,
	size: Vector3,
	rotation_y_deg: float = 0.0
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	body.rotation_degrees.y = rotation_y_deg
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body


static func add_merged_road_collision(
	parent: Node3D,
	cells: Dictionary,
	cell_size: float,
	height: float
) -> void:
	if cells.is_empty():
		return
	var body := StaticBody3D.new()
	body.name = "RoadCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	var overlap := maxf(cell_size * 0.1, 0.06)
	var slab_h := height + 0.04
	for key in cells:
		var parts: PackedStringArray = key.split(",")
		var ix := int(parts[0])
		var iz := int(parts[1])
		var center := Vector3(
			(float(ix) + 0.5) * cell_size,
			slab_h * 0.5,
			(float(iz) + 0.5) * cell_size
		)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(cell_size + overlap, slab_h, cell_size + overlap)
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


static func add_finish_line_markers(
	parent: Node3D,
	center: Vector3,
	width: float,
	rotation_y_deg: float = 0.0
) -> void:
	var stripe_count := 10
	var stripe_w := width / float(stripe_count)
	var stripe_depth := 0.65
	for i in range(stripe_count):
		var color := CURB_WHITE if i % 2 == 0 else Color(0.06, 0.06, 0.06)
		var offset := -width * 0.5 + stripe_w * 0.5 + i * stripe_w
		var stripe_center := center + Vector3(offset, 0.0, 0.0)
		_add_colored_box(
			parent,
			stripe_center,
			Vector3(stripe_w * 0.96, 0.06, stripe_depth),
			rotation_y_deg,
			color,
			false
		)

	var post_h := 3.2
	var post_offset := width * 0.5 + 0.45
	var rot_rad := deg_to_rad(rotation_y_deg)
	var perp := Vector3(cos(rot_rad), 0.0, -sin(rot_rad))
	for side in [-1.0, 1.0]:
		var post_center := center + perp * post_offset * side + Vector3(0.0, post_h * 0.5, 0.0)
		_add_colored_box(
			parent,
			post_center,
			Vector3(0.3, post_h, 0.3),
			rotation_y_deg,
			Color(0.92, 0.12, 0.12),
			false
		)
	var banner_center := center + Vector3(0.0, post_h + 0.12, 0.0)
	_add_colored_box(
		parent,
		banner_center,
		Vector3(width + 1.0, 0.28, 0.22),
		rotation_y_deg,
		Color(0.98, 0.82, 0.08),
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
			mesh_instance.set_surface_override_material(i, _polish_material(surface_mat))
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


static func _polish_material(source: Material) -> Material:
	if source is StandardMaterial3D:
		var mat := (source as StandardMaterial3D).duplicate()
		mat.roughness = clampf(mat.roughness * 0.88, 0.38, 0.9)
		mat.metallic = clampf(mat.metallic, 0.0, 0.1)
		mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		return mat
	return source


static func add_multimesh_kit_pieces(parent: Node3D, path: String, instances: Array) -> void:
	if instances.is_empty() or not ResourceLoader.exists(path):
		return
	var asset := _extract_mesh_asset(path)
	var mesh: Mesh = asset.get("mesh")
	if mesh == null:
		return

	var multi := MultiMesh.new()
	multi.mesh = mesh
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.instance_count = instances.size()

	for i in instances.size():
		var inst: Dictionary = instances[i]
		var pos: Vector3 = inst.get("pos", Vector3.ZERO)
		var rot_y: float = inst.get("rot_y", 0.0)
		var scale: Vector3 = inst.get("scale", Vector3.ONE)
		var basis := Basis.IDENTITY.rotated(Vector3.UP, deg_to_rad(rot_y)).scaled(scale)
		multi.set_instance_transform(i, Transform3D(basis, pos + Vector3(0.0, 0.03, 0.0)))

	var renderer := MultiMeshInstance3D.new()
	renderer.name = path.get_file().get_basename()
	renderer.multimesh = multi
	var material: Material = asset.get("material")
	if material:
		renderer.material_override = material
	parent.add_child(renderer)


static func _extract_mesh_asset(path: String) -> Dictionary:
	var resource := load(path)
	if resource == null:
		return {}

	if resource is Mesh:
		return {"mesh": resource, "material": null}

	if resource is PackedScene:
		var temp: Node = (resource as PackedScene).instantiate()
		var mesh_nodes := _find_all_mesh_instances(temp)
		for mesh_node in mesh_nodes:
			if mesh_node.mesh:
				var mesh := mesh_node.mesh
				var mat := mesh_node.get_active_material(0)
				if mat is StandardMaterial3D:
					mat = _polish_material(mat)
				temp.free()
				return {"mesh": mesh, "material": mat}
		temp.free()

	return {}
