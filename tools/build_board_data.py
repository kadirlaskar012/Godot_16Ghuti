import os
import json

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "scripts", "data")
os.makedirs(DATA_DIR, exist_ok=True)

# 37 Nodes definition with (col, row)
# col: 0 to 4, row: 0 to 8
NODES = [
    # Row 0 (top triangle base)
    (0, 0), (2, 0), (4, 0),                # 0, 1, 2
    # Row 1 (top triangle mid)
    (1, 1), (2, 1), (3, 1),                # 3, 4, 5
    # Row 2 (5x5 row 0 / top apex)
    (0, 2), (1, 2), (2, 2), (3, 2), (4, 2), # 6, 7, 8, 9, 10
    # Row 3 (5x5 row 1)
    (0, 3), (1, 3), (2, 3), (3, 3), (4, 3), # 11, 12, 13, 14, 15
    # Row 4 (5x5 row 2 - center row)
    (0, 4), (1, 4), (2, 4), (3, 4), (4, 4), # 16, 17, 18, 19, 20
    # Row 5 (5x5 row 3)
    (0, 5), (1, 5), (2, 5), (3, 5), (4, 5), # 21, 22, 23, 24, 25
    # Row 6 (5x5 row 4 / bottom apex)
    (0, 6), (1, 6), (2, 6), (3, 6), (4, 6), # 26, 27, 28, 29, 30
    # Row 7 (bottom triangle mid)
    (1, 7), (2, 7), (3, 7),                # 31, 32, 33
    # Row 8 (bottom triangle base)
    (0, 8), (2, 8), (4, 8),                # 34, 35, 36
]

assert len(NODES) == 37, f"Expected 37 nodes, got {len(NODES)}"

# Full straight lines
LINES = [
    # Horizontals
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8, 9, 10],
    [11, 12, 13, 14, 15],
    [16, 17, 18, 19, 20],
    [21, 22, 23, 24, 25],
    [26, 27, 28, 29, 30],
    [31, 32, 33],
    [34, 35, 36],
    
    # Verticals
    [1, 4, 8, 13, 18, 23, 28, 32, 35], # Spine (col 2)
    [6, 11, 16, 21, 26],                # Col 0
    [7, 12, 17, 22, 27],                # Col 1
    [9, 14, 19, 24, 29],                # Col 3
    [10, 15, 20, 25, 30],               # Col 4
    
    # Diagonals (down-right / up-left)
    [0, 3, 8, 14, 20],                  # From (0,0) to (4,4)
    [16, 22, 28, 33, 36],               # From (0,4) to (4,8)
    [6, 12, 18, 24, 30],                # 5x5 main diagonal
    [7, 13, 19, 25],                    # 5x5 secondary
    [9, 15],                            # 5x5 corner
    [11, 17, 23, 29],                   # 5x5 secondary
    [21, 27],                           # 5x5 corner
    
    # Diagonals (down-left / up-right)
    [2, 5, 8, 12, 16],                  # From (4,0) to (0,4)
    [20, 24, 28, 31, 34],               # From (4,4) to (0,8)
    [10, 14, 18, 22, 26],               # 5x5 main diagonal
    [9, 13, 17, 21],                    # 5x5 secondary
    [7, 11],                            # 5x5 corner
    [15, 19, 23, 27],                   # 5x5 secondary
    [25, 29],                           # 5x5 corner
]

# Build adjacency graph
adj = {i: set() for i in range(37)}
# Build jump map: jump_map[from_node][jumped_node] = to_node
jumps = {}

for line in LINES:
    for i in range(len(line) - 1):
        u, v = line[i], line[i+1]
        adj[u].add(v)
        adj[v].add(u)
    # Jumps along straight line
    for i in range(len(line) - 2):
        u, mid, w = line[i], line[i+1], line[i+2]
        jumps.setdefault(u, {})[mid] = w
        jumps.setdefault(w, {})[mid] = u

