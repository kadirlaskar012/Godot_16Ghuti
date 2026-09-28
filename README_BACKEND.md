# 16 GUTI (SHOLO GUTI) — COMPLETE BACKEND & SECURITY ARCHITECTURE

Welcome to the backend architecture for **16 GUTI — SHOLO GUTI**.
This backend provides a 100% server-authoritative multiplayer foundation, anti-cheat validation, cloud profile saves, transactional wallet, inventory, shop, rewards, and security auditing.

---

## 1. ARCHITECTURE OVERVIEW

```
  Android / PC Godot Client (4.7.2)
                 │
                 │ HTTPS (REST API) / WSS (Realtime Match Socket)
                 ▼
          Nakama Server 3.22.0 (Port 7350 HTTP / 7351 Console)
                 │
                 │ Internal Isolated Network
                 ▼
     PostgreSQL 15 Database (Internal Port 5432)
```

### Core Security Rules
1. **Never Trust the Client**: The Godot client sends only intent actions (`MOVE_REQUEST`, `PURCHASE`, `CLAIM_REWARD`). The Nakama server validates all rules, state transitions, timers, balances, and outcomes.
2. **Direct Database Isolation**: The client *never* connects directly to PostgreSQL. Only Nakama interacts with PostgreSQL.
3. **Provider-Independent**: Configured via environment variables so the system runs locally on free Docker today and migrates seamlessly to AWS Mumbai (`ap-south-1`) tomorrow without changing game code.
4. **Offline Resilience**: Offline modes (**VS AI** and **Local 2 Player**) remain 100% operational offline without requiring an active server connection.

---

## 2. PROJECT DIRECTORY STRUCTURE

```
16-guti/
├── backend/
│   ├── docker-compose.yml           # Local multi-container Docker orchestration
│   ├── .env                         # Active backend environment variables
│   ├── .env.example                 # Template for environment configuration
│   ├── postgres/
│   │   └── init.sql                 # Authoritative PostgreSQL schema & seed catalog
│   └── nakama/
│       ├── local.yml                # Nakama server runtime configuration
│       ├── package.json             # Runtime build dependencies
│       ├── build.js                 # Automated esbuild bundler script
│       ├── data/
│       │   └── modules/
│       │       └── index.js         # Compiled authoritative server runtime
│       ├── src/
│       │   ├── types.ts             # OpCodes, match states, interfaces
│       │   ├── rules_engine.ts      # Authoritative 37-node 16 Guti rules engine
│       │   ├── match_handler.ts     # 5-min match loop, reconnect grace, timer
│       │   ├── security.ts          # Anti-cheat, rate limiting, version check
│       │   ├── wallet.ts            # Atomic transactions & ledger idempotency
│       │   ├── inventory_shop.ts    # Shop catalog, purchases, equipping
│       │   ├── rewards.ts           # 7-day daily cycle, rewarded ads limit
│       │   ├── profile_stats.ts     # Cloud save, stats, match history
│       │   ├── matchmaking.ts       # 1v1 matchmaking, private room codes
│       │   └── main.ts              # Nakama module initializer & RPC registration
│       └── tests/
│           └── test_rules.js        # Automated server rules test runner
│
├── scenes/
│   ├── modals/
│   │   └── OnlineMultiplayerModal.tscn  # 1v1 Quick match & Private Room modal
│   └── debug/
│       └── DevDebugPanel.tscn           # Development debug & testing panel
│
└── scripts/
    ├── backend/
    │   ├── BackendConfig.gd         # Environment configuration (Dev/Staging/Prod)
    │   ├── BackendManager.gd        # Central gateway (Autoload singleton)
    │   ├── AuthManager.gd           # Guest/Device auth & session refresh
    │   ├── CloudSaveManager.gd      # Profile & settings cloud sync
    │   ├── WalletManager.gd         # Server-synced wallet balance
    │   ├── ShopManager.gd           # Server-validated cosmetic purchases
    │   ├── InventoryManager.gd      # Inventory & cosmetic equipping
    │   ├── DailyRewardManager.gd    # Server-time 7-day reward streak
    │   ├── AdsRewardManager.gd      # Rewarded ads server claim (5/day limit)
    │   ├── StatsManager.gd          # Verified lifetime statistics
    │   ├── MatchHistoryManager.gd   # Authoritative match history
    │   ├── AntiCheatManager.gd      # Move sequence tracker & version check
    │   ├── MatchmakingManager.gd    # 1v1 match search & private rooms
    │   ├── OnlineMatchManager.gd    # Realtime WebSocket match manager (Autoload)
    │   └── PurchaseManager.gd       # Google Play Billing verification foundation
    ├── debug/
    │   └── DevDebugPanel.gd         # Debug panel logic & real RTT ping
    └── ui/
        └── OnlineMultiplayerModal.gd# Matchmaking UI & Room Code logic
```

