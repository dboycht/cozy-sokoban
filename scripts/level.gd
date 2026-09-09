extends Node2D
## Cozy Sokoban — 单关卡逻辑（网格推箱子核心）
## 挂在 main.tscn 的 Level 节点下

const TILE_SIZE := 32

# 治愈系配色
const COLOR_WALL := Color("#4a3f6e")
const COLOR_FLOOR := Color("#f5e6d3")
const COLOR_TARGET := Color("#7ec699")
const COLOR_BOX := Color("#e8a87c")
const COLOR_BOX_ON_TARGET := Color("#a8d8a8")
const COLOR_PLAYER := Color("#5b9bd5")

var walls: Array[Vector2] = []
var boxes: Array[Vector2] = []
var targets: Array[Vector2] = []
var player := Vector2.ZERO
var grid_size := Vector2.ZERO

# 撤销历史
var _history: Array[Dictionary] = []
const MAX_HISTORY := 200

# 格子占用查询（快速查表）
var _grid: Dictionary = {}  # Vector2 -> String ("wall"/"box"/"target"/"player"/"floor")

func _ready() -> void:
	load_level(Global.current_level)

func load_level(index: int) -> void:
	var data := Levels.parse_level(index)
	if data.is_empty():
		push_warning("CozySokoban: 关卡 %d 不存在" % index)
		return
	walls = data.walls
	boxes = data.boxes.duplicate()
	targets = data.targets
	player = data.player
	grid_size = data.grid_size
	_history.clear()
	_rebuild_grid()
	queue_redraw()

func _rebuild_grid() -> void:
	_grid.clear()
	for pos in targets:
		_grid[pos] = "target"
	for pos in walls:
		_grid[pos] = "wall"
	for pos in boxes:
		_grid[pos] = "box"
	_grid[player] = "player"

func _input(event: InputEvent) -> void:
	var dir := Vector2.ZERO
	if event.is_action_pressed("move_up"):
		dir = Vector2.UP
	elif event.is_action_pressed("move_down"):
		dir = Vector2.DOWN
	elif event.is_action_pressed("move_left"):
		dir = Vector2.LEFT
	elif event.is_action_pressed("move_right"):
		dir = Vector2.RIGHT
	elif event.is_action_pressed("undo"):
		_undo()
		return
	elif event.is_action_pressed("reset"):
		load_level(Global.current_level)
		return
	else:
		return
	if dir != Vector2.ZERO:
		_move(dir)

func _move(dir: Vector2) -> void:
	var new_pos := player + dir
	if _grid.get(new_pos) == "wall":
		return
	# 有箱子？
	if _grid.get(new_pos) == "box":
		var box_new := new_pos + dir
		if _grid.get(box_new) in ["wall", "box"]:
			return  # 推不动
		# 记录历史
		_push_history()
		# 移动箱子
		boxes.erase(new_pos)
		boxes.append(box_new)
	# 记录历史（如果还没记过）
	if _grid.get(new_pos) != "box":
		_push_history()
	# 移动玩家
	player = new_pos
	_rebuild_grid()
	queue_redraw()
	_check_win()

func _push_history() -> void:
	if _history.size() >= MAX_HISTORY:
		_history.pop_front()
	_history.push_back({
		"player": player,
		"boxes": boxes.duplicate(),
	})

func _undo() -> void:
	if _history.is_empty():
		return
	var state: Dictionary = _history.pop_back()
	player = state.player
	boxes = state.boxes
	_rebuild_grid()
	queue_redraw()

func _check_win() -> void:
	for box in boxes:
		if box not in targets:
			return
	if boxes.size() == targets.size():
		Global.complete_current_level()

func _draw() -> void:
	var sx := TILE_SIZE
	# 居中偏移
	var ox := (get_viewport_rect().size.x - grid_size.x * sx) / 2.0
	var oy := (get_viewport_rect().size.y - grid_size.y * sx) / 2.0
	var offset := Vector2(ox, oy)
	# 地板
	for y in grid_size.y:
		for x in grid_size.x:
			var pos := Vector2(x, y)
			draw_rect(Rect2(pos * sx + offset, Vector2(sx, sx)), COLOR_FLOOR)
	# 目标点
	for pos in targets:
		var r := Rect2(pos * sx + offset + Vector2(sx*0.3, sx*0.3), Vector2(sx*0.4, sx*0.4))
		draw_rect(r, COLOR_TARGET)
	# 墙
	for pos in walls:
		draw_rect(Rect2(pos * sx + offset, Vector2(sx, sx)), COLOR_WALL)
	# 箱子
	for pos in boxes:
		var on_target: bool = pos in targets
		var color: Color = COLOR_BOX_ON_TARGET if on_target else COLOR_BOX
		draw_rect(Rect2(pos * sx + offset, Vector2(sx, sx)), color)
		# 箱子边框
		draw_rect(Rect2(pos * sx + offset + Vector2(3,3), Vector2(sx-6, sx-6)),
				  color.darkened(0.15), false, 2.0)
	# 玩家（圆形更可爱）
	var center := player * sx + offset + Vector2(sx/2.0, sx/2.0)
	draw_circle(center, sx/2.0 - 2, COLOR_PLAYER)
	draw_arc(center, sx/2.0 - 2, 0, TAU, 8, COLOR_PLAYER.lightened(0.3), 1.5)
