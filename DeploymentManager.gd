# deployment_manager.gd
class_name DeploymentManager
extends Node

# VERİ ODAKLI İTME MESAFESİ: Canavar savaşa girince kaç kare uzağa itilsin?
@export var enemy_spawn_distance: int = 6 

func start_preparation_phase(main: Node):
	main.is_preparation_active = true
	print("--- HAZIRLIK FAZI BAŞLADI ---")
	
	main.grid.astar.clear()
	main.grid.setup_astar(main.tilemap, main.camera)
	main.grid_units.clear()
	
	var first_enemy: Unit = null
	for child in main.get_children():
		if child is Unit and child.stats.is_enemy:
			first_enemy = child
			break
			
	if first_enemy:
		var dir = Vector2(first_enemy.position - main.leader_unit.position).normalized()
		# Veriden gelen itme mesafesini uygular
		var target_grid = main.leader_unit.grid_pos + Vector2i(round(dir.x * enemy_spawn_distance), round(dir.y * enemy_spawn_distance))
		
		var map_rect = main.tilemap.get_used_rect()
		target_grid.x = clamp(target_grid.x, map_rect.position.x + 1, map_rect.end.x - 2)
		target_grid.y = clamp(target_grid.y, map_rect.position.y + 1, map_rect.end.y - 2)
		
		target_grid = main._find_closest_walkable_cell(target_grid)
		
		first_enemy.grid_pos = target_grid
		first_enemy.position = first_enemy.grid_to_world(target_grid)
		main.grid_units[target_grid] = first_enemy
		main.grid.astar.set_point_solid(target_grid, true)

	_spawn_party_around_leader(main, first_enemy.grid_pos if first_enemy else Vector2i.ZERO)

	if main.camera and main.has_node("Cursor"):
		main.camera.reparent(main.get_node("Cursor"))
		main.camera.position = Vector2.ZERO
		
	if main.has_node("Cursor"):
		main.get_node("Cursor").visible = true
		main.get_node("Cursor").set_process_unhandled_input(true)
		main.get_node("Cursor")._update_grid_pos(main.leader_unit.grid_pos)
		
	if main.has_node("UI/StartBattleButton"):
		main.get_node("UI/StartBattleButton").visible = true

func _spawn_party_around_leader(main: Node, enemy_pos: Vector2i):
	if PartyManager.active_heroes.is_empty(): return
	
	main.leader_unit.stats = PartyManager.active_heroes[0].duplicate()
	main.leader_unit.grid_pos = Vector2i(floor(main.leader_unit.position.x / PartyManager.active_tile_size), floor(main.leader_unit.position.y / PartyManager.active_tile_size))
	main.leader_unit.position = main.leader_unit.grid_to_world(main.leader_unit.grid_pos)
	main.grid_units[main.leader_unit.grid_pos] = main.leader_unit
	main.grid.astar.set_point_solid(main.leader_unit.grid_pos, true)
	
	main.deployment_cells = _calculate_deployment_zone(main, main.leader_unit.grid_pos, PartyManager.active_heroes.size(), enemy_pos)
	main.grid.draw_deployment_zone(main.deployment_cells)
	
	var unit_scene = load("res://Scenes/unit.tscn")
	var hero_idx = 1
	for cell in main.deployment_cells:
		if hero_idx >= PartyManager.active_heroes.size(): break
		if cell == main.leader_unit.grid_pos: continue
		if not main.grid_units.has(cell):
			var new_hero = unit_scene.instantiate()
			new_hero.stats = PartyManager.active_heroes[hero_idx].duplicate()
			new_hero.grid_pos = cell
			main.add_child(new_hero)
			new_hero.position = new_hero.grid_to_world(cell)
			main.grid_units[cell] = new_hero
			main.grid.astar.set_point_solid(cell, true)
			hero_idx += 1

func _calculate_deployment_zone(main: Node, leader_pos: Vector2i, num_heroes: int, enemy_pos: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var dir_to_enemy = Vector2(enemy_pos - leader_pos).normalized()
	var behind_dir = Vector2i(round(-dir_to_enemy.x), round(-dir_to_enemy.y))
	if behind_dir == Vector2i.ZERO: behind_dir = Vector2i.LEFT
	var side_dir = Vector2i(-behind_dir.y, behind_dir.x)
	
	var depth = 2
	var width = 2
	if num_heroes > 6: depth = 4; width = 5
	elif num_heroes > 3: depth = 3; width = 4
	else: depth = 2; width = 3
		
	for d in range(depth):
		for w in range(-width/2, (width/2) + 1):
			var cell = leader_pos + (behind_dir * d) + (side_dir * w)
			if main.grid.is_cell_walkable(cell, main.tilemap, leader_pos) or cell == leader_pos:
				cells.append(cell)
	return cells

func handle_preparation_click(main: Node, cursor_pos: Vector2i):
	if main.grid_units.has(cursor_pos):
		var clicked_unit = main.grid_units[cursor_pos]
		if not clicked_unit.stats.is_enemy and cursor_pos in main.deployment_cells:
			if main.selected_unit == null:
				main.selected_unit = clicked_unit
			else:
				if clicked_unit.grid_pos in main.deployment_cells:
					var pos1 = main.selected_unit.grid_pos
					var pos2 = clicked_unit.grid_pos
					
					main.selected_unit.grid_pos = pos2
					main.selected_unit.position = main.selected_unit.grid_to_world(pos2) 
					
					clicked_unit.grid_pos = pos1
					clicked_unit.position = clicked_unit.grid_to_world(pos1) 
					
					main.grid_units[pos2] = main.selected_unit
					main.grid_units[pos1] = clicked_unit
					
					print("Birimler yer değiştirdi!")
					main.selected_unit = null
	else:
		if main.selected_unit != null and cursor_pos in main.deployment_cells:
			var old_pos = main.selected_unit.grid_pos
			main.grid.astar.set_point_solid(old_pos, false)
			main.grid_units.erase(old_pos)
			
			main.selected_unit.grid_pos = cursor_pos
			main.selected_unit.position = main.selected_unit.grid_to_world(cursor_pos)
			
			main.grid_units[cursor_pos] = main.selected_unit
			main.grid.astar.set_point_solid(cursor_pos, true)
			main.selected_unit = null
