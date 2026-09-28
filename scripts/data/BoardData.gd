class_name BoardData
extends RefCounted

## Pure Board Data & Topology for 16 Guti / Sholo Guti
## Contains exact 37-node graph, straight lines, jump table, and starting setup.

enum Player {
	NONE = 0,
	PLAYER_1 = 1, # Red pieces
	PLAYER_2 = 2  # Ivory pieces
}

const TOTAL_NODES: int = 37
const PIECES_PER_PLAYER: int = 16

const BOARD_CENTER: Vector2 = Vector2(540, 960)
const CELL_DX: float = 170.0
const CELL_DY: float = 135.0

static func get_node_position(col: int, row: int) -> Vector2:
	var x = BOARD_CENTER.x + (float(col) - 2.0) * CELL_DX
	var y = BOARD_CENTER.y + (float(row) - 4.0) * CELL_DY
	return Vector2(x, y)

# Starting node index assignments
const P1_START_NODES: Array[int] = [
	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36
]

const EMPTY_START_NODES: Array[int] = [
	16, 17, 18, 19, 20
]

const P2_START_NODES: Array[int] = [
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
]

# Coordinates in normalized board space (col: 0..4, row: 0..8)
const NODE_COORDINATES: Array[Vector2i] = [
	Vector2i(0, 0), # Node 0
	Vector2i(2, 0), # Node 1
	Vector2i(4, 0), # Node 2
	Vector2i(1, 1), # Node 3
	Vector2i(2, 1), # Node 4
	Vector2i(3, 1), # Node 5
	Vector2i(0, 2), # Node 6
	Vector2i(1, 2), # Node 7
	Vector2i(2, 2), # Node 8
	Vector2i(3, 2), # Node 9
	Vector2i(4, 2), # Node 10
	Vector2i(0, 3), # Node 11
	Vector2i(1, 3), # Node 12
	Vector2i(2, 3), # Node 13
	Vector2i(3, 3), # Node 14
	Vector2i(4, 3), # Node 15
	Vector2i(0, 4), # Node 16
	Vector2i(1, 4), # Node 17
	Vector2i(2, 4), # Node 18
	Vector2i(3, 4), # Node 19
	Vector2i(4, 4), # Node 20
	Vector2i(0, 5), # Node 21
	Vector2i(1, 5), # Node 22
	Vector2i(2, 5), # Node 23
	Vector2i(3, 5), # Node 24
	Vector2i(4, 5), # Node 25
	Vector2i(0, 6), # Node 26
	Vector2i(1, 6), # Node 27
	Vector2i(2, 6), # Node 28
	Vector2i(3, 6), # Node 29
	Vector2i(4, 6), # Node 30
	Vector2i(1, 7), # Node 31
	Vector2i(2, 7), # Node 32
	Vector2i(3, 7), # Node 33
	Vector2i(0, 8), # Node 34
	Vector2i(2, 8), # Node 35
	Vector2i(4, 8), # Node 36
]

# Adjacency List: node_id -> Array[int]
const ADJACENCY: Dictionary = {
	0: [1, 3],
	1: [0, 2, 4],
	2: [1, 5],
	3: [0, 4, 8],
	4: [1, 3, 5, 8],
	5: [2, 4, 8],
	6: [7, 11, 12],
	7: [6, 8, 11, 12, 13],
	8: [3, 4, 5, 7, 9, 12, 13, 14],
	9: [8, 10, 13, 14, 15],
	10: [9, 14, 15],
	11: [6, 7, 12, 16, 17],
	12: [6, 7, 8, 11, 13, 16, 17, 18],
	13: [7, 8, 9, 12, 14, 17, 18, 19],
	14: [8, 9, 10, 13, 15, 18, 19, 20],
	15: [9, 10, 14, 19, 20],
	16: [11, 12, 17, 21, 22],
	17: [11, 12, 13, 16, 18, 21, 22, 23],
	18: [12, 13, 14, 17, 19, 22, 23, 24],
	19: [13, 14, 15, 18, 20, 23, 24, 25],
	20: [14, 15, 19, 24, 25],
	21: [16, 17, 22, 26, 27],
	22: [16, 17, 18, 21, 23, 26, 27, 28],
	23: [17, 18, 19, 22, 24, 27, 28, 29],
	24: [18, 19, 20, 23, 25, 28, 29, 30],
	25: [19, 20, 24, 29, 30],
	26: [21, 22, 27],
	27: [21, 22, 23, 26, 28],
	28: [22, 23, 24, 27, 29, 31, 32, 33],
	29: [23, 24, 25, 28, 30],
	30: [24, 25, 29],
	31: [28, 32, 34],
	32: [28, 31, 33, 35],
	33: [28, 32, 36],
	34: [31, 35],
	35: [32, 34, 36],
	36: [33, 35],
}

