# turn_manager.gd

class_name TurnManager
extends Node

var action_queue: Array[Unit] = []
var active_unit: Unit = null
var round_count: int = 1

func initialize_queue(main: Node):
	action_queue.clear()
	for child in main.get_children():
		if child is Unit:
			action_queue.append(child)
	action_queue.sort_custom(func(a, b): return a.stats.speed > b.stats.speed)

func start_next_turn(main: Node):
	if not main.is_combat_active:
		return
		
	if main.check_victory_conditions() or main.check_defeat_conditions():
		return
		
	if action_queue.is_empty():
		round_count += 1
		initialize_queue(main)
		if action_queue.is_empty(): 
			return
			
	active_unit = action_queue.pop_front()
	
	if not is_instance_valid(active_unit) or active_unit.stats.hp <= 0:
		await start_next_turn(main)
		return
		
	_update_hud(main, active_unit)
	
	main.selected_unit = active_unit
	main.current_movement_left = active_unit.stats.move_range
	
	if active_unit.stats.is_enemy:
		if main.has_node("Cursor"):
			main.get_node("Cursor").set_process_unhandled_input(false)
			main.get_node("Cursor").visible = false
			
		if main.has_node("AIManager"):
			await main.get_node("AIManager").run_single_enemy_ai(main, active_unit)
			
		await _complete_active_turn(main)
	else:
		if main.has_node("Cursor"):
			main.get_node("Cursor").set_process_unhandled_input(true)
			main.get_node("Cursor").visible = true
			main.get_node("Cursor")._update_grid_pos(active_unit.grid_pos)
			
		main.valid_moves = main.grid.get_valid_move_cells(active_unit.grid_pos, main.current_movement_left, main.tilemap)
		main.grid.draw_move_range(main.valid_moves)

func _complete_active_turn(main: Node):
	if not main.is_combat_active:
		return
		
	if is_instance_valid(active_unit):
		active_unit.has_acted = true
		active_unit.movement_left = 0
		active_unit.modulate = Color(0.5, 0.5, 0.5, 1.0)
		
	main._deselect_unit()
	main._hide_action_menu()
	
	await start_next_turn(main)

func _update_hud(main: Node, unit: Unit):
	if not main.has_node("UI"): return
	var ui = main.get_node("UI")
	if ui.has_node("TopBar/RoundLabel"):
		ui.get_node("TopBar/RoundLabel").text = "Raunt: " + str(round_count)
	if ui.has_node("TopBar/TurnLabel"):
		if unit.stats.is_enemy:
			ui.get_node("TopBar/TurnLabel").text = "Sıra: " + unit.stats.unit_name + " (AI)"
			ui.get_node("TopBar/TurnLabel").modulate = Color.RED
		else:
			ui.get_node("TopBar/TurnLabel").text = "Sıra: " + unit.stats.unit_name
			ui.get_node("TopBar/TurnLabel").modulate = Color.GREEN

# ==========================================
# YENİ: SAVAŞ TIKLAMA YÖNETİCİSİ (Main'den devralındı!)
# ==========================================
func handle_combat_click(main: Node, cursor_pos: Vector2i):
	# A. Eğer saldırı hedefi seçiliyorsa
	if main.is_selecting_attack_target:
		await _handle_attack_selection(main, cursor_pos) 
		return

	# B. Normal Birim Seçimi
	if main.grid_units.has(cursor_pos) and (main.selected_unit == null or main.grid_units[cursor_pos] != main.selected_unit):
		var clicked_unit = main.grid_units[cursor_pos]
		if clicked_unit.stats.is_enemy or clicked_unit.has_acted: 
			return
		main._select_unit(clicked_unit)
		return

	# C. Yürüme/Hareket Emri
	if main.selected_unit and cursor_pos in main.valid_moves:
		main.grid.astar.set_point_solid(main.selected_unit.grid_pos, false)
		var path = main.grid.astar.get_id_path(main.selected_unit.grid_pos, cursor_pos)
		main.grid.astar.set_point_solid(main.selected_unit.grid_pos, true)
		
		var cost = path.size() - 1
		if path.size() > 0:
			main.grid.clear_move_range()
			await main.move_unit_to(main.selected_unit, cursor_pos, path)
			main.current_movement_left -= cost
			main.selected_unit.movement_left = main.current_movement_left
			main._show_action_menu(main.selected_unit)
		return

# Saldırı hedefinin onaylanması
func _handle_attack_selection(main: Node, cursor_pos: Vector2i):
	if cursor_pos in main.valid_attacks:
		if main.grid_units.has(cursor_pos):
			var target_enemy = main.grid_units[cursor_pos]
			if target_enemy.stats.is_enemy:
				var active_hero = main.selected_unit
				await main.combat.execute_combat(main, active_hero, target_enemy)
				
				main.is_selecting_attack_target = false
				main.grid.clear_move_range()
				
				var enemies_left = 0
				for u in main.grid_units.values():
					if is_instance_valid(u) and u.stats.is_enemy: 
						enemies_left += 1
				
				if enemies_left > 0: 
					main._complete_unit_turn(active_hero)
				else: 
					main._hide_action_menu()
				return
	print("Saldıracak düşman yok!")
