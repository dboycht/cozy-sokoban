class_name BoardView
extends Node2D
## Cozy Sokoban — 正交俯视棋盘渲染层（星露谷风）
##
## 只负责「把逻辑格子画成画面」，玩法逻辑（移动/推箱/胜负）由上层负责。
## 深度规则（冒烟测试直接断言）：
##   1) 地板 < 本格物体 < 下一行的所有东西
##   2) 物体贴图是「整格高（32px）」，直接画在格子左上角：
##      底边 = 格子底缘（不会盖到下一行），顶边 = 格子顶缘（会盖住本格上半的地面），
##      于是同一格里「物体会浮在地面之上」——这就是星露谷/DQ 式的伪 3D 观感
##   3) 同一行内：目标垫 < 箱子 < 玩家

const TS := 32.0                  # 瓦片边长
## 物体贴图不足整格高时，向下补的像素（底边对齐用）。本轮素材都是整格高 → 0
const OBJ_LIFT := 0.0

const LAYER_FLOOR := 0
const LAYER_DECOR := 1
const LAYER_TARGET := 2
const LAYER_OBJECT := 3
const LAYER_ACTOR := 4
const LAYER_STRIDE := 8

const TILE_TEX := [
	preload("res://assets/sprites/tile_grass.png"),
	preload("res://assets/sprites/tile_grass2.png"),
	preload("res://assets/sprites/tile_grass3.png"),
]
const TX_DIRT := preload("res://assets/sprites/tile_dirt.png")
const TX_WALL := preload("res://assets/sprites/obj_wall.png")
const TX_BOX := preload("res://assets/sprites/obj_box.png")
const TX_BOX_DONE := preload("res://assets/sprites/obj_box_done.png")
const TX_TARGET := preload("res://assets/sprites/obj_target.png")
const TX_FLOWER := preload("res://assets/sprites/dec_flower.png")
const TX_FLOWER2 := preload("res://assets/sprites/dec_flower2.png")
const TX_FLOWER3 := preload("res://assets/sprites/dec_flower3.png")
const TX_TREE := preload("res://assets/sprites/dec_tree.png")

const FOX_DIRS := {
	"down": [
		preload("res://assets/sprites/fox_down_0.png"),
		preload("res://assets/sprites/fox_down_1.png"),
		preload("res://assets/sprites/fox_down_2.png"),
	],
	"up": [
		preload("res://assets/sprites/fox_up_0.png"),
		preload("res://assets/sprites/fox_up_1.png"),
		preload("res://assets/sprites/fox_up_2.png"),
	],
	"left": [
		preload("res://assets/sprites/fox_left_0.png"),
		preload("res://assets/sprites/fox_left_1.png"),
		preload("res://assets/sprites/fox_left_2.png"),
	],
	"right": [
		preload("res://assets/sprites/fox_right_0.png"),
		preload("res://assets/sprites/fox_right_1.png"),
		preload("res://assets/sprites/fox_right_2.png"),
	],
}

const DECOR_CHANCE := 0.10
const VIEW_W := 640.0
const VIEW_H := 576.0
const HUD_TOP := 52.0
const HUD_BOTTOM := 40.0

var origin := Vector2.ZERO
var grid_size := Vector2.ZERO
var walls: Array[Vector2] = []
var targets: Array[Vector2] = []
var boxes: Array[Vector2] = []
var decor_jitter := false

var _rng := RandomNumberGenerator.new()
var _root: Node2D
var _box_sprites: Array[Sprite2D] = []

## 格子左上角在屏幕上的位置
func cell_origin(cell: Vector2) -> Vector2:
	return origin + cell * TS

## 格子中心
func cell_center(cell: Vector2) -> Vector2:
	return cell_origin(cell) + Vector2(TS / 2.0, TS / 2.0)

## 深度键：行 × 层步长 + 层内序号（行是俯视唯一的深度轴）
func depth_for(cell: Vector2, layer: int) -> int:
	return (int(cell.y) * 4 + int(cell.x)) * LAYER_STRIDE + layer

## 瓦片棋盘在屏幕上的包围盒
func board_size() -> Vector2:
	return grid_size * TS

## 把棋盘居中到可视区（顶栏与底部提示之间）
static func origin_for(grid_size: Vector2) -> Vector2:
	var size := grid_size * TS
	var usable_top := HUD_TOP
	var usable_bottom := VIEW_H - HUD_BOTTOM
	var x := (VIEW_W - size.x) / 2.0
	var y := usable_top + maxf((usable_bottom - usable_top - size.y) / 2.0, 4.0)
	return Vector2(round(x), round(y))

