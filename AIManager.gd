# ai_manager.gd

class_name AIManager
extends Node

# Sadece sırası gelen tek bir düşmanı yönetir
func run_single_enemy_ai(main: Node, enemy: Unit):
	print("AI Düşman Düşünüyor: ", enemy.stats.unit_name)
	
	var target_player = _find_closest_player_unit(main, enemy)
	if target_player == null:
		return
		
	var target_neighbor = _get_closest_walkable_neighbor(main, enemy.grid_pos, target_player.grid_pos)
	var distance = abs(enemy.grid_pos.x - target_player.grid_pos.x) + abs(enemy.grid_pos.y - target_player.grid_pos.y)
	
	if distance > 1:
		main.grid.astar.set_point_solid(enemy.grid_pos, false)
		var full_path = main.grid.astar.get_id_path(enemy.grid_pos, target_neighbor)
		main.grid.astar.set_point_solid(enemy.grid_pos, true)
		
		if full_path.size() > 0:
			var actual_path_size = min(full_path.size(), enemy.stats.move_range + 1)
			var clipped_path = full_path.slice(0, actual_path_size)
			var final_pos = clipped_path[-1]
			
			await main.move_unit_to(enemy, final_pos, clipped_path)
			
	var new_distance = abs(enemy.grid_pos.x - target_player.grid_pos.x) + abs(enemy.grid_pos.y - target_player.grid_pos.y)
	if new_distance == 1:
		main.combat.execute_combat(main, enemy, target_player)
		await main.get_tree().create_timer(0.6).timeout

func _find_closest_player_unit(main: Node, enemy: Unit) -> Unit:
	var closest_player: Unit = null
	var min_distance = 9999
	for child in main.get_children():
		if child is Unit and not child.stats.is_enemy:
			var dist = abs(enemy.grid_pos.x - child.grid_pos.x) + abs(enemy.grid_pos.y - child.grid_pos.y)
			if dist < min_distance:
				min_distance = dist
				closest_player = child
	return closest_player

func _get_closest_walkable_neighbor(main: Node, start_pos: Vector2i, target_pos: Vector2i) -> Vector2i:
	var neighbors = [
		target_pos + Vector2i.UP,
		target_pos + Vector2i.DOWN,
		target_pos + Vector2i.LEFT,
		target_pos + Vector2i.RIGHT
	]
	var closest_neighbor = target_pos
	var min_distance = 9999
	for cell in neighbors:
		if main.grid.is_cell_walkable(cell, main.tilemap) or cell == start_pos:
			var dist = abs(start_pos.x - cell.x) + abs(start_pos.y - cell.y)
			if dist < min_distance:
				min_distance = dist
				closest_neighbor = cell
	return closest_neighbor