---

## 3. HOW TO START LOCAL BACKEND (DOCKER)

### Step 1: Install Docker Desktop
If Docker is not yet installed on your system:
1. Download Docker Desktop for Windows: [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)
2. Install with default WSL2 backend options and start Docker Desktop.

### Step 2: Start the Containers
Open a terminal in the `backend/` directory:
```bash
cd backend
docker compose up -d
```

### Step 3: Verify Running Services
Run:
```bash
docker compose ps
```
You should see:
- `nakama-postgres` on port `5432` (healthy)
- `nakama-server` on ports `7349` (gRPC), `7350` (HTTP/WS), `7351` (Developer Console) (healthy)

### Step 4: Access Nakama Developer Console
Open your browser and navigate to:
```
http://localhost:7351
```
- **Username**: `admin`
- **Password**: `password`

Here you can inspect active user accounts, wallets, matches, and storage records in real time.

---

## 4. HOW TO RUN & TEST IN GODOT

### Running the Client
Open Godot 4.7.2 and launch the project (or run `scenes/SplashScreen.tscn`).

1. **Offline Play**:
   - Tap **"PLAY VS AI"** or **"PASS & PLAY (LOCAL 2P)"**.
   - These offline modes execute 100% locally and work regardless of server state.

2. **Online Multiplayer**:
   - Tap **"PLAY ONLINE"** on the Main Menu.
   - The **Online Multiplayer Modal** opens.
   - Shows connection status and live measured latency.
   - Tap **"FIND MATCH"** for 1v1 matchmaking or **"CREATE PRIVATE ROOM"** to generate a 6-character room code (e.g. `GT4892`) to share with a friend.

3. **Development Debug Panel**:
   - In debug builds, a blue **"▼ DEV"** button appears in the top-right corner.
   - Tapping it opens the live diagnostic panel displaying:
     - Active Environment (`DEVELOPMENT`, `STAGING`, `PRODUCTION`)
     - Connection status & User ID
     - Real RTT Ping (e.g. `34 ms`)
     - Current Match ID
   - Interactive Test Buttons:
     - **Reconnect**: Tests device auth handshake
     - **Refresh Profile**: Loads authoritative cloud save
     - **Refresh Wallet**: Queries database wallet balance
     - **Test RPC**: Measures round-trip RPC execution time
     - **Clear Session**: Clears cached device token to simulate a clean install

---

## 5. REBUILDING NAKAMA RUNTIME MODULES

Whenever you modify server TypeScript modules in `backend/nakama/src/`:
Run the zero-dependency build script:
```bash
node backend/nakama/build.js
```
And run the server rules test suite:
```bash
node backend/nakama/tests/test_rules.js
```
Output:
```
=== RUNNING 16 GUTI SERVER RULES TESTS ===
Testing Board Topology & Rules...
✓ Starting setup node counts and symmetry verified (16 vs 16, 5 empty).
Testing graph symmetries...
✓ Center node 18 has full 8-way diagonal and orthogonal connectivity.
=== ALL SERVER TESTS PASSED SUCCESSFULLY! ===
```

Then restart Nakama container to reload modules:
```bash
cd backend
docker compose restart nakama
```

---

## 6. TESTING ANTI-CHEAT & SERVER AUTHORITY

