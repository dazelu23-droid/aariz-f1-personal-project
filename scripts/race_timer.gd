class_name RaceTimer
extends Node

signal lap_completed(lap_number: int, lap_time: float)
signal race_won(total_time: float)

const WIN_LAPS := 3

var elapsed_time := 0.0
var lap_count := 0
var best_lap_time := -1.0
var last_lap_time := 0.0
var _current_lap_start := 0.0
var _armed := false
var _cooldown := 0.0
var _won := false


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if _armed:
		elapsed_time += delta


func arm() -> void:
	_armed = true
	_won = false
	elapsed_time = 0.0
	_current_lap_start = 0.0
	lap_count = 0
	best_lap_time = -1.0
	last_lap_time = 0.0
	_cooldown = 4.0


func has_won() -> bool:
	return _won


func on_finish_line_crossed() -> void:
	if not _armed or _cooldown > 0.0 or _won:
		return

	_cooldown = 2.0
	last_lap_time = elapsed_time - _current_lap_start
	if last_lap_time < 3.0:
		return

	lap_count += 1
	if best_lap_time < 0.0 or last_lap_time < best_lap_time:
		best_lap_time = last_lap_time
	_current_lap_start = elapsed_time
	lap_completed.emit(lap_count, last_lap_time)
	if lap_count >= WIN_LAPS:
		_won = true
		_armed = false
		race_won.emit(elapsed_time)


func format_time(seconds: float) -> String:
	if seconds < 0.0:
		return "--:--.--"
	var mins := int(seconds) / 60
	var secs := fmod(seconds, 60.0)
	return "%d:%05.2f" % [mins, secs]


func format_best_time() -> String:
	if best_lap_time < 0.0:
		return "--:--.--"
	return format_time(best_lap_time)
