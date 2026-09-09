class_name Levels
## Cozy Sokoban — 关卡数据
## 用 ASCII 地图定义关卡，# 墙 · @ 玩家 · $ 箱子 · . 目标点 · 空格 地板

const LEVELS: Array[String] = [
	# 第 1 关 — 入门
	"########
#      #
# .$.@ #
#      #
########",
	# 第 2 关 — 简单推箱
	"########
#      #
# .$   #
#   @  #
#      #
########",
	# 第 3 关 — 转角
	"##########
#        #
# .      #
#        #
#  $     #
#    @   #
#        #
##########",
	# 第 4 关 — 双箱
	"#########
#       #
#  . .  #
#  $ $  #
#   @   #
#       #
#########",
	# 第 5 关 — 小迷宫
	"#########
#   #   #
# . # . #
# $ # $ #
#   @   #
#########",
]

## 返回关卡总数
static func count() -> int:
	return LEVELS.size()

## 获取指定关卡的 ASCII 地图（越界返回空）
static func get_level(index: int) -> String:
	if index < 0 or index >= LEVELS.size():
		return ""
	return LEVELS[index]

## 将 ASCII 地图解析为网格字典
## 返回 { walls: PackedVector2Array, boxes: PackedVector2Array,
##        targets: PackedVector2Array, player: Vector2, grid_size: Vector2 }
static func parse_level(index: int) -> Dictionary:
	var ascii := get_level(index)
	var walls: Array[Vector2] = []
	var boxes: Array[Vector2] = []
	var targets: Array[Vector2] = []
	var player := Vector2.ZERO
	var lines := ascii.split("\n")
	var grid_w := 0
	var grid_h := lines.size()
	for y in grid_h:
		var line := lines[y]
		grid_w = maxi(grid_w, line.length())
		for x in line.length():
			var ch := line[x]
			var pos := Vector2(x, y)
			match ch:
				"#": walls.append(pos)
				"@": player = pos
				"$": boxes.append(pos)
				".": targets.append(pos)
	return {
		"walls": walls,
		"boxes": boxes,
		"targets": targets,
		"player": player,
		"grid_size": Vector2(grid_w, grid_h),
	}
