extends Node3D


func _ready() -> void:
	rotation_degrees.y = 180.0
	var owner_car := get_parent() as RigidBody3D
	var car_index := -1
	if owner_car and owner_car.get("car_visual_index") != null:
		car_index = owner_car.car_visual_index
	var car: Dictionary = GameSettings.get_car(car_index) if car_index >= 0 else GameSettings.get_selected_car()
	var body_path: String = car.body
	var body := MeshFactory.create_model(body_path, "")
	var scale_factor: float = car.get("scale", 1.0)
	body.scale = Vector3(scale_factor, scale_factor, scale_factor)
	add_child(body)

	if car.get("integrated", false):
		return

	var wheel_path: String = GameSettings.WHEEL_MESH
	var wheel_scale: float = car.get("wheel_scale", 0.42)
	for offset in GameSettings.WHEEL_OFFSETS:
		var wheel := MeshFactory.create_model(wheel_path, "")
		wheel.position = offset
		wheel.scale = Vector3(wheel_scale, wheel_scale, wheel_scale)
		add_child(wheel)
