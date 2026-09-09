# 🎮 Cozy Sokoban

> 像素风闯关推箱子治愈风小游戏 · Godot 4 (GDScript)

一个温馨治愈的像素风格推箱子益智游戏。推动箱子到目标点，享受慢节奏的解谜乐趣。

## ✨ 特性

- 🎨 像素风格画面，温暖治愈的配色
- 🧩 多关卡递进式难度设计
- ↩️ 撤销 / 重置功能，不怕走错
- ⌨️ 方向键 / WASD 操作，简单上手
- 🎵 轻柔背景音乐与音效（计划中）

## 🎯 玩法

- 使用方向键或 WASD 移动角色
- 将所有箱子推到目标点上即可通关
- `Z` 撤销上一步 · `R` 重置当前关卡

## 🛠️ 技术栈

- **引擎**: Godot 4.3 (GL Compatibility 渲染器)
- **语言**: GDScript
- **分辨率**: 640×576（逻辑像素，窗口 2x 缩放）

## 📂 项目结构

```
cozy-sokoban/
├── project.godot        # Godot 工程配置
├── scenes/              # 场景文件 (.tscn)
├── scripts/             # GDScript 脚本
├── assets/              # 美术 / 音频 / 字体资源
│   ├── sprites/
│   ├── audio/
│   └── fonts/
├── levels/              # 关卡数据
└── .gitignore
```

## 🚀 运行

1. 安装 [Godot 4.3+](https://godotengine.org/download)
2. 用 Godot 打开本项目文件夹
3. 按 F5 运行

## 📄 许可证

MIT License
