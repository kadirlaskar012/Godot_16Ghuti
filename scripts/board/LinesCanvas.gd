class_name LinesCanvas
extends Node2D

## LinesCanvas draws authentic 2.5D hand-engraved physical lines on the 16 Guti wooden board.
## Uses a 3-pass illumination technique: sunlit lower bevel highlight, carved wooden groove, and deep inner dark incision.

var current_theme: String = "classic_wood"

func apply_theme(theme_id: String) -> void:
	current_theme = theme_id
	queue_redraw()

func _draw() -> void:
	var lines = BoardData.get_all_lines()
	
	var bevel_color: Color
	var groove_color: Color
	var crevice_color: Color
	
	match current_theme:
		"ivory_maple":
			# Light mode: clean ivory/sunlit highlight, crisp dark walnut engraved groove
			bevel_color = Color(1.0, 0.98, 0.92, 0.65)
			groove_color = Color(0.24, 0.16, 0.09, 0.95)
			crevice_color = Color(0.12, 0.08, 0.03, 0.98)
		"royal_mahogany":
			# Royal mahogany: rich brass/gold sunlit bevel, deep wine/rosewood groove
			bevel_color = Color(1.0, 0.85, 0.48, 0.45)
			groove_color = Color(0.20, 0.06, 0.04, 0.94)
			crevice_color = Color(0.08, 0.02, 0.01, 0.98)
		_: # classic_wood
			bevel_color = Color(0.95, 0.82, 0.52, 0.36)
			groove_color = Color(0.16, 0.08, 0.03, 0.92)
			crevice_color = Color(0.06, 0.03, 0.01, 0.96)
	
	var bevel_offset = Vector2(0.0, 1.8)
	var bevel_width = 5.4
	var groove_width = 3.6
	var crevice_width = 1.8
	
	# Pass 1: Sunlight catch on bottom/right carved bevel
	for line in lines:
		for i in range(line.size() - 1):
			var u = line[i]
			var v = line[i+1]
			var p1 = BoardData.get_node_position(BoardData.NODE_COORDINATES[u].x, BoardData.NODE_COORDINATES[u].y)
			var p2 = BoardData.get_node_position(BoardData.NODE_COORDINATES[v].x, BoardData.NODE_COORDINATES[v].y)
			draw_line(p1 + bevel_offset, p2 + bevel_offset, bevel_color, bevel_width, false)
			
	# Pass 2: Deep engraved wooden trench
	for line in lines:
		for i in range(line.size() - 1):
			var u = line[i]
			var v = line[i+1]
			var p1 = BoardData.get_node_position(BoardData.NODE_COORDINATES[u].x, BoardData.NODE_COORDINATES[u].y)
			var p2 = BoardData.get_node_position(BoardData.NODE_COORDINATES[v].x, BoardData.NODE_COORDINATES[v].y)
			draw_line(p1, p2, groove_color, groove_width, false)
			
	# Pass 3: Deepest inner dark groove incision
	for line in lines:
		for i in range(line.size() - 1):
			var u = line[i]
			var v = line[i+1]
			var p1 = BoardData.get_node_position(BoardData.NODE_COORDINATES[u].x, BoardData.NODE_COORDINATES[u].y)
			var p2 = BoardData.get_node_position(BoardData.NODE_COORDINATES[v].x, BoardData.NODE_COORDINATES[v].y)
			draw_line(p1, p2, crevice_color, crevice_width, false)