func build(p_grid_size: Vector2, p_walls: Array[Vector2], p_targets: Array[Vector2], p_boxes: Array[Vector2], seed_value: int) -> void:
	grid_size = p_grid_size
	walls = p_walls
	targets = p_targets
	boxes = p_boxes
	origin = origin_for(grid_size)
	_rng.seed = seed_value

	if _root and is_instance_valid(_root):
		_root.queue_free()
	_root = Node2D.new()
	_root.name = "BoardRoot"
	add_child(_root)
	_box_sprites.clear()

	var wall_set := {}
	for w in walls:
		wall_set[w] = true
	var target_set := {}
	for t in targets:
		target_set[t] = true

	# 1) 整块地面（每格一张瓦片，铺满，无缝隙）
	for gy in int(grid_size.y):
		for gx in int(grid_size.x):
			var cell := Vector2(gx, gy)
			var tile := Sprite2D.new()
			tile.texture = TILE_TEX[_rng.randi_range(0, TILE_TEX.size() - 1)]
			tile.centered = false
			tile.position = cell_origin(cell)
			tile.z_index = depth_for(cell, LAYER_FLOOR)
			tile.set_meta(&"cell", cell)
			tile.set_meta(&"layer", LAYER_FLOOR)
			_root.add_child(tile)

			# 装饰（不放墙/目标/箱子格）
			if _rng.randf() < DECOR_CHANCE and not wall_set.has(cell) and not target_set.has(cell) and not (cell in boxes):
				var dec := Sprite2D.new()
				var pick := _rng.randf()
				if pick < 0.45:
					dec.texture = TX_FLOWER
					dec.scale = Vector2(1.4, 1.4)
				elif pick < 0.75:
					dec.texture = TX_FLOWER2
					dec.scale = Vector2(1.4, 1.4)
				elif pick < 0.92:
					dec.texture = TX_FLOWER3
					dec.scale = Vector2(1.4, 1.4)
				else:
					dec.texture = TX_TREE
					dec.scale = Vector2(1.0, 1.0)
				var jitter := Vector2.ZERO
				if decor_jitter:
					jitter = Vector2(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-4.0, 4.0))
				# 装饰底边贴格底（树下更能盖住格子，显得立体）
				dec.position = Vector2(
					cell_origin(cell).x - (dec.texture.get_width() * dec.scale.x - TS) / 2.0,
					cell_origin(cell).y + TS - dec.texture.get_height() * dec.scale.y)
				dec.position += jitter
				dec.z_index = depth_for(cell, LAYER_DECOR)
				dec.set_meta(&"cell", cell)
				dec.set_meta(&"layer", LAYER_DECOR)
				_root.add_child(dec)

	# 2) 目标垫
	for cell in targets:
		var pad := Sprite2D.new()
		pad.texture = TX_TARGET
		pad.centered = false
		pad.position = cell_origin(cell)
		pad.z_index = depth_for(cell, LAYER_TARGET)
		pad.set_meta(&"cell", cell)
		pad.set_meta(&"layer", LAYER_TARGET)
		_root.add_child(pad)

	# 3) 墙
	for cell in walls:
		var w := Sprite2D.new()
		w.texture = TX_WALL
		w.centered = false
		w.position = cell_origin(cell) + Vector2(0.0, OBJ_LIFT)
		w.z_index = depth_for(cell, LAYER_OBJECT)
		w.set_meta(&"cell", cell)
		w.set_meta(&"layer", LAYER_OBJECT)
		_root.add_child(w)

	# 4) 箱子
	for i in boxes.size():
		var b := Sprite2D.new()
		b.texture = TX_BOX_DONE if boxes[i] in targets else TX_BOX
		b.centered = false
		b.position = cell_origin(boxes[i]) + Vector2(0.0, OBJ_LIFT)
		b.z_index = depth_for(boxes[i], LAYER_OBJECT)
		b.set_meta(&"cell", boxes[i])
		b.set_meta(&"layer", LAYER_OBJECT)
		_root.add_child(b)
		_box_sprites.append(b)

func box_sprite(i: int) -> Sprite2D:
	return _box_sprites[i] if i >= 0 and i < _box_sprites.size() else null

func box_sprites() -> Array[Sprite2D]:
	return _box_sprites

## 箱子换格后同步贴图/位置/深度（⚠️ 逻辑 boxes 下标必须原地替换，ERROR.md #7）
func refresh_box(i: int, dur: float, tween_factory: Callable) -> void:
	var sp := box_sprite(i)
	if sp == null:
		return
	sp.texture = TX_BOX_DONE if boxes[i] in targets else TX_BOX
	var dst := cell_origin(boxes[i]) + Vector2(0.0, OBJ_LIFT)
	if dur <= 0.0:
		sp.position = dst
	else:
		var tw: Tween = tween_factory.call()
		tw.tween_property(sp, "position", dst, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	sp.z_index = depth_for(boxes[i], LAYER_OBJECT)
	sp.set_meta(&"cell", boxes[i])

func refresh_all_boxes(dur: float, tween_factory: Callable) -> void:
	for i in boxes.size():
		refresh_box(i, dur, tween_factory)
