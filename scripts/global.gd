extends Node
## Cozy Sokoban — 全局游戏管理器（Autoload 单例）
## 负责：关卡进度、场景切换、游戏状态

signal level_completed(level_index: int)

var current_level: int = 0
var total_levels: int = 0
var unlocked_level: int = 0  # 已解锁的最高关卡

func _ready() -> void:
	total_levels = Levels.count()
	_load_progress()

func go_to_level(index: int) -> void:
	current_level = clampi(index, 0, total_levels - 1)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func go_to_next_level() -> void:
	if current_level + 1 < total_levels:
		unlocked_level = maxi(unlocked_level, current_level + 1)
		_save_progress()
		go_to_level(current_level + 1)
	else:
		# 全部通关
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func complete_current_level() -> void:
	level_completed.emit(current_level)
	go_to_next_level()

## -- 进度存档（存到 user data，不进仓库）--

const SAVE_PATH := "user://save_game.save"

func _save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data := {"unlocked_level": unlocked_level}
		file.store_string(JSON.stringify(data))
		file.close()

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			unlocked_level = json.get_data().get("unlocked_level", 0)
		file.close()
