extends CanvasLayer

@export var track_name := "Track":
	set(value):
		track_name = value
		_apply_title()

@export var timer_path: NodePath

@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var timer_label: Label = $Panel/Margin/VBox/Timer
@onready var lap_label: Label = $Panel/Margin/VBox/Lap
@onready var best_label: Label = $Panel/Margin/VBox/Best
@onready var hint_label: Label = $Panel/Margin/VBox/Hint

var _timer: RaceTimer
var _countdown_label: Label
var _win_overlay: ColorRect
var _win_panel: PanelContainer


func _ready() -> void:
	_apply_title()
	hint_label.text = "W/S drive · A/D steer · R checkpoint reset · Esc menu"
	if timer_path != NodePath():
		_timer = get_node(timer_path) as RaceTimer
		if _timer:
			_timer.lap_completed.connect(_on_lap_completed)
	_setup_countdown_overlay()
	_setup_win_overlay()


func _setup_countdown_overlay() -> void:
	_countdown_label = Label.new()
	_countdown_label.name = "Countdown"
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_countdown_label.add_theme_font_size_override("font_size", 108)
	_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.2))
	_countdown_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	_countdown_label.add_theme_constant_override("outline_size", 12)
	_countdown_label.visible = false
	add_child(_countdown_label)


func _setup_win_overlay() -> void:
	_win_overlay = ColorRect.new()
	_win_overlay.name = "WinOverlay"
	_win_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_win_overlay.color = Color(0.02, 0.06, 0.02, 0.72)
	_win_overlay.visible = false
	_win_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_win_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_win_overlay.add_child(center)

	_win_panel = PanelContainer.new()
	_win_panel.custom_minimum_size = Vector2(420, 260)
	center.add_child(_win_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_win_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var title := Label.new()
	title.name = "WinTitle"
	title.text = "You Win!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.98, 0.88, 0.2))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "WinSubtitle"
	subtitle.text = "3 laps complete"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	vbox.add_child(subtitle)

	var time_label := Label.new()
	time_label.name = "WinTime"
	time_label.text = "Total time: --:--.--"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(time_label)

	var home_button := Button.new()
	home_button.name = "HomeButton"
	home_button.text = "Return Home"
	home_button.custom_minimum_size = Vector2(220, 44)
	home_button.pressed.connect(_on_return_home_pressed)
	vbox.add_child(home_button)


func show_win_screen(total_time: float) -> void:
	var time_label := _win_panel.get_node("Margin/VBox/WinTime") as Label
	if time_label and _timer:
		time_label.text = "Total time: %s" % _timer.format_time(total_time)
	_win_overlay.visible = true


func _on_return_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/track_select.tscn")


func _apply_title() -> void:
	if is_node_ready() and title_label:
		title_label.text = track_name


func _process(_delta: float) -> void:
	var track := get_tree().current_scene
	if track and track.has_method("get_countdown_text"):
		var countdown_text: String = track.get_countdown_text()
		_countdown_label.visible = countdown_text != ""
		_countdown_label.text = countdown_text
		if countdown_text != "":
			hint_label.text = "Get ready..."
		elif _win_overlay == null or not _win_overlay.visible:
			hint_label.text = "W/S drive · A/D steer · R checkpoint reset · Esc menu"

	if _timer == null:
		return
	timer_label.text = "Time: %s" % _timer.format_time(_timer.elapsed_time)
	if _timer.lap_count == 0:
		lap_label.text = "Lap: 0 / %d  (cross finish line)" % RaceTimer.WIN_LAPS
	else:
		lap_label.text = "Lap: %d / %d  Last: %s" % [
			_timer.lap_count, RaceTimer.WIN_LAPS, _timer.format_time(_timer.last_lap_time)
		]
	best_label.text = "Best: %s" % _timer.format_best_time()


func _on_lap_completed(lap: int, lap_time: float) -> void:
	lap_label.text = "Lap: %d / %d  Last: %s" % [lap, RaceTimer.WIN_LAPS, _timer.format_time(lap_time)]
