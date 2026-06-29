# exploration_manager.gd
class_name ExplorationManager
extends Node

# VERİ ODAKLI TETİKLEME MENZİLİ: Karakter canavara kaç kare yaklaşınca savaş başlasın?
@export var encounter_trigger_range: float = 3.5 

# Pürüzsüz 8-yönlü fiziksel yürüme ve wall-slide kontrolleri
func handle_movement(main: Node, delta: float):
	if main.leader_unit == null or main.leader_unit.is_moving:
		return
		
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_down", "ui_up")
	
	if direction == Vector2.ZERO:
		if Input.is_key_pressed(KEY_W): direction.y = -1
		elif Input.is_key_pressed(KEY_S): direction.y = 1
		if Input.is_key_pressed(KEY_A): direction.x = -1
		elif Input.is_key_pressed(KEY_D): direction.x = 1
		
	if direction != Vector2.ZERO:
		main.exploration_mouse_target = Vector2.INF
	else:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			main.exploration_mouse_target = main.get_global_mouse_position()
			
		if main.exploration_mouse_target != Vector2.INF:
			if main.leader_unit.position.distance_to(main.exploration_mouse_target) > 6.0:
				direction = (main.exploration_mouse_target - main.leader_unit.position).normalized()
			else:
				main.exploration_mouse_target = Vector2.INF
				
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		var velocity = direction * main.leader_unit.stats.exploration_speed * delta
		
		var offset = 6.0
		var target_pos_x = main.leader_unit.position + Vector2(velocity.x, 0)
		var check_x = target_pos_x.x + (offset if velocity.x > 0 else -offset)
		var target_grid_x = Vector2i(floor(check_x / PartyManager.active_tile_size), floor(main.leader_unit.position.y / PartyManager.active_tile_size))
		
		var target_pos_y = main.leader_unit.position + Vector2(0, velocity.y)
		var check_y = target_pos_y.y + (offset if velocity.y > 0 else -offset)
		var target_grid_y = Vector2i(floor(main.leader_unit.position.x / PartyManager.active_tile_size), floor(check_y / PartyManager.active_tile_size))
		
		var target_grid_both = Vector2i(floor(check_x / PartyManager.active_tile_size), floor(check_y / PartyManager.active_tile_size))
		
		if main.grid.is_cell_walkable(target_grid_both, main.tilemap, main.leader_unit.grid_pos):
			main.leader_unit.position += velocity
		else:
			if main.grid.is_cell_walkable(target_grid_x, main.tilemap, main.leader_unit.grid_pos):
				main.leader_unit.position.x += velocity.x
			if main.grid.is_cell_walkable(target_grid_y, main.tilemap, main.leader_unit.grid_pos):
				main.leader_unit.position.y += velocity.y
		
		var current_grid = Vector2i(floor(main.leader_unit.position.x / PartyManager.active_tile_size), floor(main.leader_unit.position.y / PartyManager.active_tile_size))
		if current_grid != main.leader_unit.grid_pos:
			main.grid.astar.set_point_solid(main.leader_unit.grid_pos, false)
			main.grid_units.erase(main.leader_unit.grid_pos)
			main.leader_unit.grid_pos = current_grid
			main.grid_units[main.leader_unit.grid_pos] = main.leader_unit
			main.grid.astar.set_point_solid(main.leader_unit.grid_pos, true)
		
		_check_encounter_trigger_pixels(main)

func _check_encounter_trigger_pixels(main: Node):
	for unit in main.grid_units.values():
		if is_instance_valid(unit) and unit.stats.is_enemy:
			var dist = main.leader_unit.position.distance_to(unit.position)
			# Veriden gelen menzille çarparak kontrol eder (Dinamiktir)
			if dist <= (encounter_trigger_range * PartyManager.active_tile_size):
				main.exploration_mouse_target = Vector2.INF
				main.start_preparation_phase()
				break
