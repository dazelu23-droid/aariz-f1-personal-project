class_name GraphicsSetup
extends RefCounted

## Builds a rich WorldEnvironment for each track theme.


static func apply(world_env: WorldEnvironment, theme: String) -> void:
	var env := Environment.new()

	env.background_mode = Environment.BG_SKY
	env.sky = _make_sky(theme)

	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.62 if theme == "racing" else (0.55 if theme == "city" else 0.78)
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.85

	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.12 if theme == "racing" else (1.08 if theme == "city" else 1.02)
	env.tonemap_white = 5.8 if theme == "racing" else 5.5

	env.ssao_enabled = true
	env.ssao_radius = 2.4 if theme == "racing" else 2.0
	env.ssao_intensity = 1.55 if theme == "racing" else 1.35
	env.ssao_power = 1.15 if theme == "racing" else 1.2
	env.ssao_detail = 0.72 if theme == "racing" else 0.65
	env.ssao_horizon = 0.06 if theme == "racing" else 0.08

	env.ssil_enabled = true
	env.ssil_intensity = 0.62 if theme == "racing" else 0.45
	env.ssil_radius = 5.0 if theme == "racing" else 4.0

	env.glow_enabled = true
	env.glow_intensity = 0.55 if theme == "city" else (0.42 if theme == "racing" else 0.35)
	env.glow_strength = 0.85 if theme == "city" else (0.72 if theme == "racing" else 0.65)
	env.glow_bloom = 0.2 if theme == "city" else (0.16 if theme == "racing" else 0.12)
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	env.sdfgi_enabled = false

	env.fog_enabled = true
	env.fog_light_color = _fog_color(theme)
	env.fog_density = _fog_density(theme)
	env.fog_aerial_perspective = 0.62 if theme == "racing" else (0.55 if theme == "city" else 0.38)
	env.fog_sky_affect = 0.82
	env.fog_depth_begin = 45.0 if theme == "racing" else 35.0
	env.fog_depth_end = 320.0 if theme == "racing" else (220.0 if theme == "city" else 280.0)

	world_env.environment = env


static func setup_sun(light: DirectionalLight3D, theme: String) -> void:
	light.shadow_enabled = true
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	light.directional_shadow_max_distance = 420.0
	light.directional_shadow_blend_splits = true
	light.shadow_bias = 0.03
	light.shadow_normal_bias = 1.2
	light.light_energy = 0.95 if theme == "city" else (1.38 if theme == "racing" else 1.28)
	light.light_color = _sun_color(theme)
	light.rotation_degrees = Vector3(-38.0 if theme == "racing" else (-28.0 if theme == "city" else -52.0), _sun_yaw(theme), 0.0)


static func _make_sky(theme: String) -> Sky:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_curve = 0.18
	sky_mat.sky_energy_multiplier = 1.05
	match theme:
		"racing":
			sky_mat.sky_top_color = Color(0.1, 0.34, 0.82)
			sky_mat.sky_horizon_color = Color(0.58, 0.78, 0.92)
			sky_mat.ground_horizon_color = Color(0.32, 0.58, 0.38)
			sky_mat.ground_bottom_color = Color(0.22, 0.46, 0.28)
			sky_mat.sky_energy_multiplier = 1.15
		"city":
			sky_mat.sky_top_color = Color(0.02, 0.04, 0.12)
			sky_mat.sky_horizon_color = Color(0.22, 0.26, 0.34)
			sky_mat.ground_horizon_color = Color(0.22, 0.24, 0.28)
			sky_mat.ground_bottom_color = Color(0.18, 0.2, 0.24)
		"nature":
			sky_mat.sky_top_color = Color(0.2, 0.46, 0.76)
			sky_mat.sky_horizon_color = Color(0.58, 0.76, 0.58)
			sky_mat.ground_horizon_color = Color(0.22, 0.42, 0.26)
			sky_mat.ground_bottom_color = Color(0.16, 0.34, 0.18)
		_:
			sky_mat.sky_top_color = Color(0.2, 0.45, 0.8)
			sky_mat.sky_horizon_color = Color(0.65, 0.8, 0.95)

	var sky := Sky.new()
	sky.sky_material = sky_mat
	return sky


static func _sun_color(theme: String) -> Color:
	match theme:
		"city":
			return Color(1.0, 0.82, 0.62)
		"nature":
			return Color(1.0, 0.95, 0.84)
		_:
			return Color(1.0, 0.98, 0.88)


static func _sun_yaw(theme: String) -> float:
	match theme:
		"city":
			return -38.0
		"nature":
			return 52.0
		_:
			return 28.0


static func _fog_color(theme: String) -> Color:
	match theme:
		"city":
			return Color(0.35, 0.4, 0.55)
		"nature":
			return Color(0.6, 0.76, 0.56)
		_:
			return Color(0.72, 0.86, 0.98)


static func _fog_density(theme: String) -> float:
	match theme:
		"city":
			return 0.0034
		"nature":
			return 0.0028
		_:
			return 0.0022
