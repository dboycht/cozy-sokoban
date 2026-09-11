class_name IsoBoard
extends Node2D
## Cozy Sokoban — 等距棋盘（2.5D 立体渲染层）
##
## 只负责「把逻辑格子画成 2:1 等距立体场景」，玩法逻辑（移动/推箱/胜负）仍由上层负责。
## 关键不变量（冒烟测试直接断言）：
##   1) 每个可见格子的 Sprite2D.position = IsoMath.cell_center(格子, origin) + place() 写入的 offset
##   2) z_index 严格按深度单调：靠前的格子（gx+gy 更大）在更上层
##   3) 同一格内：地板 < 装饰 < 目标垫 < 墙/箱（立体物）—— 立体物永远压住自己那格的地面

const FLOOR_TEX := [
	preload("res://assets/sprites/iso_floor.png"),
	preload("res://assets/sprites/iso_floor2.png"),
	preload("res://assets/sprites/iso_floor3.png"),
]
const TX_TARGET := preload("res://assets/sprites/iso_target.png")
const TX_WALL := preload("res://assets/sprites/iso_wall.png")
const TX_BOX := preload("res://assets/sprites/iso_box.png")
const TX_BOX_DONE := preload("res://assets/sprites/iso_box_done.png")
const TX_FLOWER := preload("res://assets/sprites/flower.png")
const TX_FLOWER2 := preload("res://assets/sprites/flower2.png")
const TX_FLOWER3 := preload("res://assets/sprites/flower3.png")
const TX_MUSHROOM := preload("res://assets/sprites/mushroom.png")

## 同格内的层内序号（越小越靠底层）
const LAYER_FLOOR := 0
const LAYER_DECOR := 1
const LAYER_TARGET := 2
const LAYER_OBJECT := 3
const LAYER_FOX := 4

## 立体物的像素高度（与 iso_wall.png 的实际高度一致，用于深度键）
const CUBE_HEIGHT := 32.0

## 精灵放置偏移：把「贴图中心」对到格子中心所需的 (0, TILE_H/2)
const ORIGIN_OFFSET := Vector2(0.0, IsoMath.TILE_H / 2.0)

## 狐狸的基准偏移（贴图中心略低于格子中心，脚踩在菱形中央）
const FOX_BASE_OFFSET := Vector2(0.0, 2.0)

## 撒花装饰概率（与旧版一致的观感）
const DECOR_CHANCE := 0.07

var origin := Vector2.ZERO
var grid_size := Vector2.ZERO
var walls: Array[Vector2] = []
var targets: Array[Vector2] = []
var boxes: Array[Vector2] = []

## 测试/调试用：是否给装饰加一点随机偏移（默认关闭 → 渲染完全确定，便于断言）
var decor_jitter := false

var _rng := RandomNumberGenerator.new()
var _root: Node2D
var _wall_sprites: Dictionary = {}     # Vector2 -> Sprite2D
var _box_sprites: Array[Sprite2D] = []

## 把格子的等距屏幕坐标算出来（含 origin）
func cell_center(cell: Vector2) -> Vector2:
	return IsoMath.cell_center(cell, origin)

## 深度键：整数槽位（格子纵深 + 立方体高度）× 层步长 + 层内序号。
## ⚠️ 层内序号必须落在「一格深度」之内，否则靠后格子上的高层物体会画到靠前格子的地板之后。
func depth_for(cell: Vector2, layer: int) -> int:
	return IsoMath.cell_depth_int(cell, CUBE_HEIGHT, layer)

## 统一放置入口：记录 offset 并设置 z_index
func place(sp: Sprite2D, cell: Vector2, layer: int, pixel_offset: Vector2 = ORIGIN_OFFSET) -> void:
	sp.position = cell_center(cell) + pixel_offset
	sp.set_meta(&"iso_cell", cell)
	sp.set_meta(&"iso_offset", pixel_offset)
	sp.set_meta(&"iso_layer", layer)
	sp.z_index = depth_for(cell, layer)

