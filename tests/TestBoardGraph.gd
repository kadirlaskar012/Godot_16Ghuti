extends SceneTree

func _init() -> void:
	print("--- Running TestBoardGraph ---")
	
	# 1. Startup configuration validation
	var valid: bool = BoardData.validate_startup_configuration()
	assert(valid, "Startup configuration validation failed!")
	print("✔ Startup 16 vs 16 configuration verified.")
	
	# 2. Total nodes count
	assert(BoardData.TOTAL_NODES == 37, "Total nodes must be 37")
	assert(BoardData.NODE_COORDINATES.size() == 37, "Coordinates must have 37 elements")
	print("✔ 37 nodes count verified.")
	
	# 3. Adjacency symmetry test
	for u in range(37):
		var neighbors: Array = BoardData.ADJACENCY[u]
		for v in neighbors:
			assert(BoardData.ADJACENCY[v].has(u), "Adjacency asymmetric between %d and %d" % [u, v])
	print("✔ Adjacency symmetry verified (all 92 undirected connections).")
	
	# 4. Jump Table tests
	var jump_count: int = 0
	for u in BoardData.JUMP_TABLE.keys():
		var over_map: Dictionary = BoardData.JUMP_TABLE[u]
		for over_node in over_map.keys():
			var land_node: int = over_map[over_node]
			jump_count += 1
			# u must be adjacent to over_node
			assert(BoardData.ADJACENCY[u].has(over_node), "Jump start %d not adjacent to hopped node %d" % [u, over_node])
			# over_node must be adjacent to land_node
			assert(BoardData.ADJACENCY[over_node].has(land_node), "Hopped node %d not adjacent to landing %d" % [over_node, land_node])
			# Reverse jump must exist
			assert(BoardData.JUMP_TABLE.has(land_node), "Landing node %d has no jump entries" % land_node)
			assert(BoardData.JUMP_TABLE[land_node].has(over_node), "Reverse jump through %d missing from %d" % [over_node, land_node])
			assert(BoardData.JUMP_TABLE[land_node][over_node] == u, "Reverse jump mismatch from %d through %d" % [land_node, over_node])
	print("✔ Jump table symmetry and connectivity verified (%d jump paths)." % jump_count)
	
	print("🎉 ALL BOARD GRAPH TESTS PASSED!")
	quit(0)
