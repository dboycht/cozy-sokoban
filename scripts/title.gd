extends Node2D
## Cozy Sokoban — 标题页 v2（统一全局坐标系 640x576，直观定位）

const TX_FOX := preload("res://assets/sprites/fox.png")
const TX_BOX := preload("res://assets/sprites/box.png")

var _confirm_root: Control

func _ready() -> void:
	_build_body()
	_build_confirm()

## 清空进度后重建界面（保留确认遮罩节点本身）
func _rebuild() -> void:
	for c in get_children():
		if c != _confirm_root:
			c.queue_free()
	_build_body()

func _build_body() -> void:
	# ---- 背景（草地绿）----
	var bg := ColorRect.new()
	bg.color = UI.C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 顶部浅色带（天空感）
	var sky := ColorRect.new()
	sky.color = Color("#cdeec6")
	sky.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	sky.offset_bottom = 92.0
	add_child(sky)

	# 柔和圆角主卡片（仅装饰背景，装在最底层之上）
	var card := Panel.new()
	card.add_theme_stylebox_override("panel", UI.make_card(Color(1, 1, 1, 0.9), 26))
	card.position = Vector2(110, 26)
	card.size = Vector2(420, 512)
	add_child(card)

	# ---- 立绘：狐狸（居中上区）----
	var fox := Sprite2D.new()
	fox.texture = TX_FOX
	fox.scale = Vector2(7, 7)
	fox.position = Vector2(320, 148)
	add_child(fox)

	# 身旁小箱子（互动感）
	var box := Sprite2D.new()
	box.texture = TX_BOX
	box.scale = Vector2(3.6, 3.6)
	box.position = Vector2(424, 172)
	add_child(box)

	# ---- 标题文字 ----
	var title := UI.make_label("Cozy Sokoban", 46, Color("#7a4a2f"), true)
	title.position = Vector2(110, 212)
	title.size = Vector2(420, 56)
	add_child(title)

	var sub := UI.make_label("小狐狸的推箱子花园", 19, UI.C_TEXT_LIGHT, true)
	sub.position = Vector2(110, 272)
	sub.size = Vector2(420, 26)
	add_child(sub)

	# ---- 开始按钮 ----
	var btn_start := UI.make_button("开 始 冒 险", 24)
	btn_start.position = Vector2(195, 322)
	btn_start.size = Vector2(250, 56)
	btn_start.pressed.connect(func() -> void: Global.start_level(0))
	add_child(btn_start)

	# ---- 选关区（多行网格，随关卡数自动排布）----
	var ts := Levels.total_stars(Global.best_steps)
	var sel_label := UI.make_label("选 择 关 卡　　★ %d / %d" % [ts[0], ts[1]], 15, UI.C_TEXT_LIGHT, true)
	sel_label.position = Vector2(110, 390)
	sel_label.size = Vector2(420, 22)
	add_child(sel_label)

	var total := Levels.count()
	var per_row := 5
	var btn_w := 52.0
	var btn_h := 50.0
	var gap := 12.0
	var row_gap := 8.0
	for i in total:
		var row := int(i / float(per_row))
		var col := i % per_row
		var in_row := mini(per_row, total - row * per_row)
		var row_w := in_row * btn_w + maxf(in_row - 1, 0) * gap
		var bx := 320.0 - row_w / 2.0 + col * (btn_w + gap)
		var by := 420.0 + row * (btn_h + row_gap)

		var locked := not Global.is_unlocked(i)
		var b := UI.make_button(str(i + 1), 20, UI.C_GREEN, UI.C_CREAM)
		b.position = Vector2(bx, by)
		b.size = Vector2(btn_w, btn_h)
		b.disabled = locked
		if not locked:
			var idx := i
			var best := Global.get_best_steps(i)
			var opt := Levels.optimal_steps(i)
			var tip := Levels.level_name(i)
			if best < Global.INF:
				tip += "（最少 %d 步 · %s）" % [opt, Levels.stars_text(Levels.stars_for(i, best))]
			else:
				tip += "（最少 %d 步）" % opt
			b.tooltip_text = tip
			b.pressed.connect(func() -> void: Global.start_level(idx))
		add_child(b)

	# ---- 底部提示 + 重置进度 ----
	# 提示文字保持简短并靠左居中，给右下角按钮留位置（按钮实际高度由字体撑到 31px）
	var hint := UI.make_label("方向键/WASD 移动 · Z 撤销 · R 重置 · M 静音", 14, Color(0.36, 0.3, 0.24, 0.7), true)
	hint.position = Vector2(0, 550)
	hint.size = Vector2(528, 22)
	add_child(hint)

	var btn_reset := UI.make_soft_button("重置进度", 12)
	btn_reset.position = Vector2(536, 540)
	btn_reset.size = Vector2(96, 26)
	btn_reset.tooltip_text = "清空解锁进度与最少步数记录"
	btn_reset.pressed.connect(func() -> void: _confirm_root.visible = true)
	add_child(btn_reset)

## ---- 重置进度二次确认（防误触）----

func _build_confirm() -> void:
	_confirm_root = Control.new()
	_confirm_root.position = Vector2.ZERO
	_confirm_root.size = Vector2(640, 576)
	_confirm_root.visible = false
	add_child(_confirm_root)

	var dim := ColorRect.new()
	dim.color = Color(0.2, 0.16, 0.1, 0.55)
	dim.position = Vector2.ZERO
	dim.size = Vector2(640, 576)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_root.add_child(dim)

	var card := Panel.new()
	card.position = Vector2(160, 206)
	card.size = Vector2(320, 164)
	card.add_theme_stylebox_override("panel", UI.make_card(Color("#fbf3e2"), 20))
	_confirm_root.add_child(card)

	var title := UI.make_label("要清空所有进度吗？", 20, Color("#7a4a2f"), true)
	title.position = Vector2(160, 226)
	title.size = Vector2(320, 30)
	_confirm_root.add_child(title)

	var sub := UI.make_label("解锁进度与每关最少步数都会清空，之后无法恢复。", 13, UI.C_TEXT_LIGHT, true)
	sub.position = Vector2(170, 262)
	sub.size = Vector2(300, 42)
	_confirm_root.add_child(sub)

	var yes := UI.make_button("确定清空", 15, Color("#d9734f"), UI.C_CREAM)
	yes.position = Vector2(178, 312)
	yes.size = Vector2(128, 42)
	yes.pressed.connect(_do_reset)
	_confirm_root.add_child(yes)

	var no := UI.make_soft_button("再想想", 14)
	no.position = Vector2(334, 312)
	no.size = Vector2(128, 42)
	no.pressed.connect(func() -> void: _confirm_root.visible = false)
	_confirm_root.add_child(no)

func _do_reset() -> void:
	Global.reset_progress()
	_confirm_root.visible = false
	_rebuild()
