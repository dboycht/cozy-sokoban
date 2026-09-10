extends Node
## Cozy Sokoban — 音频管理器（Autoload: `Audio`）
## 音效走小型播放器池（连续移动时不会互相打断）；BGM 单播放器 + 代码设循环点 + 淡入。
## 素材由 tools/gen_audio.gd 合成（16-bit 单声道 22050Hz）。

const SFX_VOLUME := -7.0      # 音效基准音量
const BGM_VOLUME := -18.0     # BGM 刻意压低，做背景

const POOL_SIZE := 8

var SFX: Dictionary = {
	"move": preload("res://assets/audio/move.wav"),
	"push": preload("res://assets/audio/push.wav"),
	"box_done": preload("res://assets/audio/box_done.wav"),
	"win": preload("res://assets/audio/win.wav"),
	"undo": preload("res://assets/audio/undo.wav"),
	"reset": preload("res://assets/audio/reset.wav"),
	"click": preload("res://assets/audio/click.wav"),
}

var muted := false

var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _bgm: AudioStreamPlayer

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.volume_db = SFX_VOLUME
		add_child(p)
		_pool.append(p)
	_start_bgm()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		toggle_mute()

## 播放一个音效；name 见 SFX 字典（不存在则忽略）
func play_sfx(name: StringName) -> void:
	if muted:
		return
	var s: AudioStream = SFX.get(name)
	if s == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.pitch_scale = randf_range(0.97, 1.03)   # 轻微随机音高，避免机械重复感
	p.stream = s
	p.play()

## 静音开关（M 键），返回切换后的静音状态
func toggle_mute() -> bool:
	muted = not muted
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)
	return muted

func _start_bgm() -> void:
	var stream: AudioStreamWAV = load("res://assets/audio/bgm.wav")
	if stream == null:
		return
	# 循环点在代码里设，不依赖 .import 的循环配置
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_bgm = AudioStreamPlayer.new()
	_bgm.stream = stream
	_bgm.volume_db = -40.0        # 从近乎无声淡入
	add_child(_bgm)
	_bgm.play()
	var tw := create_tween()
	tw.tween_property(_bgm, "volume_db", BGM_VOLUME, 2.5)
