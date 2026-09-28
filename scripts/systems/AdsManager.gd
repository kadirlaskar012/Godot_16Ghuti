extends Node

## AdsManager Singleton
## Clean AdMob architecture wrapper with signal callbacks and safe mock fallbacks.

signal rewarded_video_loaded
signal rewarded_video_failed_to_load(error_code)
signal rewarded_video_opened
signal rewarded_video_closed
signal user_earned_reward(currency, amount)
signal interstitial_loaded
signal interstitial_closed

const TEST_INTERSTITIAL_ID: String = "ca-app-pub-3940256099942544/1033173712"
const TEST_REWARDED_ID: String = "ca-app-pub-3940256099942544/5224354917"

var is_initialized: bool = false
var _rewarded_ready: bool = true
var _interstitial_ready: bool = true

func _ready() -> void:
	initialize_ads()

func initialize_ads() -> void:
	is_initialized = true
	# In actual Android export with godot-admob plugin, initialize the plugin here
	# For development and fallback, simulate ready state
	_rewarded_ready = true
	_interstitial_ready = true
	print("[AdsManager] AdMob initialized with test IDs.")

func is_rewarded_available() -> bool:
	return is_initialized and _rewarded_ready

func show_rewarded(reward_type: String = "hint") -> void:
	if not is_rewarded_available():
		push_warning("[AdsManager] Rewarded ad not ready.")
		return
		
	print("[AdsManager] Showing rewarded ad for %s..." % reward_type)
	rewarded_video_opened.emit()
	
	# Simulate ad watching duration (0.5s for seamless mock experience)
	var tree = get_tree()
	if tree:
		tree.create_timer(0.5).timeout.connect(func():
			var amount: int = 1
			if reward_type == "coins":
				amount = 100
			elif reward_type == "hint":
				amount = 1
			user_earned_reward.emit(reward_type, amount)
			rewarded_video_closed.emit()
			print("[AdsManager] User earned reward: %s x%d" % [reward_type, amount])
		)

func show_interstitial() -> void:
	if not is_initialized or not _interstitial_ready:
		return
		
	print("[AdsManager] Showing interstitial after match.")
	var tree = get_tree()
	if tree:
		tree.create_timer(0.3).timeout.connect(func():
			interstitial_closed.emit()
		)