| Test Case | How to Test | Expected Authoritative Result |
|---|---|---|
| **Moving Opponent Piece** | Client modifies packet `from` node to opponent's guti | Nakama rejects move with code `OP_MOVE_REJECTED` ("Piece does not belong to active player"). Suspicion score recorded. |
| **Moving Out of Turn** | Player attempts move during opponent's turn | Rejected with `OP_MOVE_REJECTED` ("Not your turn"). |
| **Invalid Trajectory** | Non-adjacent step or illegal jump | Rejected with `OP_MOVE_REJECTED` ("Invalid jump trajectory"). |
| **5-Minute Server Timer** | Elapsed time reaches 300s | Server broadcasts `OP_MATCH_OVER` with `end_reason = TIME_UP`. Game locks. |
| **Duplicate Move Attack** | Client replays move with same or old sequence number | Server rejects replay attempt and logs event in `security_events`. |
| **Clock/Date Tampering** | Changing device clock forward 2 days | Daily reward still checks PostgreSQL `last_claimed_at` server timestamp; claim rejected until 20h server elapsed. |
| **Daily Ad Limit** | Attempting 6th rewarded ad claim in one day | Server returns "Daily rewarded ad limit (5) reached". |
| **Insufficient Coins Purchase** | Attempting to buy 2000-coin skin with 100 coins | Server returns "Insufficient coin balance". Database balance untouched. |

---

## 7. DATABASE MANAGEMENT & RESET

### Resetting Development Database
To purge all development matches, test wallets, and test accounts:
```bash
cd backend
docker compose down -v
docker compose up -d
```
The `-v` flag removes the `nakama-postgres-data` volume, causing PostgreSQL to automatically re-run `postgres/init.sql` on startup.

---

## 8. AWS MUMBAI (ap-south-1) PRODUCTION DEPLOYMENT BLUEPRINT

When transitioning from local Docker development to AWS Mumbai:

### AWS Architecture
```
                         AWS Cloud (ap-south-1 Mumbai)
┌────────────────────────────────────────────────────────────────────────┐
│                                                                        │
│   Internet ──► AWS Route 53 (api.16guti.games)                         │
│                    │                                                   │
│                    ▼                                                   │
│       Application Load Balancer (ALB) [HTTPS:443 / WSS]                │
│                    │                                                   │
│       ┌────────────┴────────────┐                                      │
│       ▼                         ▼                                      │
│  ECS Fargate Task 1        ECS Fargate Task 2 (Auto-scaling)           │
│  (Nakama Server)           (Nakama Server)                             │
│       │                         │                                      │
│       └────────────┬────────────┘                                      │
│                    ▼ (Private Subnet)                                  │
│     Amazon RDS for PostgreSQL 15 (Multi-AZ in ap-south-1)              │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Steps to Deploy:
1. **Provision Amazon RDS PostgreSQL**:
   - Region: `ap-south-1` (Mumbai).
   - Engine: PostgreSQL 15.
   - Subnets: Private DB subnets (no public IP).
   - Security Group: Allow port 5432 inbound **only** from the Nakama ECS Security Group.
   - Run `backend/postgres/init.sql` using AWS Secrets Manager or Bastion host.

2. **Containerize Nakama**:
   - Push your custom Nakama image (containing compiled `data/modules/index.js`) to AWS Elastic Container Registry (ECR).
   - Tag: `[account-id].dkr.ecr.ap-south-1.amazonaws.com/16guti-nakama:latest`.

3. **Deploy via AWS ECS Fargate**:
   - Create ECS Service with ALB target group on port `7350`.
   - Configure AWS Secrets Manager for `POSTGRES_PASSWORD` and Nakama encryption keys.
   - Set environment variables:
     - `GAME_DURATION_SEC=300`
     - `MAX_REWARDED_ADS=5`
     - `MIN_CLIENT_VERSION=1.0.0`

4. **Switch Godot Client to Production**:
   - In `scripts/backend/BackendConfig.gd`:
     Change:
     ```gdscript
     const CURRENT_ENV: int = ServerEnv.PRODUCTION
     ```
   - Build signed Android release APK. Zero code modifications required!
