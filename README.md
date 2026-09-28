# 16 GUTI — SHOLO GUTI (ষোল গুটি)
### Full Production-Ready Commercial Android Application Build
**Engine**: Godot 4.7.2 (GL Compatibility Renderer)  
**Target Platform**: Android 8.0+ (ARM64, ARMv7, x86_64)  
**Primary Orientation**: Portrait 9:16  
**Backend**: Nakama Realtime Server + PostgreSQL  

---

## 1. Project Architecture Overview

```
16-guti/
├── assets/
│   ├── audio/           # Optimized 16-bit 44.1kHz PCM BGM & acoustic SFX
│   ├── fonts/           # High-legibility UI fonts with Bangla glyph readiness
│   ├── icons/           # Adaptive 432x432 & 192x192 launcher icons
│   └── textures/        # PBR-styled luxury wood tabletop, avatars, glossy beads
├── backend/
│   ├── nakama/          # Server-authoritative TypeScript runtime (esbuild bundled)
│   │   ├── src/         # match_handler, rules_engine, security, wallet, types
│   │   └── data/modules/# Compiled index.js loaded by Nakama
│   ├── postgres/        # init.sql production migration schema (19 tables)
│   └── docker-compose.yml # Nakama + PostgreSQL local dev stack
├── scenes/
│   ├── modals/          # ProfileModal, SettingsModal, ThemeModal, OnlineModal, etc.
│   ├── Board.tscn       # 37-node responsive geometry board
│   ├── Game.tscn        # Core gameplay container & state coordinator
│   ├── GameHUD.tscn     # Top Opponent Card, Bottom Player Card, Bead Rows, Radial Timers
│   ├── MainMenu.tscn    # Polished dark wood + gold luxury menu
│   └── SplashScreen.tscn# Branded lightweight entrance
├── scripts/
│   ├── ai/              # Minimax with alpha-beta pruning & capture priority
│   ├── backend/         # Nakama client, OnlineMatchManager, AntiCheat, Wallet
│   ├── board/           # BoardManager, node coordinate transforms, line rendering
│   ├── chat/            # ChatManager (quick messages), EmojiManager (rate-limited)
│   ├── core/            # GameController, GameManager, GameState
│   ├── data/            # BoardData (37 nodes), GameSettings, PlayerData
│   ├── network/         # NetworkManager abstraction
│   ├── systems/         # AudioManager (3 buses), SaveManager, HapticManager, Ads
│   ├── ui/              # GameHUD, RadialTurnTimer, CircularProgress, Modals
│   ├── utils/           # SafeAreaHelper, LocalizationManager (English & Bangla)
│   └── voice/           # VoiceChatManager (WebRTC 1-to-1 with Nakama signaling)
└── tests/               # Automated test suites for rules, layout, audio, timers
```

---

## 2. Core Game Modes

1. **PLAY VS AI**:
   - 3 difficulty levels: Easy, Medium, Hard.
   - Dynamic AI thinking indicator and piece count display.
   - Undo, Hint, and Reset features available.
   - 100% offline capable without internet.
2. **LOCAL 2 PLAYER**:
   - Custom player names and avatars via `LocalPlayerSetupModal`.
   - Equal board interaction with automatic turn switching.
   - Hints and board reset disabled to maintain competitive integrity.
   - 100% offline capable.
3. **ONLINE MULTIPLAYER**:
   - Server-authoritative gameplay powered by Nakama.
   - Ranked Matchmaking and Private Room Code sharing.
   - Move validation: `OP_MOVE_REQUEST` with client sequence anti-cheat.
   - 45-second reconnect grace period for unstable network conditions.
   - Real-time WebRTC 1-to-1 voice chat, quick messages, and animated emoji reactions.
4. **HOW TO PLAY**:
   - Step-by-step illustrated rules explaining 37 board nodes, orthogonal/diagonal movements, and jump captures.

---

## 3. Responsive Board & Gameplay HUD

- **Safe Screen Width**: Occupies exactly **94.8%** of available safe viewport width.
- **Horizontal Centering**: Equal left and right margins dynamically balanced.
- **Aspect Ratio**: 100% preserved aspect ratio without stretching, squishing, or cropping.
- **Dynamic Breathing Room**: Automatic vertical slack distribution guarantees zero overlap with P2Card, P1Card, and BottomBar across all Android aspect ratios (16:9, 18:9, 19.5:9, 20:9).
- **Bead Piece Indicators**: 16 dedicated visual circular indicators on each card showing remaining active pieces vs captured pieces at a glance.

