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


func _ready() -> void:
	_apply_title()
	hint_label.text = "W/S drive · A/D steer · R checkpoint reset · Esc menu"
	if timer_path != NodePath():
		_timer = get_node(timer_path) as RaceTimer
		if _timer:
			_timer.lap_completed.connect(_on_lap_completed)
	_setup_countdown_overlay()


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
		else:
			hint_label.text = "W/S drive · A/D steer · R checkpoint reset · Esc menu"

	if _timer == null:
		return
	timer_label.text = "Time: %s" % _timer.format_time(_timer.elapsed_time)
	if _timer.lap_count == 0:
		lap_label.text = "Lap: 0  (cross start/finish)"
	else:
		lap_label.text = "Lap: %d  Last: %s" % [_timer.lap_count, _timer.format_time(_timer.last_lap_time)]
	best_label.text = "Best: %s" % _timer.format_best_time()


func _on_lap_completed(lap: int, lap_time: float) -> void:
	lap_label.text = "Lap: %d  Last: %s" % [lap, _timer.format_time(lap_time)]
