extends Node2D
## Cozy Sokoban — v2 游戏场景（挂在 game.tscn）
## UI 全部用 640x576 屏幕绝对坐标（父容器 CanvasLayer 非 Control，避免锚点坑）

const TILE := 32.0
const MOVE_DURATION := 0.13

const TX_FLOOR1 := preload("res://assets/sprites/floor.png")
const TX_FLOOR2 := preload("res://assets/sprites/floor2.png")
const TX_FLOOR3 := preload("res://assets/sprites/floor3.png")
const TX_TARGET := preload("res://assets/sprites/target.png")
const TX_BOX := preload("res://assets/sprites/box.png")
const TX_BOX_DONE := preload("res://assets/sprites/box_done.png")
const TX_WALL := preload("res://assets/sprites/wall.png")
const TX_FOX := preload("res://assets/sprites/fox.png")
const TX_FLOWER := preload("res://assets/sprites/flower.png")
const TX_FLOWER2 := preload("res://assets/sprites/flower2.png")

# ---- 逻辑状态 ----
var walls: Array[Vector2] = []
var boxes: Array[Vector2] = []
var targets: Array[Vector2] = []
var player := Vector2.ZERO
var grid_size := Vector2.ZERO
var _grid: Dictionary = {}
var _history: Array[Dictionary] = []
var _steps := 0
var _winning := false

# ---- 视觉 ----
var _board_origin := Vector2.ZERO
var _box_sprites: Array[Sprite2D] = []
var _fox_sprite: Sprite2D
var _board_root: Node2D

# ---- UI（屏幕绝对坐标）----
var _canvas: CanvasLayer
var _hud_steps: Label
var _hud_title: Label
var _hint_label: Label
var _tutorial_root: Control
var _celebrate_root: Control
var _win_label: Label
var _stats_label: Label
var _next_btn: Button

func _ready() -> void:
	_build_ui()
	load_level(Global.current_level)
	if Global.current_level == 0 and not Global.tutorial_shown:
		_show_tutorial()

## ================= UI 构建 =================

func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 10
	add_child(_canvas)

	# ---- 顶栏 ----
	var top := ColorRect.new()
	top.color = Color(1, 1, 0.94, 0.85)
	top.position = Vector2(0, 0)
	top.size = Vector2(640, 44)
	_canvas.add_child(top)

	_hud_title = UI.make_label("", 18, UI.C_TEXT, true)
	_hud_title.position = Vector2(80, 6)
	_hud_title.size = Vector2(400, 32)
	_canvas.add_child(_hud_title)

	var btn_menu := UI.make_soft_button("菜单", 13)
	btn_menu.position = Vector2(10, 6)
	btn_menu.size = Vector2(72, 32)
	btn_menu.pressed.connect(func() -> void: Global.go_to_title())
	_canvas.add_child(btn_menu)

	_hud_steps = UI.make_label("0 步", 15, UI.C_TEXT_LIGHT)
	_hud_steps.position = Vector2(520, 6)
	_hud_steps.size = Vector2(110, 32)
	_hud_steps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_canvas.add_child(_hud_steps)

	# ---- 底部撤销/重置/提示 ----
	var btn_undo := UI.make_soft_button("撤销 (Z)", 13)
	btn_undo.position = Vector2(452, 534)
	btn_undo.size = Vector2(90, 34)
	btn_undo.pressed.connect(_undo)
	_canvas.add_child(btn_undo)

	var btn_reset := UI.make_soft_button("重置 (R)", 13)
	btn_reset.position = Vector2(546, 534)
	btn_reset.size = Vector2(88, 34)
	btn_reset.pressed.connect(func() -> void: load_level(Global.current_level))
	_canvas.add_child(btn_reset)

	_hint_label = UI.make_label("", 13, UI.C_TEXT_LIGHT, true)
	_hint_label.position = Vector2(0, 538)
	_hint_label.size = Vector2(440, 30)
	_canvas.add_child(_hint_label)

	_build_tutorial_ui()
	_build_celebrate_ui()

## ---- 首关教程遮罩 ----