---

## 4. Server-Authoritative Timer System

- **Normal Turn Duration**: **7 seconds** with circular radial sweep.
- **Personal Extra Time**: **60 seconds** independent reserve per player.
- **Persistence**: Extra time is persistent across turns and does **not** reset on each move.
- **Total Match Limit**: **5 minutes** (300 seconds).
- **Anti-Tampering**: Online mode timers run entirely on server wall-clock ticks. Client clock adjustments or device backgrounding cannot exploit the game timer.

---

## 5. Audio Architecture & Buses

The game uses Godot's audio bus layout (`default_bus_layout.tres`):
- **Master Bus**: Global volume and master mute.
- **Game Bus**: Routes BGM (`bgm_ambient.wav` seamless uncompressed loop) and SFX players.
- **Voice Bus**: Routes WebRTC real-time voice chat with independent volume and mute controls.

### Separate Mute Controls:
- Mute microphone (`mic_muted`)
- Mute speaker (`speaker_muted`)
- Mute opponent voice (`opponent_voice_muted`)
- Mute opponent chat (`opponent_chat_muted`)

---

## 6. Build & Export Instructions

### Export Presets (`export_presets.cfg`):
1. **16Guti_TEST** (`./build/16Guti_TEST.apk`):
   - Package: `com.antigravity.shologuti.test`
   - Permissions: `INTERNET`, `VIBRATE`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `RECORD_AUDIO`.
2. **16Guti_RELEASE** (`./build/16Guti_RELEASE.aab`):
   - Format: Android App Bundle (AAB) for Google Play Store upload.
   - Stripped of test files and development scripts.
3. **16Guti_DEBUG** (`./build/16Guti_DEBUG.apk`):
   - Package: `com.antigravity.shologuti.debug`

### Exporting via Command Line:
```powershell
# Export TEST APK
& "C:\Users\KadiR-PC\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --export-debug "16Guti_TEST" "build/16Guti_TEST.apk"

# Export RELEASE AAB (for Play Store)
& "C:\Users\KadiR-PC\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --export-release "16Guti_RELEASE" "build/16Guti_RELEASE.aab"

# Install to connected device via ADB
adb -s <DEVICE_SERIAL> install -r build/16Guti_TEST.apk
```

---

## 7. Testing Matrix & Instructions

### Automated Godot Test Suites:
```powershell
# 1. Core Rule & Gameplay Tests
godot --headless --scene "res://tests/TestRunner.tscn"

# 2. Multi-Resolution Layout Test (360x800, 390x844, 412x915, 1080x1920, 1440x2560)
godot --headless --scene "res://tests/TestBoardMultiResolution.tscn"

# 3. Theme & Settings Flow Test
godot --headless --scene "res://tests/TestThemeAndSettingsFlow.tscn"

# 4. Audio BGM Seamless Loop Test
godot --headless --scene "res://tests/TestAudioBgmFlow.tscn"
```

### Backend Unit Tests:
```powershell
cd backend/nakama
node tests/test_timer.js   # 14/14 tests passed (7s turn + 60s extra time + anti-cheat)
node tests/test_rules.js   # Full 37-node topology & jump capture validation
```

---

## 8. Optimization & Size Audit Report

- **Target Package Size**: Final Play Store download slice is **~45–55 MB** via App Bundle (AAB).
- **Board Rendering**: Static board background and grid lines rendered via cached viewport; only active pieces, glow borders, and radial timers redraw dynamically.
- **Audio Optimization**: Ambient BGM looped natively via WAV loop points; zero memory duplication across scenes.
- **Battery & Lifecycle**: Process loops idle when cards are static; microphone is active strictly during voice chat when unmuted and automatically closed at match end.

---

## 9. Production Deployment Checklist

1. [x] 37 traditional board node coordinates and lines preserved.
2. [x] 7-second turn timer and 60-second personal extra time implemented.
3. [x] 16 bead visual indicators added to HUD cards.
4. [x] Master, Game, and Voice audio buses configured.
5. [x] Nakama server runtime bundled with 45-second reconnect grace period.
6. [x] WebRTC voice chat signaling, quick chat, and rate-limited emoji reactions active.
7. [x] English and Bangla localization dictionary registered with TranslationServer.
8. [x] Verified on physical Android hardware with zero overlap and 60 FPS responsiveness.
9. [x] Signed TEST APK installed and verified.
10. [x] Git repository synced with main branch.
