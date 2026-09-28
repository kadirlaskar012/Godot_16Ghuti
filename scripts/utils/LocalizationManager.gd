class_name LocalizationManager
extends RefCounted

## LocalizationManager
## High-performance translation registry for English ("en") and Bangla ("bn").
## Integrated directly with Godot's TranslationServer so tr("KEY") resolves instantly.

const STRINGS_EN: Dictionary = {
	"APP_NAME": "16 GUTI",
	"APP_SUBTITLE": "SHOLO GUTI",
	"MENU_PLAY_VS_AI": "PLAY VS AI",
	"MENU_LOCAL_2P": "LOCAL 2 PLAYER",
	"MENU_ONLINE_MP": "ONLINE MULTIPLAYER",
	"MENU_HOW_TO_PLAY": "HOW TO PLAY",
	"MENU_SETTINGS": "SETTINGS",
	"MENU_PROFILE": "PROFILE",
	
	"HUD_YOUR_TURN": "YOUR TURN",
	"HUD_WAITING": "WAITING...",
	"HUD_AI_THINKING": "AI IS THINKING...",
	"HUD_EXTRA_TIME": "EXTRA TIME",
	"HUD_GUTI_COUNT": "%d Guti",
	"HUD_MENU": "MENU",
	"HUD_THEME": "THEME",
	"HUD_UNDO": "UNDO",
	"HUD_HINT": "HINT",
	"HUD_RESET": "RESET",
	
	"SETTINGS_TITLE": "SETTINGS",
	"SETTINGS_SOUND": "Sound Effects",
	"SETTINGS_MUSIC": "Background Music",
	"SETTINGS_VOICE": "Voice Chat",
	"SETTINGS_HAPTICS": "Haptic Vibration",
	"SETTINGS_FORCED_CAPTURE": "Compulsory Capture",
	"SETTINGS_TIMER": "Match Timer",
	"SETTINGS_DIFFICULTY": "AI Difficulty",
	"SETTINGS_LANGUAGE": "Language",
	"SETTINGS_CLOSE": "SAVE & CLOSE",
	
	"CHAT_GOOD_MOVE": "Good move!",
	"CHAT_NICE": "Nice!",
	"CHAT_WELL_PLAYED": "Well played!",
	"CHAT_GOOD_GAME": "Good game!",
	"CHAT_WOW": "Wow!",
	"CHAT_OOPS": "Oops!",
	"CHAT_GREAT": "Great!",
	"CHAT_GG": "GG!",
	"CHAT_HURRY_UP": "Hurry up!",
	"CHAT_AMAZING": "Amazing!",
	
	"RESULT_VICTORY": "VICTORY!",
	"RESULT_DEFEAT": "DEFEAT",
	"RESULT_DRAW": "DRAW MATCH",
	"RESULT_REMATCH": "REMATCH",
	"RESULT_MAIN_MENU": "MAIN MENU"
}

const STRINGS_BN: Dictionary = {
	"APP_NAME": "১৬ গুটি",
	"APP_SUBTITLE": "ষোল গুটি",
	"MENU_PLAY_VS_AI": "এআই এর সাথে খেলুন",
	"MENU_LOCAL_2P": "লোকাল ২ জন খেলোয়াড়",
	"MENU_ONLINE_MP": "অনলাইন মাল্টিপ্লেয়ার",
	"MENU_HOW_TO_PLAY": "কীভাবে খেলতে হয়",
	"MENU_SETTINGS": "সেটিংস",
	"MENU_PROFILE": "প্রোফাইল",
	
	"HUD_YOUR_TURN": "আপনার চাল",
	"HUD_WAITING": "অপেক্ষা করছে...",
	"HUD_AI_THINKING": "এআই চিন্তা করছে...",
	"HUD_EXTRA_TIME": "অতিরিক্ত সময়",
	"HUD_GUTI_COUNT": "%d গুটি",
	"HUD_MENU": "মেনু",
	"HUD_THEME": "থিম",
	"HUD_UNDO": "পূর্বাবস্থায়",
	"HUD_HINT": "ইঙ্গিত",
	"HUD_RESET": "পুনরায় শুরু",
	
	"SETTINGS_TITLE": "সেটিংস",
	"SETTINGS_SOUND": "শব্দ প্রভাব",
	"SETTINGS_MUSIC": "পটভূমির সঙ্গীত",
	"SETTINGS_VOICE": "ভয়েস চ্যাট",
	"SETTINGS_HAPTICS": "কম্পন",
	"SETTINGS_FORCED_CAPTURE": "বাধ্যতামূলক গুটি খাওয়া",
	"SETTINGS_TIMER": "ম্যাচ টাইমার",
	"SETTINGS_DIFFICULTY": "এআই স্তর",
	"SETTINGS_LANGUAGE": "ভাষা",
	"SETTINGS_CLOSE": "সংরক্ষণ ও বন্ধ",
	
	"CHAT_GOOD_MOVE": "ভালো চাল!",
	"CHAT_NICE": "চমৎকার!",
	"CHAT_WELL_PLAYED": "দারুণ খেলেছেন!",
	"CHAT_GOOD_GAME": "ভালো খেলা!",
	"CHAT_WOW": "বাহ!",
	"CHAT_OOPS": "উফ!",
	"CHAT_GREAT": "দুর্দান্ত!",
	"CHAT_GG": "ভালো খেলা!",
	"CHAT_HURRY_UP": "তাড়াতাড়ি করুন!",
	"CHAT_AMAZING": "অসাধারণ!",
	
	"RESULT_VICTORY": "জয়!",
	"RESULT_DEFEAT": "পরাজয়",
	"RESULT_DRAW": "ড্র ম্যাচ",
	"RESULT_REMATCH": "পুনরায় খেলা",
	"RESULT_MAIN_MENU": "মূল মেনু"
}

static var _initialized: bool = false

static func setup_localization(initial_lang: String = "en") -> void:
	if _initialized:
		return
	_initialized = true
	
	var trans_en = Translation.new()
	trans_en.locale = "en"
	for k in STRINGS_EN.keys():
		trans_en.add_message(k, STRINGS_EN[k])
	TranslationServer.add_translation(trans_en)
	
	var trans_bn = Translation.new()
	trans_bn.locale = "bn"
	for k in STRINGS_BN.keys():
		trans_bn.add_message(k, STRINGS_BN[k])
	TranslationServer.add_translation(trans_bn)
	
	set_language(initial_lang)

static func set_language(lang_code: String) -> void:
	if lang_code != "bn" and lang_code != "en":
		lang_code = "en"
	TranslationServer.set_locale(lang_code)
