extends Node3D

const CAR_MESH := "res://assets/car-kit/Models/OBJ format/race.obj"
const WHEEL_MESH := "res://assets/car-kit/Models/OBJ format/wheel-racing.obj"

const WHEEL_OFFSETS := [
	Vector3(-0.62, 0.18, 0.85),
	Vector3(0.62, 0.18, 0.85),
	Vector3(-0.62, 0.18, -0.85),
	Vector3(0.62, 0.18, -0.85),
]


func _ready() -> void:
	rotation_degrees.y = 180.0
	var body := MeshFactory.create_model(CAR_MESH, "")
	add_child(body)

	for offset in WHEEL_OFFSETS:
		var wheel := MeshFactory.create_model(WHEEL_MESH, "")
		wheel.position = offset
		wheel.scale = Vector3(0.42, 0.42, 0.42)
		add_child(wheel)
