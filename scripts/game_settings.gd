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
		"name": "Hot Hatch",
		"body": "res://assets/car-kit/Models/OBJ format/hatchback-sports.obj",
		"preview": "res://assets/city-kit-commercial/Models/OBJ format/Textures/colormap.png",
		"integrated": false,
		"wheel_scale": 0.38,
	},
	{
		"name": "Rally Kart",
		"body": "res://assets/car-kit/Models/OBJ format/kart-oodi.obj",
		"preview": "res://assets/racing-kit/Side/raceCarOrange.png",
		"integrated": false,
		"wheel_scale": 0.35,
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
	{
		"name": "White F1",
		"body": "res://assets/racing-kit/Models/GLTF format/raceCarWhite.glb",
		"preview": "res://assets/racing-kit/Side/raceCarWhite.png",
		"integrated": true,
		"scale": 0.55,
	},
	{
		"name": "Space Racer",
		"body": "res://assets/space-kit/Models/OBJ format/craft_racer.obj",
		"preview": "res://assets/racing-kit/Side/raceCarWhite.png",
		"integrated": false,
		"wheel_scale": 0.4,
	},
]

const AI_DIFFICULTIES := [
	{"name": "1 - Easy", "speed_mult": 0.38, "accel_mult": 0.42, "steer_mult": 0.48, "lookahead": 3.5, "steer_error": 0.42, "corner_caution": 0.85},
	{"name": "2 - Novice", "speed_mult": 0.46, "accel_mult": 0.5, "steer_mult": 0.56, "lookahead": 4.5, "steer_error": 0.34, "corner_caution": 0.78},
	{"name": "3 - Casual", "speed_mult": 0.54, "accel_mult": 0.58, "steer_mult": 0.64, "lookahead": 5.5, "steer_error": 0.28, "corner_caution": 0.7},
	{"name": "4 - Intermediate", "speed_mult": 0.62, "accel_mult": 0.66, "steer_mult": 0.72, "lookahead": 6.5, "steer_error": 0.22, "corner_caution": 0.62},
	{"name": "5 - Skilled", "speed_mult": 0.72, "accel_mult": 0.76, "steer_mult": 0.82, "lookahead": 7.5, "steer_error": 0.16, "corner_caution": 0.55},
	{"name": "6 - Advanced", "speed_mult": 0.82, "accel_mult": 0.86, "steer_mult": 0.92, "lookahead": 8.5, "steer_error": 0.12, "corner_caution": 0.48},
	{"name": "7 - Expert", "speed_mult": 0.92, "accel_mult": 0.96, "steer_mult": 1.02, "lookahead": 9.5, "steer_error": 0.08, "corner_caution": 0.4},
	{"name": "8 - Master", "speed_mult": 1.02, "accel_mult": 1.06, "steer_mult": 1.1, "lookahead": 10.5, "steer_error": 0.05, "corner_caution": 0.32},
	{"name": "9 - Legend", "speed_mult": 1.12, "accel_mult": 1.16, "steer_mult": 1.2, "lookahead": 12.0, "steer_error": 0.03, "corner_caution": 0.22},
	{"name": "10 - Unbeatable", "speed_mult": 1.28, "accel_mult": 1.32, "steer_mult": 1.35, "lookahead": 14.0, "steer_error": 0.01, "corner_caution": 0.12},
]

const WHEEL_MESH := "res://assets/car-kit/Models/OBJ format/wheel-racing.obj"
const WHEEL_OFFSETS := [
	Vector3(-0.62, 0.18, 0.85),
	Vector3(0.62, 0.18, 0.85),
	Vector3(-0.62, 0.18, -0.85),
	Vector3(0.62, 0.18, -0.85),
]

var selected_car_index: int = 0
var selected_ai_difficulty: int = 4
var ai_opponent_count: int = 5


func get_selected_car() -> Dictionary:
	return CARS[clampi(selected_car_index, 0, CARS.size() - 1)]


func get_car(index: int) -> Dictionary:
	return CARS[clampi(index, 0, CARS.size() - 1)]


func set_selected_car(index: int) -> void:
	selected_car_index = clampi(index, 0, CARS.size() - 1)


func set_ai_difficulty(index: int) -> void:
	selected_ai_difficulty = clampi(index, 0, AI_DIFFICULTIES.size() - 1)


func get_ai_difficulty_profile() -> Dictionary:
	return AI_DIFFICULTIES[clampi(selected_ai_difficulty, 0, AI_DIFFICULTIES.size() - 1)]


func random_car_index(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(0, CARS.size() - 1)