func _build_tutorial_ui() -> void:
	_tutorial_root = Control.new()
	_tutorial_root.position = Vector2(0, 0)
	_tutorial_root.size = Vector2(640, 576)
	_tutorial_root.visible = false
	_canvas.add_child(_tutorial_root)

	var dim := ColorRect.new()
	dim.color = Color(0.2, 0.16, 0.1, 0.55)
	dim.position = Vector2(0, 0)
	dim.size = Vector2(640, 576)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_root.add_child(dim)

	var card := Panel.new()
	card.position = Vector2(96, 76)
	card.size = Vector2(448, 424)
	card.add_theme_stylebox_override("panel", UI.make_card(Color("#fbf3e2"), 24))
	_tutorial_root.add_child(card)

	var title := UI.make_label("欢迎来到 Cozy Sokoban！", 24, Color("#7a4a2f"), true)
	title.position = Vector2(96, 96)
	title.size = Vector2(448, 40)
	_tutorial_root.add_child(title)

	var intro := UI.make_label(
		"我是小狐狸，把木箱推到薄荷色垫子上，我就有家啦！\n每一关都暖暖的，慢慢想，不着急。",
		15, UI.C_TEXT, true)
	intro.position = Vector2(110, 142)
	intro.size = Vector2(420, 52)
	_tutorial_root.add_child(intro)

	# 图例：箱子 → 目标 → 就位（三项）
	_legend_show(96, 210)

	var keys := UI.make_label(
		"移动：方向键 或 WASD\n撤销：Z       重置本关：R",
		15, UI.C_TEXT, true)
	keys.position = Vector2(150, 330)
	keys.size = Vector2(340, 64)
	_tutorial_root.add_child(keys)

	var btn := UI.make_button("好，出发！", 20)
	btn.position = Vector2(225, 432)
	btn.size = Vector2(190, 50)
	btn.pressed.connect(_dismiss_tutorial)
	_tutorial_root.add_child(btn)

func _legend_show(card_x: float, card_y: float) -> void:
	# 三张 96x72 小卡 + 两个箭头，横排居中于卡片
	var items := [
		[TX_BOX, "箱子"],
		[TX_TARGET, "目标点"],
		[TX_BOX_DONE, "就位！"],
	]
	var total_w := 3.0 * 96.0 + 2.0 * 28.0
	var x := card_x + (448.0 - total_w) / 2.0
	for it in items:
		var c := Control.new()
		c.position = Vector2(x, card_y)
		c.size = Vector2(96, 76)
		var sp := TextureRect.new()
		sp.texture = it[0]
		sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sp.position = Vector2(0, 0)
		sp.size = Vector2(96, 56)
		c.add_child(sp)
		var lb := UI.make_label(it[1], 13, UI.C_TEXT_LIGHT, true)
		lb.position = Vector2(0, 56)
		lb.size = Vector2(96, 20)
		c.add_child(lb)
		_tutorial_root.add_child(c)
		x += 96.0
		if it[1] != "就位！":
			var arrow := UI.make_label("→", 22, Color("#a98b5f"), true)
			arrow.position = Vector2(x - 28, card_y + 18)
			arrow.size = Vector2(28, 30)
			_tutorial_root.add_child(arrow)
			x += 28.0

func _show_tutorial() -> void:
	_tutorial_root.visible = true

func _dismiss_tutorial() -> void:
	Global.tutorial_shown = true
	_tutorial_root.visible = false

## ---- 过关庆祝 ----

func _build_celebrate_ui() -> void:
	_celebrate_root = Control.new()
	_celebrate_root.position = Vector2(0, 0)
	_celebrate_root.size = Vector2(640, 576)
	_celebrate_root.visible = false
	_canvas.add_child(_celebrate_root)

	var dim := ColorRect.new()
	dim.color = Color(0.2, 0.16, 0.1, 0.5)
	dim.position = Vector2(0, 0)
	dim.size = Vector2(640, 576)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_celebrate_root.add_child(dim)

	var card := Panel.new()
	card.position = Vector2(140, 130)
	card.size = Vector2(360, 320)
	card.add_theme_stylebox_override("panel", UI.make_card(Color("#fdf3df"), 24))
	_celebrate_root.add_child(card)

	_win_label = UI.make_label("过关啦！", 32, Color("#6f9f4f"), true)
	_win_label.position = Vector2(140, 152)
	_win_label.size = Vector2(360, 48)
	_celebrate_root.add_child(_win_label)

	var stars := UI.make_label("★ ★ ★", 26, Color("#f4b942"), true)
	stars.position = Vector2(140, 204)
	stars.size = Vector2(360, 34)
	_celebrate_root.add_child(stars)

	_stats_label = UI.make_label("", 16, UI.C_TEXT_LIGHT, true)
	_stats_label.position = Vector2(140, 248)
	_stats_label.size = Vector2(360, 30)
	_celebrate_root.add_child(_stats_label)

	_next_btn = UI.make_button("下一关  →", 20, UI.C_GREEN, UI.C_CREAM)
	_next_btn.position = Vector2(195, 300)
	_next_btn.size = Vector2(250, 52)
	_next_btn.pressed.connect(_go_next)
	_celebrate_root.add_child(_next_btn)

	var again := UI.make_soft_button("再玩一次", 13)
	again.position = Vector2(195, 358)
	again.size = Vector2(120, 36)
	again.pressed.connect(func() -> void: load_level(Global.current_level))
	_celebrate_root.add_child(again)

	var menu := UI.make_soft_button("回到菜单", 13)
	menu.position = Vector2(325, 358)
	menu.size = Vector2(120, 36)
	menu.pressed.connect(func() -> void: Global.go_to_title())
	_celebrate_root.add_child(menu)