# Precalculated Jump Table:
# jump_map[from_node][jumped_node] = landing_node
# All jumps are guaranteed along straight drawn board lines.
const JUMP_TABLE: Dictionary = {
	0: {1: 2, 3: 8},
	1: {4: 8},
	2: {1: 0, 5: 8},
	3: {4: 5, 8: 14},
	4: {8: 13},
	5: {4: 3, 8: 12},
	6: {7: 8, 11: 16, 12: 18},
	7: {8: 9, 12: 17, 13: 19},
	8: {7: 6, 9: 10, 4: 1, 13: 18, 3: 0, 14: 20, 5: 2, 12: 16},
	9: {8: 7, 14: 19, 13: 17},
	10: {9: 8, 15: 20, 14: 18},
	11: {12: 13, 16: 21, 17: 23},
	12: {13: 14, 17: 22, 18: 24, 8: 5},
	13: {12: 11, 14: 15, 8: 4, 18: 23, 19: 25, 17: 21},
	14: {13: 12, 19: 24, 8: 3, 18: 22},
	15: {14: 13, 20: 25, 19: 23},
	16: {17: 18, 11: 6, 21: 26, 22: 28, 12: 8},
	17: {18: 19, 12: 7, 22: 27, 23: 29, 13: 9},
	18: {17: 16, 19: 20, 13: 8, 23: 28, 12: 6, 24: 30, 14: 10, 22: 26},
	19: {18: 17, 14: 9, 24: 29, 13: 7, 23: 27},
	20: {19: 18, 15: 10, 25: 30, 14: 8, 24: 28},
	21: {22: 23, 16: 11, 17: 13},
	22: {23: 24, 17: 12, 28: 33, 18: 14},
	23: {22: 21, 24: 25, 18: 13, 28: 32, 17: 11, 19: 15},
	24: {23: 22, 19: 14, 18: 12, 28: 31},
	25: {24: 23, 20: 15, 19: 13},
	26: {27: 28, 21: 16, 22: 18},
	27: {28: 29, 22: 17, 23: 19},
	28: {27: 26, 29: 30, 23: 18, 32: 35, 22: 16, 33: 36, 24: 20, 31: 34},
	29: {28: 27, 24: 19, 23: 17},
	30: {29: 28, 25: 20, 24: 18},
	31: {32: 33, 28: 24},
	32: {28: 23},
	33: {32: 31, 28: 22},
	34: {35: 36, 31: 28},
	35: {32: 28},
	36: {35: 34, 33: 28},
}

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
		[0, 1, 2],
		[3, 4, 5],
		[6, 7, 8, 9, 10],
		[11, 12, 13, 14, 15],
		[16, 17, 18, 19, 20],
		[21, 22, 23, 24, 25],
		[26, 27, 28, 29, 30],
		[31, 32, 33],
		[34, 35, 36],
		[1, 4, 8, 13, 18, 23, 28, 32, 35],
		[6, 11, 16, 21, 26],
		[7, 12, 17, 22, 27],
		[9, 14, 19, 24, 29],
		[10, 15, 20, 25, 30],
		[0, 3, 8, 14, 20],
		[16, 22, 28, 33, 36],
		[6, 12, 18, 24, 30],
		[7, 13, 19, 25],
		[9, 15],
		[11, 17, 23, 29],
		[21, 27],
		[2, 5, 8, 12, 16],
		[20, 24, 28, 31, 34],
		[10, 14, 18, 22, 26],
		[9, 13, 17, 21],
		[7, 11],
		[15, 19, 23, 27],
		[25, 29],
	]