## 建整盘：walls / targets / boxes 已是逻辑数据，grid_size 决定铺地范围
func build(p_grid_size: Vector2, p_walls: Array[Vector2], p_targets: Array[Vector2], p_boxes: Array[Vector2], seed_value: int) -> void:
	grid_size = p_grid_size
	walls = p_walls
	targets = p_targets
	boxes = p_boxes
	origin = IsoMath.board_origin(grid_size)

	if _root and is_instance_valid(_root):
		_root.queue_free()
	_root = Node2D.new()
	_root.name = "IsoRoot"
	add_child(_root)

	_wall_sprites.clear()
	_box_sprites.clear()

	_rng.seed = seed_value
	var wall_set := {}
	for w in walls:
		wall_set[w] = true
	var target_set := {}
	for t in targets:
		target_set[t] = true

	# 1) 地面 + 装饰
	for gy in int(grid_size.y):
		for gx in int(grid_size.x):
			var cell := Vector2(gx, gy)
			var tile := Sprite2D.new()
			tile.texture = FLOOR_TEX[_rng.randi_range(0, FLOOR_TEX.size() - 1)]
			tile.centered = true
			place(tile, cell, LAYER_FLOOR, Vector2.ZERO)
			_root.add_child(tile)

			if _rng.randf() < DECOR_CHANCE and not wall_set.has(cell) and not target_set.has(cell):
				var dec := Sprite2D.new()
				var pick := _rng.randf()
				if pick < 0.40:
					dec.texture = TX_FLOWER
				elif pick < 0.70:
					dec.texture = TX_FLOWER2
				elif pick < 0.88:
					dec.texture = TX_FLOWER3
				else:
					dec.texture = TX_MUSHROOM
				dec.scale = Vector2(0.9, 0.9)
				var jitter := Vector2.ZERO
				if decor_jitter:
					jitter = Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-4.0, 4.0))
				# 装饰是 16x16 的小图，底部对齐到格子中心
				place(dec, cell, LAYER_DECOR, Vector2(0.0, -4.0) + jitter)
				_root.add_child(dec)

	# 2) 目标垫
	for cell in targets:
		var pad := Sprite2D.new()
		pad.texture = TX_TARGET
		pad.centered = true
		place(pad, cell, LAYER_TARGET, Vector2.ZERO)
		_root.add_child(pad)

	# 3) 墙（立体立方体）
	for cell in walls:
		var wall := Sprite2D.new()
		wall.texture = TX_WALL
		wall.centered = true
		place(wall, cell, LAYER_OBJECT)
		_root.add_child(wall)
		_wall_sprites[cell] = wall

	# 4) 箱子（立体立方体）
	for i in boxes.size():
		var box := Sprite2D.new()
		box.texture = TX_BOX_DONE if boxes[i] in targets else TX_BOX
		box.centered = true
		place(box, boxes[i], LAYER_OBJECT)
		_root.add_child(box)
		_box_sprites.append(box)

## 箱子贴图（按逻辑 boxes 顺序建立 _box_sprites，位置必须一一对应）
func box_sprite(i: int) -> Sprite2D:
	return _box_sprites[i] if i >= 0 and i < _box_sprites.size() else null

func box_sprites() -> Array[Sprite2D]:
	return _box_sprites

## 箱子移动后同步贴图与位置（原地替换逻辑坐标，绝不打乱下标 —— 见 ERROR.md #7）
func refresh_box(i: int, dur: float, create_tween_fn: Callable) -> void:
	var sp := box_sprite(i)
	if sp == null:
		return
	sp.texture = TX_BOX_DONE if boxes[i] in targets else TX_BOX
	var dst := cell_center(boxes[i]) + ORIGIN_OFFSET
	if dur <= 0.0:
		sp.position = dst
	else:
		var tw: Tween = create_tween_fn.call()
		tw.tween_property(sp, "position", dst, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 换格后深度键必须跟着更新，否则会压在错误的层
	sp.z_index = depth_for(boxes[i], LAYER_OBJECT)
	sp.set_meta(&"iso_cell", boxes[i])

## 全部箱子归位（撤销/重置用）
func refresh_all_boxes(dur: float, create_tween_fn: Callable) -> void:
	for i in boxes.size():
		refresh_box(i, dur, create_tween_fn)

func wall_count() -> int:
	return _wall_sprites.size()
