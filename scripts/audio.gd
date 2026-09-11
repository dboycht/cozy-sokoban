extends Node
## Cozy Sokoban — 音频管理器（Autoload: `Audio`）
## 音效走小型播放器池（连续移动时不会互相打断）；BGM 单播放器 + 代码设循环点 + 淡入。
## 素材由 tools/gen_audio.gd 合成（16-bit 单声道 22050Hz）。

const SFX_VOLUME := -7.0      # 音效基准音量
const BGM_VOLUME := -18.0     # BGM 刻意压低，做背景
const BGM_FADE := 0.8         # 交叉淡入淡出时长

const POOL_SIZE := 8

const BGM_PATHS: Array[String] = [
	"res://assets/audio/bgm.wav",
	"res://assets/audio/bgm2.wav",
]

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
var _bgm_index := -1
var _bgm_tracks: Array[AudioStreamWAV] = []

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.volume_db = SFX_VOLUME
		add_child(p)
		_pool.append(p)
	# 运行时加载 BGM（不 preload，避免素材还没生成时编译失败，见 ERROR.md #8）
	for path in BGM_PATHS:
		var s: AudioStreamWAV = load(path)
		if s != null:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = int(s.get_length() * s.mix_rate)
			_bgm_tracks.append(s)
	_bgm = AudioStreamPlayer.new()
	add_child(_bgm)
	_play_bgm(0)
	# 自己接管关窗流程，好在退出前停声（见下方 _notification 注释）
	get_tree().auto_accept_quit = false

## 退出期资源泄漏的处理（见 ERROR.md #9）：
## 直接退出时 AudioServer 里的 AudioStreamPlaybackWAV 还握着 wav 流，
## 资源缓存先于音频服务器清理 → 报「ObjectDB instances leaked at exit / resources still in use」。
## 所以：关窗请求先停声、松开流引用，给音频线程留一点时间再真正退出。
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			_graceful_quit()
		NOTIFICATION_EXIT_TREE:
			stop_all()
			if _bgm != null:
				_bgm.stream = null
			for p in _pool:
				p.stream = null
			# 直接 quit() 的路径（如 --quit-after）没有机会等下一帧，
			# 这里给音频线程一点时间真正释放 playback，否则仍会偶发"resources still in use"。
			# 实测：开发版 40ms 足够，而 release 导出版时序更紧，需要 150ms（退出多等这点时间玩家无感）
			OS.delay_msec(150)

func _graceful_quit() -> void:
	stop_all()
	if _bgm != null:
		_bgm.stream = null
	for p in _pool:
		p.stream = null
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

## 停掉所有声音（BGM + 音效池）。注意：AudioServer 需要走过一轮混音
## 才会真正释放 playback，所以调用后应至少等一帧再退出。
func stop_all() -> void:
	if _bgm != null:
		_bgm.stop()
	for p in _pool:
		p.stop()

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

## 播放指定索引的 BGM（带淡入）。循环点已在 _ready 里预设好。
func _play_bgm(index: int) -> void:
	if index < 0 or index >= _bgm_tracks.size():
		return
	_bgm_index = index
	_bgm.stream = _bgm_tracks[index]
	_bgm.volume_db = -40.0
	_bgm.play()
	var tw := create_tween()
	tw.tween_property(_bgm, "volume_db", BGM_VOLUME, 2.5)

## 交叉淡入淡出切换到指定 BGM；已在播放同一首则跳过。
func switch_bgm(index: int) -> void:
	if index < 0 or index >= _bgm_tracks.size():
		return
	if index == _bgm_index and _bgm != null and _bgm.playing:
		return
	if _bgm == null or not _bgm.playing:
		_play_bgm(index)
		return
	# 先淡出当前，再淡入新的
	var tw := create_tween()
	tw.tween_property(_bgm, "volume_db", -40.0, BGM_FADE)
	tw.tween_callback(func() -> void: _play_bgm(index))

## 返回当前播放的 BGM 索引（供测试断言用）
func current_bgm_index() -> int:
	return _bgm_index
