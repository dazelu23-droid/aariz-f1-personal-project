class_name GraphicsSetup
extends RefCounted

## Builds a rich WorldEnvironment for each track theme.


static func apply(world_env: WorldEnvironment, theme: String) -> void:
	var env := Environment.new()

	env.background_mode = Environment.BG_SKY
	env.sky = _make_sky(theme)

	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55 if theme == "racing" else 0.7
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.9

	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 1.0

	env.glow_enabled = false

	env.fog_enabled = true
	env.fog_light_color = _fog_color(theme)
	env.fog_density = _fog_density(theme) * (0.12 if theme == "racing" else 0.22)
	env.fog_aerial_perspective = 0.35 if theme == "city" else 0.15

	world_env.environment = env


static func setup_sun(light: DirectionalLight3D, theme: String) -> void:
	light.shadow_enabled = true
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	light.directional_shadow_max_distance = 200.0
	light.light_energy = 1.15
	light.light_color = _sun_color(theme)
	light.rotation_degrees = Vector3(-48.0, _sun_yaw(theme), 0.0)


static func _make_sky(theme: String) -> Sky:
	var sky_mat := ProceduralSkyMaterial.new()
	match theme:
		"racing":
			sky_mat.sky_top_color = Color(0.18, 0.42, 0.82)
			sky_mat.sky_horizon_color = Color(0.62, 0.78, 0.95)
			sky_mat.ground_horizon_color = Color(0.28, 0.5, 0.3)
			sky_mat.ground_bottom_color = Color(0.18, 0.36, 0.2)
		"city":
			sky_mat.sky_top_color = Color(0.08, 0.12, 0.28)
			sky_mat.sky_horizon_color = Color(0.45, 0.52, 0.68)
			sky_mat.ground_horizon_color = Color(0.28, 0.3, 0.34)
			sky_mat.ground_bottom_color = Color(0.1, 0.1, 0.12)
		"nature":
			sky_mat.sky_top_color = Color(0.22, 0.48, 0.78)
			sky_mat.sky_horizon_color = Color(0.72, 0.86, 0.72)
			sky_mat.ground_horizon_color = Color(0.42, 0.55, 0.38)
			sky_mat.ground_bottom_color = Color(0.16, 0.22, 0.14)
		_:
			sky_mat.sky_top_color = Color(0.2, 0.45, 0.8)
			sky_mat.sky_horizon_color = Color(0.65, 0.8, 0.95)

	var sky := Sky.new()
	sky.sky_material = sky_mat
	return sky


static func _sun_color(theme: String) -> Color:
	match theme:
		"city":
			return Color(1.0, 0.92, 0.82)
		"nature":
			return Color(1.0, 0.96, 0.86)
		_:
			return Color(1.0, 0.98, 0.92)


static func _sun_yaw(theme: String) -> float:
	match theme:
		"city":
			return -35.0
		"nature":
			return 55.0
		_:
			return 25.0


static func _fog_color(theme: String) -> Color:
	match theme:
		"city":
			return Color(0.55, 0.6, 0.72)
		"nature":
			return Color(0.62, 0.78, 0.58)
		_:
			return Color(0.7, 0.82, 0.95)


static func _fog_density(theme: String) -> float:
	match theme:
		"city":
			return 0.0025
		"nature":
			return 0.0018
		_:
			return 0.0012
