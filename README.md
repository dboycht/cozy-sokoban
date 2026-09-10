# 🎮 Cozy Sokoban

> 像素风闯关推箱子 · 治愈花园风小游戏 · Godot 4 (GDScript)

小狐狸推木箱的治愈系解谜游戏：把木箱推到薄荷色的垫子上，箱子就会开花，狐狸就有家啦。

## ✨ 特性

- 🦊 **治愈花园像素美术**：小狐狸、暖橙木箱、薄荷草垫、树篱墙、草地与小花（16×16 像素，最近邻放大不糊）
- 🏡 **完整流程**：标题页 → 选关 → 关卡内 HUD → 首关引导 → 过关庆祝
- 🌱 **首关新手指引**：图例说明「箱子 → 目标点 → 就位」，温和不打断
- ⭐ **进度记录**：解锁进度与每关最少步数自动存档（`user://save_game.save`）
- ↩️ **撤销 / 重置**：走错不怕，`Z` 撤销、`R` 重来
- 🧩 **5 个递进关卡**：从 3 步入门到 10 步小迷宫
- 🎵 音效与 BGM（计划中）

## 🎯 玩法

- 方向键或 `WASD` 移动小狐狸
- 把所有木箱推到目标点上即可通关（一次只能推一个，推不动就是被挡住了）
- `Z` 撤销上一步 · `R` 重置当前关卡
- 标题页可用数字按钮直接选已解锁的关卡

## 🛠️ 技术栈

- **引擎**: Godot 4.5（GL Compatibility 渲染器，已用 4.5 stable 验证）
- **语言**: GDScript
- **分辨率**: 逻辑 640×576，窗口默认 2 倍缩放（1280×1152），`stretch_mode=viewport`
- **贴图过滤**: 最近邻（`default_texture_filter=0`），保证像素锐利

## 📂 项目结构

```
cozy-sokoban/
├── project.godot              # 工程配置（主场景 scenes/title.tscn）
├── scenes/
│   ├── title.tscn             # 标题页 / 选关
│   └── game.tscn              # 游戏场景
├── scripts/
│   ├── global.gd              # [Autoload] 关卡切换、解锁、最少步数、存档
│   ├── levels.gd              # 关卡数据：5 关 ASCII + 关卡名/提示
│   ├── title.gd               # 标题页构建
│   ├── level.gd               # 棋盘渲染 + 移动/推箱/撤销/胜利/引导/庆祝
│   └── ui.gd                  # UI 工厂：中文字体、奶油卡片、柔和按钮、配色
├── assets/sprites/            # 像素素材（16×16 PNG）+ 项目图标
├── levels/                    # （关卡数据仍内嵌 levels.gd）
└── .gitignore
```

## 🚀 运行

1. 安装 [Godot 4.5](https://godotengine.org/download)（4.3+ 亦可）
2. 用 Godot 打开本项目文件夹
3. 按 `F5` 运行

## 📄 许可证

MIT License
