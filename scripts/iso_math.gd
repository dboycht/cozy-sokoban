class_name IsoMath
## Cozy Sokoban — 等距（2:1 菱形）投影核心
## 纯数学、不依赖场景：把「逻辑格子坐标」翻译成「屏幕像素坐标」，并给出画家算法深度键。
## 逻辑层（boxes/walls/targets 的 Vector2 网格）完全不变，本文件只负责表现层换算。
##
## 坐标约定：
##   格子 (gx, gy) —— gy 向右下增大（朝观众），gy 增大时更靠前
##   屏幕      —— 一个格子是 W 宽 × H 高的菱形（W : H = 2 : 1）

## 菱形瓦片尺寸（2:1，经典等距）
const TILE_W := 64.0
const TILE_H := 32.0

## 逻辑游戏尺寸 640×576；几何常量放在 IsoMath 里，game.gd 与 tools 都从这里取
const VIEW_W := 640.0
const VIEW_H := 576.0

## 顶栏 / 底部 HUD 占位（摆棋盘时避让）
const HUD_TOP := 52.0
const HUD_BOTTOM := 40.0

## 相机倾角系数：屏幕竖直偏移 → 格子纵向偏移的换算（1 格 = H/2 屏幕像素）
const ANGLE_K := TILE_H / 2.0

## 深度键步长：每个 z 单位留 1/OBJECT_SLOTS 个整数槽给同一格内的物体排序
const OBJECT_SLOTS := 32

## 同一格内的层内序号步长（必须 < Godot z_index 上限 4096 / 最大槽数）；
## 棋盘 16x16 + 一个瓦片高 ≈ 34 槽 → 34 * 8 + 4 = 276，安全
const LAYER_STRIDE := 8

## 逻辑格 (gx, gy) → 未加原点偏移的屏幕像素（返回该格的「顶顶点」）
static func cell_to_local(cell: Vector2) -> Vector2:
	return Vector2(
		(cell.x - cell.y) * (TILE_W / 2.0),
		(cell.x + cell.y) * ANGLE_K
	)

## 逻辑格 → 该格菱形地面的几何中心（棋盘局部坐标，已含 _origin）
static func cell_center(cell: Vector2, origin: Vector2 = Vector2.ZERO) -> Vector2:
	return origin + cell_to_local(cell) + Vector2(0.0, TILE_H / 2.0)

## 4 向逻辑方向 → 对应的高亮色（给方向指示器用）
static func dir_color(dir: Vector2) -> Color:
	if dir == Vector2.UP:
		return Color("#8fd4ff")
	if dir == Vector2.DOWN:
		return Color("#ffd166")
	if dir == Vector2.LEFT:
		return Color("#b8f2c9")
	return Color("#ffb3a7")

## 整个菱形棋盘的屏幕包围盒（相对原点），返回 Rect2
static func board_bounds(grid_size: Vector2) -> Rect2:
	var w := maxf(grid_size.x, 1.0)
	var h := maxf(grid_size.y, 1.0)
	var left := -h * (TILE_W / 2.0)
	var width := (w + h) * (TILE_W / 2.0)
	var top := 0.0
	var height := (w + h) * ANGLE_K
	return Rect2(left, top, width, height)

## 把棋盘水平/竖直居中到可视区，返回棋盘原点（应赋给 IsoBoard.origin）
static func board_origin(grid_size: Vector2) -> Vector2:
	var b := board_bounds(grid_size)
	var usable_top := HUD_TOP
	var usable_bottom := VIEW_H - HUD_BOTTOM
	var x := (VIEW_W - b.size.x) / 2.0 - b.position.x
	var y := usable_top + maxf((usable_bottom - usable_top - b.size.y) / 2.0, 8.0) - b.position.y
	return Vector2(round(x), round(y))

## 画家算法排序键（浮点）：格子纵深 + 物体自身高度（越高越晚画，才能正确遮挡后面的高物体）
## 返回 float；z_index 请用 cell_depth_int()（整数且受 Godot ±4096 限制）。
static func depth_key(cell: Vector2, height_px: float = 0.0) -> float:
	var steps := height_px / ANGLE_K
	return (cell.x + cell.y + steps) * OBJECT_SLOTS

## 整数深度（画序槽位）：一格 = 1 槽；层内序号再乘以 LAYER_STRIDE 落在槽内。
## 棋盘最大 16x16 + 立方体一个瓦片高 → 最大约 34 槽，远小于 Godot 的 z_index 上限 4096。
static func cell_depth_int(cell: Vector2, height_px: float = 0.0, layer: int = 0) -> int:
	var steps := int(round(height_px / ANGLE_K))
	return (int(cell.x) + int(cell.y) + steps) * LAYER_STRIDE + layer

## 墙/箱子的像素高度（按瓦片高度比例，至少 1 个 z 单位）
static func body_height_px(h_cells: float) -> float:
	return maxf(h_cells * ANGLE_K, ANGLE_K)
