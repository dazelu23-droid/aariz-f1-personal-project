extends Node

## Persists player choices between the menu and track scenes.

const CARS := [
	{
		"name": "Classic Racer",
		"body": "res://assets/car-kit/Models/OBJ format/race.obj",
		"preview": "res://assets/racing-kit/Side/raceCarRed.png",
		"integrated": false,
		"wheel_scale": 0.42,
	},
	{
		"name": "Future Racer",
		"body": "res://assets/car-kit/Models/OBJ format/race-future.obj",
		"preview": "res://assets/racing-kit/Side/raceCarWhite.png",
		"integrated": false,
		"wheel_scale": 0.42,
	},
	{
		"name": "Sports Sedan",
		"body": "res://assets/car-kit/Models/OBJ format/sedan-sports.obj",
		"preview": "res://assets/city-kit-commercial/Models/OBJ format/Textures/colormap.png",
		"integrated": false,
		"wheel_scale": 0.4,
	},
	{
		"name": "Red F1",
		"body": "res://assets/racing-kit/Models/GLTF format/raceCarRed.glb",
		"preview": "res://assets/racing-kit/Side/raceCarRed.png",
		"integrated": true,
		"scale": 0.55,
	},
	{
		"name": "Orange F1",
		"body": "res://assets/racing-kit/Models/GLTF format/raceCarOrange.glb",
		"preview": "res://assets/racing-kit/Side/raceCarOrange.png",
		"integrated": true,
		"scale": 0.55,
	},
	{
		"name": "Green F1",
		"body": "res://assets/racing-kit/Models/GLTF format/raceCarGreen.glb",
		"preview": "res://assets/racing-kit/Side/raceCarGreen.png",
		"integrated": true,
		"scale": 0.55,
	},
]

const WHEEL_MESH := "res://assets/car-kit/Models/OBJ format/wheel-racing.obj"
const WHEEL_OFFSETS := [
	Vector3(-0.62, 0.18, 0.85),
	Vector3(0.62, 0.18, 0.85),
	Vector3(-0.62, 0.18, -0.85),
	Vector3(0.62, 0.18, -0.85),
]

var selected_car_index: int = 0


func get_selected_car() -> Dictionary:
	return CARS[clampi(selected_car_index, 0, CARS.size() - 1)]


func set_selected_car(index: int) -> void:
	selected_car_index = clampi(index, 0, CARS.size() - 1)