## ================= 关卡加载 =================

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
	_steps = 0
	_winning = false
	if _celebrate_root:
		_celebrate_root.visible = false
	_rebuild_grid()
	_build_board()
	_refresh_hud()

func _refresh_hud() -> void:
	_hud_steps.text = "%d 步" % _steps
	_hud_title.text = "第 %d 关 · %s" % [Global.current_level + 1, Levels.level_name(Global.current_level)]
	_hint_label.text = Levels.level_hint(Global.current_level)

func _rebuild_grid() -> void:
	_grid.clear()
	for pos in targets:
		_grid[pos] = "target"
	for pos in walls:
		_grid[pos] = "wall"
	for pos in boxes:
		_grid[pos] = "box"
	_grid[player] = "player"

## ================= 棋盘 =================

func _board_origin_for() -> Vector2:
	var board_px := grid_size * TILE
	var top := 50.0
	var bottom := 530.0
	return Vector2(
		(640.0 - board_px.x) / 2.0,
		top + (bottom - top - board_px.y) / 2.0
	)

func _cell_center(cell: Vector2) -> Vector2:
	return _board_origin + cell * TILE + Vector2(TILE / 2, TILE / 2)

func _build_board() -> void:
	_board_origin = _board_origin_for()
	_box_sprites.clear()
	if _board_root:
		_board_root.queue_free()
	_board_root = Node2D.new()
	_board_root.name = "Board"
	add_child(_board_root)

	var rng := RandomNumberGenerator.new()
	rng.seed = 20260910 + Global.current_level * 7
	var floor_texs := [TX_FLOOR1, TX_FLOOR2, TX_FLOOR3]

	# 地板
	for y in grid_size.y:
		for x in grid_size.x:
			var cell := Vector2(x, y)
			var sp := Sprite2D.new()
			sp.texture = floor_texs[rng.randi_range(0, 2)]
			sp.scale = Vector2(TILE / sp.texture.get_width(), TILE / sp.texture.get_height())
			sp.position = _cell_center(cell)
			_board_root.add_child(sp)
			# 空地撒花装饰（避开墙、目标、出生点）
			if rng.randf() < 0.06 and cell not in walls and cell not in targets and cell != player:
				var fl := Sprite2D.new()
				fl.texture = TX_FLOWER if rng.randf() < 0.6 else TX_FLOWER2
				fl.scale = Vector2(TILE / fl.texture.get_width(), TILE / fl.texture.get_height())
				fl.position = _cell_center(cell)
				fl.z_index = 0.5
				_board_root.add_child(fl)
	# 目标点（画在地板上方）
	for pos in targets:
		var sp := Sprite2D.new()
		sp.texture = TX_TARGET
		sp.scale = Vector2(TILE / TX_TARGET.get_width(), TILE / TX_TARGET.get_height())
		sp.position = _cell_center(pos)
		sp.z_index = 1
		_board_root.add_child(sp)
	# 墙
	for pos in walls:
		var sp := Sprite2D.new()
		sp.texture = TX_WALL
		sp.scale = Vector2(TILE / TX_WALL.get_width(), TILE / TX_WALL.get_height())
		sp.position = _cell_center(pos)
		sp.z_index = 2
		_board_root.add_child(sp)
	# 箱子
	for pos in boxes:
		_box_sprites.append(_make_box_sprite(pos, pos in targets))
	# 狐狸
	_fox_sprite = Sprite2D.new()
	_fox_sprite.texture = TX_FOX
	var fs := TILE / TX_FOX.get_width()
	_fox_sprite.scale = Vector2(fs * 1.05, fs * 1.05)
	_fox_sprite.position = _cell_center(player)
	_fox_sprite.z_index = 5
	_board_root.add_child(_fox_sprite)

