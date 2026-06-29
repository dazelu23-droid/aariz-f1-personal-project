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

var _timer


func _ready() -> void:
	_apply_title()
	hint_label.text = "W/S drive · A/D steer · R reset · Esc menu"
	if timer_path != NodePath():
		_timer = get_node(timer_path)
		if _timer:
			_timer.lap_completed.connect(_on_lap_completed)


func _apply_title() -> void:
	if is_node_ready() and title_label:
		title_label.text = track_name


func _process(_delta: float) -> void:
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
