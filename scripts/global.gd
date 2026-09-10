extends Node
## Cozy Sokoban — 全局游戏管理器（Autoload 单例）
## v2：标题页入口 + 最少步数记录 + 解锁进度

signal level_started(index: int)

var current_level: int = -1
var total_levels: int = 0
var unlocked_level: int = 0          # 已解锁的最高关卡
var best_steps: Dictionary = {}      # level_index -> int (最少步数)
var tutorial_shown: bool = false     # 本次运行是否已展示过引导

const INF := 1 << 30

func _ready() -> void:
	total_levels = Levels.count()
	_load_progress()

## -- 场景切换 --

func go_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func start_level(index: int) -> void:
	current_level = clampi(index, 0, total_levels - 1)
	level_started.emit(current_level)
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func next_level() -> void:
	if has_next():
		start_level(current_level + 1)
	else:
		go_to_title()

func has_next() -> bool:
	return current_level >= 0 and current_level < total_levels - 1

func is_unlocked(index: int) -> bool:
	return index <= unlocked_level

## -- 关卡完成 --

func complete_current_level(steps: int) -> void:
	var next := mini(current_level + 1, total_levels - 1)
	unlocked_level = maxi(unlocked_level, next)
	var prev: int = best_steps.get(current_level, INF)
	if steps < prev:
		best_steps[current_level] = steps
	_save_progress()

func get_best_steps(index: int) -> int:
	return best_steps.get(index, INF)

## 清空进度（标题页「重置进度」用；⚠️ 会写盘，调用前请确认）
func reset_progress() -> void:
	_clear_progress()
	_save_progress()

## 只清内存、不写盘（便于测试与"确认前预演"）
func _clear_progress() -> void:
	unlocked_level = 0
	best_steps.clear()

## -- 进度存档（存到 user data，不进仓库）--

const SAVE_PATH := "user://save_game.save"

func _save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data := {
			"unlocked_level": unlocked_level,
			"best_steps": best_steps,
		}
		file.store_string(JSON.stringify(data))
		file.close()

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data: Dictionary = json.get_data()
			unlocked_level = data.get("unlocked_level", 0)
			var best: Variant = data.get("best_steps", {})
			if best is Dictionary:
				# ⚠️ JSON 的对象键永远是 String（Godot 4 不再自动转数字），
				# 必须显式转回 int，否则 get_best_steps(关卡) 永远查不到记录
				# （表现为：重启后标题页"最少 N 步"消失、过关时永远说刷新记录）
				best_steps.clear()
				for k in best:
					best_steps[int(k)] = int(best[k])
		file.close()
