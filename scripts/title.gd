extends Node2D
## Cozy Sokoban — 标题页 v2（统一全局坐标系 640x576，直观定位）

const TX_FOX := preload("res://assets/sprites/fox.png")
const TX_BOX := preload("res://assets/sprites/box.png")

func _ready() -> void:
	_build()

func _build() -> void:
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

	# ---- 选关区 ----
	var sel_label := UI.make_label("选 择 关 卡", 15, UI.C_TEXT_LIGHT, true)
	sel_label.position = Vector2(110, 402)
	sel_label.size = Vector2(420, 22)
	add_child(sel_label)

	var total := Levels.count()
	var btn_w := 62
	var gap := 16
	var total_w := total * btn_w + (total - 1) * gap
	var start_x := 320.0 - total_w / 2.0
	for i in total:
		var locked := not Global.is_unlocked(i)
		var b := UI.make_button(str(i + 1), 22, UI.C_GREEN, UI.C_CREAM)
		b.position = Vector2(start_x + i * (btn_w + gap), 434)
		b.size = Vector2(btn_w, 54)
		b.disabled = locked
		if not locked:
			var idx := i
			var best := Global.get_best_steps(i)
			var tip := Levels.level_name(i)
			if best < Global.INF:
				tip += "（最少 %d 步）" % best
			b.tooltip_text = tip
			b.pressed.connect(func() -> void: Global.start_level(idx))
		add_child(b)

	# ---- 底部版本提示 ----
	var hint := UI.make_label("方向键 / WASD 移动  ·  Z 撤销  ·  R 重置  ·  M 静音", 14, Color(0.36, 0.3, 0.24, 0.7), true)
	hint.position = Vector2(0, 552)
	hint.size = Vector2(640, 22)
	add_child(hint)
