class_name UI
## Cozy Sokoban — 治愈风 UI 工厂
## 统一：中文字体 / 圆角奶油卡片 / 柔和按钮 / 配色常量

# ---- 治愈配色 ----
const C_TEXT := Color("#5a4633")      # 深棕文字
const C_TEXT_LIGHT := Color("#8a7355")
const C_CREAM := Color("#fff8ec")     # 卡片奶油白
const C_CREAM_LINE := Color("#e8d9bd")
const C_BG := Color("#a8d8a0")        # 页面背景草绿
const C_GREEN := Color("#8fca8f")
const C_GREEN_DARK := Color("#5e9c68")
const C_ORANGE := Color("#f2a35e")
const C_ORANGE_DARK := Color("#c97b3f")
const C_BROWN := Color("#b58b5f")
const C_SHADOW := Color(0.30, 0.22, 0.12, 0.28)

## 中文字体（Godot 默认字体无中文字形 → 用系统字体）
static func font(size: int) -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray([
		"Microsoft YaHei UI", "Microsoft YaHei", "SimHei",
		"Noto Sans CJK SC", "Source Han Sans SC",
	])
	f.font_weight = 500
	return f

## 圆角卡片背景（PanelContainer / Panel）
static func make_card(color: Color = C_CREAM, radius: float = 14.0, border_color: Color = C_CREAM_LINE) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(radius))
	sb.border_color = border_color
	sb.set_border_width_all(2)
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	sb.shadow_color = C_SHADOW
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 3)
	return sb

## 柔和主按钮（浅橙）
static func make_button(text: String, font_size: int = 18, bg: Color = C_ORANGE, bg_hover: Color = C_CREAM) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_override("font", font(font_size))
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", C_TEXT)
	btn.add_theme_color_override("font_pressed_color", C_TEXT)
	btn.add_theme_color_override("font_focus_color", C_TEXT)

	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(12)
	sb.shadow_color = C_SHADOW
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 3)
	sb.content_margin_left = 18.0
	sb.content_margin_right = 18.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("normal", sb)

	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = bg_hover
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# 禁用态：灰
	var sb_d := sb.duplicate() as StyleBoxFlat
	sb_d.bg_color = Color(0.78, 0.74, 0.68)
	sb_d.shadow_size = 0
	btn.add_theme_stylebox_override("disabled", sb_d)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.52, 0.48))
	return btn

## 文本标签（可多行、居中）
static func make_label(text: String, font_size: int = 16, color: Color = C_TEXT, center: bool = false) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_override("font", font(font_size))
	lb.add_theme_color_override("font_color", color)
	if center:
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lb

## 柔和返回/次要按钮（浅色描边）
static func make_soft_button(text: String, font_size: int = 14) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_override("font", font(font_size))
	btn.add_theme_color_override("font_color", C_TEXT)
	btn.add_theme_color_override("font_hover_color", C_TEXT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.5)
	sb.set_corner_radius_all(10)
	sb.border_color = Color.WHITE
	sb.set_border_width_all(1)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(1, 1, 1, 0.9)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn
