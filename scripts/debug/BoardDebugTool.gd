class_name BoardDebugTool
extends Control

## BoardDebugTool is a development-only inspection tool for verifying
## board topology, node IDs, connections, jump paths, and piece states.

@onready var board: BoardManager = $Board
@onready var info_label: Label = $InspectorPanel/Margin/VBox/InfoLabel
@onready var node_spin: SpinBox = $InspectorPanel/Margin/VBox/HBox/NodeSpin
@onready var back_btn: Button = $TopBar/BackButton
@onready var toggle_ids_btn: Button = $TopBar/ToggleIDsButton

var state: GameState
var show_ids: bool = true

func _ready() -> void:
	state = GameState.new()
	state.reset_to_start()
	board.populate_pieces_from_state(state)
	
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	
	toggle_ids_btn.pressed.connect(func():
		show_ids = not show_ids
		board.toggle_debug()
	)
	
	node_spin.value_changed.connect(_on_node_selected)
	
	# Start with IDs visible
	board.toggle_debug()
	_inspect_node(0)

func _inspect_node(node_id: int) -> void:
	var coord = BoardData.NODE_COORDINATES[node_id]
	var neighbors = BoardData.ADJACENCY[node_id]
	var jumps = BoardData.JUMP_TABLE.get(node_id, {})
	var occ = state.get_piece(node_id)
	var occ_str = "EMPTY"
	if occ == BoardData.Player.PLAYER_1: occ_str = "RED (P1)"
	elif occ == BoardData.Player.PLAYER_2: occ_str = "IVORY (P2)"
	
	var text = "=== NODE %02d ===\n" % node_id
	text += "Grid Coord: (%d, %d)\n" % [coord.x, coord.y]
	text += "Occupant: %s\n" % occ_str
	text += "\nConnected Neighbors (%d):\n" % neighbors.size()
	for n in neighbors:
		text += "  -> Node %02d\n" % n
		
	text += "\nJump Paths (%d):\n" % jumps.size()
	for over_node in jumps:
		text += "  Jump over %02d -> Landing %02d\n" % [over_node, jumps[over_node]]
		
	info_label.text = text
	
	# Highlight node and connections
	board.clear_selection()
	if board.pieces.has(node_id) and is_instance_valid(board.pieces[node_id]):
		board.pieces[node_id].set_selected(true)
	for n in neighbors:
		if board.nodes.has(n):
			board.nodes[n].set_highlight(BoardNode.HighlightType.VALID_MOVE)
	for over_node in jumps:
		var land = jumps[over_node]
		if board.nodes.has(land):
			board.nodes[land].set_highlight(BoardNode.HighlightType.VALID_CAPTURE)

func _on_node_selected(value: float) -> void:
	_inspect_node(int(value))
