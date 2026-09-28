extends Node

## EmojiManager
## Real-time in-match emoji reactions with client rate-limiting (max 3/sec).
## Triggers floating reaction animations above player/opponent avatars.

signal emoji_triggered(player_id: int, emoji_symbol: String)

const EMOJIS: Array[String] = [
	"😀", "😂", "😎", "😮", "😅", "👍", "👏", "🔥", "❤️", "😭", "🎉", "🤔", "😱"
]

var _online_manager: Node
var _recent_timestamps: Array[float] = []
const MAX_EMOJIS_PER_SECOND: int = 3

func _ready() -> void:
	_online_manager = get_node_or_null("/root/OnlineMatchManager")
	if _online_manager and _online_manager.has_signal("emoji_received"):
		_online_manager.emoji_received.connect(_on_emoji_received)

func send_emoji(emoji_symbol: String) -> bool:
	var now = Time.get_ticks_msec() / 1000.0
	
	# Clean timestamps older than 1 second
	var valid_stamps: Array[float] = []
	for t in _recent_timestamps:
		if now - t < 1.0:
			valid_stamps.append(t)
	_recent_timestamps = valid_stamps
	
	# Rate-limit check (max 3 per second)
	if _recent_timestamps.size() >= MAX_EMOJIS_PER_SECOND:
		return false
		
	_recent_timestamps.append(now)
	
	var local_p = _online_manager.local_player_index if _online_manager else BoardData.Player.PLAYER_1
	emoji_triggered.emit(local_p, emoji_symbol)
	
	if _online_manager and _online_manager.has_method("send_emoji_reaction"):
		_online_manager.send_emoji_reaction(emoji_symbol)
		
	return true

func _on_emoji_received(player_id: int, emoji_symbol: String) -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.settings and sm.settings.opponent_chat_muted:
		return
		
	emoji_triggered.emit(player_id, emoji_symbol)
