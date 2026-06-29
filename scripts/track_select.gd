extends Control

const TRACKS := [
	{
		"name": "Racing Circuit",
		"desc": "Official circuit with grandstands and pit lane",
		"scene": "res://scenes/tracks/racing_track.tscn",
		"preview": "res://assets/racing-kit/Models/OBJ format/Textures/checkers.png",
	},
	{
		"name": "City Streets",
		"desc": "Downtown roads between skyscrapers",
		"scene": "res://scenes/tracks/city_track.tscn",
		"preview": "res://assets/city-kit-roads/Models/OBJ format/Textures/colormap.png",
	},
	{
		"name": "Forest Trail",
		"desc": "Dirt paths through trees and rocks",
		"scene": "res://scenes/tracks/nature_track.tscn",
		"preview": "res://assets/city-kit-commercial/Models/OBJ format/Textures/colormap.png",
	},
]

var _car_buttons: Array[Button] = []


func _ready() -> void:
	_build_car_cards()
	_build_cards()


func _build_car_cards() -> void:
	var grid := $Center/Panel/Margin/VBox/CarGrid
	for child in grid.get_children():
		child.queue_free()
	_car_buttons.clear()

	for i in GameSettings.CARS.size():
		var car: Dictionary = GameSettings.CARS[i]
		var card := _make_car_card(car, i)
		grid.add_child(card)


func _make_car_card(car: Dictionary, index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(0, 72)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(car.preview):
		preview.texture = load(car.preview)
	vbox.add_child(preview)

	var label := Label.new()
	label.text = car.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(label)

	var button := Button.new()
	button.text = "Select" if index != GameSettings.selected_car_index else "Selected"
	button.toggle_mode = true
	button.button_pressed = index == GameSettings.selected_car_index
	button.pressed.connect(_on_car_pressed.bind(index))
	_car_buttons.append(button)
	vbox.add_child(button)

	return panel


func _on_car_pressed(index: int) -> void:
	GameSettings.set_selected_car(index)
	for i in _car_buttons.size():
		var btn: Button = _car_buttons[i]
		btn.button_pressed = i == index
		btn.text = "Selected" if i == index else "Select"


func _build_cards() -> void:
	var grid := $Center/Panel/Margin/VBox/TrackGrid
	for child in grid.get_children():
		child.queue_free()

	for track in TRACKS:
		var card := _make_card(track)
		grid.add_child(card)


func _make_card(track: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(0, 96)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(track.preview):
		preview.texture = load(track.preview)
	vbox.add_child(preview)

	var title := Label.new()
	title.text = track.name
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = track.desc
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9))
	vbox.add_child(desc)

	var button := Button.new()
	button.text = "Race"
	button.pressed.connect(_on_track_pressed.bind(track.scene))
	vbox.add_child(button)

	return panel


func _on_track_pressed(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