func _make_box_sprite(cell: Vector2, on_target: bool) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = TX_BOX_DONE if on_target else TX_BOX
	var bs := TILE / TX_BOX.get_width()
	sp.scale = Vector2(bs * 0.95, bs * 0.95)
	sp.position = _cell_center(cell)
	sp.z_index = 3
	_board_root.add_child(sp)
	return sp

## ================= 输入与移动 =================

func _input(event: InputEvent) -> void:
	if _winning or (_tutorial_root and _tutorial_root.visible):
		return
	if _celebrate_root and _celebrate_root.visible:
		return
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
		_try_move(dir)

func _try_move(dir: Vector2) -> void:
	var new_pos := player + dir
	if _grid.get(new_pos) == "wall":
		_bump_animation(dir)
		return
	var pushed_box := -1
	if _grid.get(new_pos) == "box":
		var box_new := new_pos + dir
		if _grid.get(box_new) in ["wall", "box"]:
			_bump_animation(dir)
			return
		_push_history()
		boxes.erase(new_pos)
		boxes.append(box_new)
		pushed_box = boxes.size() - 1
	else:
		_push_history()
	player = new_pos
	_steps += 1
	_rebuild_grid()
	_refresh_hud()
	_animate(dir, pushed_box)
	_check_win()

func _push_history() -> void:
	if _history.size() >= 200:
		_history.pop_front()
	_history.push_back({
		"player": player,
		"boxes": boxes.duplicate(),
		"steps": _steps,
	})

func _undo() -> void:
	if _history.is_empty() or _winning:
		return
	if _tutorial_root and _tutorial_root.visible:
		return
	var state: Dictionary = _history.pop_back()
	player = state.player
	boxes = state.boxes
	_steps = state.steps
	_rebuild_grid()
	_refresh_hud()
	_refresh_box_positions(0.0)
	if _fox_sprite:
		_fox_sprite.position = _cell_center(player)

func _animate(dir: Vector2, pushed_box: int) -> void:
	if _fox_sprite:
		if dir.x != 0:
			_fox_sprite.flip_h = dir.x > 0
		var tw := create_tween()
		tw.tween_property(_fox_sprite, "position", _cell_center(player), MOVE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if pushed_box >= 0 and pushed_box < _box_sprites.size():
		var bs := _box_sprites[pushed_box]
		var on_target := boxes[pushed_box] in targets
		# 换图 + 滑动
		bs.texture = TX_BOX_DONE if on_target else TX_BOX
		var tw2 := create_tween()
		tw2.tween_property(bs, "position", _cell_center(boxes[pushed_box]), MOVE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _refresh_box_positions(dur: float) -> void:
	for i in boxes.size():
		if i < _box_sprites.size():
			_box_sprites[i].texture = TX_BOX_DONE if boxes[i] in targets else TX_BOX
			if dur > 0:
				var tw := create_tween()
				tw.tween_property(_box_sprites[i], "position", _cell_center(boxes[i]), dur)
			else:
				_box_sprites[i].position = _cell_center(boxes[i])

func _bump_animation(dir: Vector2) -> void:
	if not _fox_sprite:
		return
	var orig := _cell_center(player)
	var tw := create_tween()
	tw.tween_property(_fox_sprite, "position", orig + dir * 4.0, 0.05)
	tw.tween_property(_fox_sprite, "position", orig, 0.08)

func _check_win() -> void:
	if boxes.is_empty() or boxes.size() != targets.size():
		return
	for box in boxes:
		if box not in targets:
			return
	_win()

func _win() -> void:
	if _winning:
		return
	_winning = true
	Global.complete_current_level(_steps)
	var best := Global.get_best_steps(Global.current_level)
	_win_label.text = "过关啦！"
	_stats_label.text = "本关用了 %d 步 · %s" % [
		_steps,
		"刷新了你的记录！" if _steps == best else "最佳记录 %d 步" % best,
	]
	if not Global.has_next():
		_next_btn.text = "全部通关 · 回菜单"
	_celebrate_root.visible = true

func _go_next() -> void:
	if Global.has_next():
		Global.start_level(Global.current_level + 1)
	else:
		Global.go_to_title()
