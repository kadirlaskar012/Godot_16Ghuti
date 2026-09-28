class_name PlayerData
extends RefCounted

## Player Profile, Lifetime Statistics, Cosmetics, and Progression System

var player_name: String = "Player 1"
var player_id: String = ""
var avatar_index: int = 0 # 0: P1 crest, 1: P2 star, 2: AI bot, 3: Crown, 4: Tiger, 5: Warrior
var coins: int = 500
var xp: int = 320
var hints_remaining: int = 3

# Statistics
var games_played: int = 0
var games_won: int = 0
var games_lost: int = 0
var games_draw: int = 0
var total_captures: int = 0
var win_streak: int = 0
var best_win_streak: int = 0
var ai_easy_wins: int = 0
var ai_medium_wins: int = 0
var ai_hard_wins: int = 0
var total_play_time_seconds: float = 0.0

# Customization ("My Style")
var equipped_guti: String = "Classic Red"
var equipped_board: String = "Classic Wood"
var equipped_victory: String = "Classic Sparkle"
var equipped_effect: String = "classic_gold"

# Unlocked cosmetics
var unlocked_themes: Array[String] = ["classic_wood"]
var unlocked_pieces: Array[String] = ["glossy_classic"]
var unlocked_effects: Array[String] = ["classic_gold"]

# Match history (latest 5 matches)
var recent_matches: Array[Dictionary] = []

func _init() -> void:
	if player_id.is_empty():
		player_id = _generate_player_id()

func _generate_player_id() -> String:
	return "#G%05d" % (randi() % 90000 + 10000)

const AVATAR_NAMES: Array[String] = [
	"Warrior",
	"King",
	"Queen",
	"Samurai",
	"Knight",
	"Royal Prince",
	"Royal Princess",
	"Mystic Player"
]

## Data-driven Level and XP calculation
static func get_level_info(total_xp: int) -> Dictionary:
	var current_lvl: int = 1
	var accumulated_xp: int = 0
	var needed_for_next: int = 500
	
	while total_xp >= accumulated_xp + needed_for_next:
		accumulated_xp += needed_for_next
		current_lvl += 1
		needed_for_next = 500 + (current_lvl - 1) * 250
		
	var current_lvl_xp: int = total_xp - accumulated_xp
	return {
		"level": current_lvl,
		"current_xp": current_lvl_xp,
		"max_xp": needed_for_next,
		"xp_to_next": maxi(0, needed_for_next - current_lvl_xp),
		"progress": clampf(float(current_lvl_xp) / float(needed_for_next), 0.0, 1.0)
	}

func get_win_rate() -> float:
	if games_played <= 0:
		return 0.0
	return (float(games_won) / float(games_played)) * 100.0

func to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"player_id": player_id,
		"avatar_index": avatar_index,
		"coins": coins,
		"xp": xp,
		"hints_remaining": hints_remaining,
		"games_played": games_played,
		"games_won": games_won,
		"games_lost": games_lost,
		"games_draw": games_draw,
		"total_captures": total_captures,
		"win_streak": win_streak,
		"best_win_streak": best_win_streak,
		"ai_easy_wins": ai_easy_wins,
		"ai_medium_wins": ai_medium_wins,
		"ai_hard_wins": ai_hard_wins,
		"total_play_time_seconds": total_play_time_seconds,
		"equipped_guti": equipped_guti,
		"equipped_board": equipped_board,
		"equipped_victory": equipped_victory,
		"equipped_effect": equipped_effect,
		"unlocked_themes": unlocked_themes,
		"unlocked_pieces": unlocked_pieces,
		"unlocked_effects": unlocked_effects,
		"recent_matches": recent_matches
	}

