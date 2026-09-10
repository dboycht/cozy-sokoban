class_name Levels
## Cozy Sokoban — 关卡数据 v2
## ASCII 地图：# 墙 · @ 玩家 · $ 箱子 · . 目标点 · 空格 地板
## 关卡名与提示词用于标题/引导 UI

const LEVEL_NAMES: Array[String] = [
	"初见草地",
	"小小花圃",
	"转角花园",
	"双生花径",
	"静谧庭院",
]

const LEVEL_HINTS: Array[String] = [
	"把木箱推到薄荷色垫子上，狐狸就能回家啦！",
	"一次只能推一个箱子，先想好再动。",
	"绕到箱子后面才能往前推哦。",
	"两个目标、两个箱子，别让它们互相挡住。",
	"庭院深处的小谜题，慢慢来～",
]

const LEVELS: Array[String] = [
	# 第 1 关 — 入门
	"#########
#       #
# . $ @ #
#       #
#########",
	# 第 2 关 — 简单推箱
	"#########
#   #   #
# . # . #
# $ # $ #
#   @   #
#########",
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
	"##########
#        #
#  .  .  #
#        #
#  $  $  #
#        #
#    @   #
##########",
	# 第 5 关 — 小迷宫
	"###########
#   #   # #
# . # . # #
# $ # $ # #
#   #   # #
#     @   #
#         #
###########",
]

## 返回关卡总数
static func count() -> int:
	return LEVELS.size()

## 关卡名
static func level_name(index: int) -> String:
	if index < 0 or index >= LEVEL_NAMES.size():
		return "未知关卡"
	return LEVEL_NAMES[index]

## 关卡提示
static func level_hint(index: int) -> String:
	if index < 0 or index >= LEVEL_HINTS.size():
		return ""
	return LEVEL_HINTS[index]

## 获取指定关卡的 ASCII 地图（越界返回空）
static func get_level(index: int) -> String:
	if index < 0 or index >= LEVELS.size():
		return ""
	return LEVELS[index]

## 将 ASCII 地图解析为网格字典
## 返回 { walls, boxes, targets, player, grid_size }
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