# Convert adj sets to sorted lists
adj_list = {i: sorted(list(adj[i])) for i in range(37)}

print(f"Total nodes: {len(NODES)}")
print(f"Total lines: {len(LINES)}")
total_edges = sum(len(neighbors) for neighbors in adj_list.values()) // 2
print(f"Total undirected edges: {total_edges}")
total_jumps = sum(len(sub) for sub in jumps.values())
print(f"Total jump paths: {total_jumps}")

# Generate GDScript BoardData.gd
gdscript = f"""class_name BoardData
extends RefCounted

## Pure Board Data & Topology for 16 Guti / Sholo Guti
## Contains exact 37-node graph, straight lines, jump table, and starting setup.

enum Player {{
	NONE = 0,
	PLAYER_1 = 1, # Red pieces
	PLAYER_2 = 2  # Ivory pieces
}}

const TOTAL_NODES: int = 37
const PIECES_PER_PLAYER: int = 16

# Starting node index assignments
const P1_START_NODES: Array[int] = [
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
]

const EMPTY_START_NODES: Array[int] = [
	16, 17, 18, 19, 20
]

const P2_START_NODES: Array[int] = [
	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36
]

# Coordinates in normalized board space (col: 0..4, row: 0..8)
const NODE_COORDINATES: Array[Vector2i] = [
"""
for idx, (c, r) in enumerate(NODES):
    gdscript += f"\tVector2i({c}, {r}), # Node {idx}\n"
gdscript += """]

# Adjacency List: node_id -> Array[int]
const ADJACENCY: Dictionary = {
"""
for idx in range(37):
    gdscript += f"\t{idx}: {adj_list[idx]},\n"
gdscript += """}

# Precalculated Jump Table:
# jump_map[from_node][jumped_node] = landing_node
# All jumps are guaranteed along straight drawn board lines.
const JUMP_TABLE: Dictionary = {
"""
for u in sorted(jumps.keys()):
    gdscript += f"\t{u}: {jumps[u]},\n"
gdscript += """}

# Human-readable identifiers for debug / inspector
static func get_node_name(node_id: int) -> String:
	return "NODE_%02d" % node_id

# Startup validation to guarantee 16 vs 16 setup
static func validate_startup_configuration() -> bool:
	if P1_START_NODES.size() != PIECES_PER_PLAYER:
		push_error("Invalid P1 start count: %d (expected 16)" % P1_START_NODES.size())
		return false
	if P2_START_NODES.size() != PIECES_PER_PLAYER:
		push_error("Invalid P2 start count: %d (expected 16)" % P2_START_NODES.size())
		return false
	if EMPTY_START_NODES.size() != (TOTAL_NODES - PIECES_PER_PLAYER * 2):
		push_error("Invalid empty start count: %d (expected 5)" % EMPTY_START_NODES.size())
		return false
	
	# Check for overlaps
	var seen: Dictionary = {}
	for n in P1_START_NODES:
		if seen.has(n):
			push_error("Duplicate node in P1 start: %d" % n)
			return false
		seen[n] = true
	for n in P2_START_NODES:
		if seen.has(n):
			push_error("Duplicate node in P2 start: %d" % n)
			return false
		seen[n] = true
	for n in EMPTY_START_NODES:
		if seen.has(n):
			push_error("Duplicate node in empty start: %d" % n)
			return false
		seen[n] = true
		
	if seen.size() != TOTAL_NODES:
		push_error("Startup configuration does not cover all 37 nodes!")
		return false
		
	return true

# Get straight lines for rendering board geometry
static func get_all_lines() -> Array:
	return [
"""
for line in LINES:
    gdscript += f"\t\t{line},\n"
gdscript += """	]
"""

with open(os.path.join(DATA_DIR, "BoardData.gd"), "w", encoding="utf-8") as f:
    f.write(gdscript)
print("Saved BoardData.gd successfully!")