func from_dict(d: Dictionary) -> void:
	player_name = d.get("player_name", "Player 1")
	player_id = d.get("player_id", "")
	if player_id.is_empty():
		player_id = _generate_player_id()
	avatar_index = d.get("avatar_index", 0)
	coins = d.get("coins", 500)
	xp = d.get("xp", 320)
	hints_remaining = d.get("hints_remaining", 3)
	games_played = d.get("games_played", 0)
	games_won = d.get("games_won", 0)
	games_lost = d.get("games_lost", 0)
	games_draw = d.get("games_draw", 0)
	total_captures = d.get("total_captures", 0)
	win_streak = d.get("win_streak", 0)
	best_win_streak = d.get("best_win_streak", 0)
	ai_easy_wins = d.get("ai_easy_wins", 0)
	ai_medium_wins = d.get("ai_medium_wins", 0)
	ai_hard_wins = d.get("ai_hard_wins", 0)
	total_play_time_seconds = d.get("total_play_time_seconds", 0.0)
	
	equipped_guti = d.get("equipped_guti", "Classic Red")
	equipped_board = d.get("equipped_board", "Classic Wood")
	equipped_victory = d.get("equipped_victory", "Classic Sparkle")
	equipped_effect = d.get("equipped_effect", "classic_gold")
	
	var themes_raw = d.get("unlocked_themes", ["classic_wood"])
	unlocked_themes.clear()
	for item in themes_raw:
		unlocked_themes.append(str(item))
		
	var pieces_raw = d.get("unlocked_pieces", ["glossy_classic"])
	unlocked_pieces.clear()
	for item in pieces_raw:
		unlocked_pieces.append(str(item))
		
	var effects_raw = d.get("unlocked_effects", ["classic_gold"])
	unlocked_effects.clear()
	for item in effects_raw:
		unlocked_effects.append(str(item))
		
	var rm_raw = d.get("recent_matches", [])
	recent_matches.clear()
	for item in rm_raw:
		if item is Dictionary:
			recent_matches.append(item)

func record_win(difficulty: int = -1, match_captures: int = 0, duration: float = 0.0, opponent_name: String = "AI Bot", mode_name: String = "VS AI") -> void:
	games_played += 1
	games_won += 1
	total_captures += match_captures
	total_play_time_seconds += duration
	win_streak += 1
	if win_streak > best_win_streak:
		best_win_streak = win_streak
	coins += 50
	xp += 100 + match_captures * 10
	
	if difficulty == AIManager.Difficulty.EASY:
		ai_easy_wins += 1
	elif difficulty == AIManager.Difficulty.MEDIUM:
		ai_medium_wins += 1
	elif difficulty == AIManager.Difficulty.HARD:
		ai_hard_wins += 1
		coins += 50 # Hard bonus
		xp += 50
		
	_push_recent_match(opponent_name, mode_name, "WIN", duration)

func record_loss(match_captures: int = 0, duration: float = 0.0, opponent_name: String = "AI Bot", mode_name: String = "VS AI") -> void:
	games_played += 1
	games_lost += 1
	total_captures += match_captures
	total_play_time_seconds += duration
	win_streak = 0
	coins += 10
	xp += 25 + match_captures * 10
	_push_recent_match(opponent_name, mode_name, "LOSS", duration)

func record_draw(match_captures: int = 0, duration: float = 0.0, opponent_name: String = "Player 2", mode_name: String = "LOCAL 2P") -> void:
	games_played += 1
	games_draw += 1
	total_captures += match_captures
	total_play_time_seconds += duration
	coins += 20
	xp += 50 + match_captures * 10
	_push_recent_match(opponent_name, mode_name, "DRAW", duration)

func _push_recent_match(opponent: String, mode: String, result: String, duration: float) -> void:
	var dur_str = "%02d:%02d" % [int(duration) / 60, int(duration) % 60]
	var d_dict = Time.get_date_dict_from_system()
	var date_str = "%04d-%02d-%02d" % [d_dict["year"], d_dict["month"], d_dict["day"]]
	recent_matches.push_front({
		"opponent": opponent,
		"mode": mode,
		"result": result,
		"duration": dur_str,
		"date": date_str
	})
	while recent_matches.size() > 5:
		recent_matches.pop_back()
