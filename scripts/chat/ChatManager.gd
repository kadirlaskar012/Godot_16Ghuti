extends Node

## ChatManager
## Real-time in-match quick chat messages.
## Zero permanent message retention, fully decoupled from board logic.

signal message_received(sender_name: String, message_text: String)
signal message_sent(message_text: String)

const QUICK_MESSAGES: Array[String] = [
	"Good move!",
	"Nice!",
	"Well played!",
	"Good game!",
	"Wow!",
	"Oops!",
	"Great!",
	"GG!",
	"Hurry up!",
	"Amazing!"
]

var _online_manager: Node
var _last_sent_time: float = 0.0
const SEND_COOLDOWN_SEC: float = 1.0

func _ready() -> void:
	_online_manager = get_node_or_null("/root/OnlineMatchManager")
	if _online_manager and _online_manager.has_signal("chat_received"):
		_online_manager.chat_received.connect(_on_chat_received)

func send_quick_message(message_text: String) -> bool:
	var now = Time.get_ticks_msec() / 1000.0
	if now - _last_sent_time < SEND_COOLDOWN_SEC:
		return false # Cooldown active
		
	_last_sent_time = now
	if _online_manager and _online_manager.has_method("send_chat_message"):
		_online_manager.send_chat_message(message_text)
		message_sent.emit(message_text)
		return true
	return false

func _on_chat_received(sender_name: String, message_text: String) -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.settings and sm.settings.opponent_chat_muted:
		return # Opponent chat is muted
		
	message_received.emit(sender_name, message_text)
