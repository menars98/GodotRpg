# main.gd
extends Node2D

signal level_up_completed # Oyuncu Level Up ekranında "Tamam"a bastığında fırlatılır
signal promotion_completed # Oyuncu sınıf seçtiğinde fırlatılır

var grid_units := {}
var selected_unit: Unit = null
var valid_moves: Array[Vector2i] = []
var current_movement_left: int = 0 
var valid_attacks: Array[Vector2i] = []
var is_selecting_attack_target: bool = false

# Keşif ve Savaş durumları
var is_combat_active: bool = false
var is_preparation_active: bool = false 
var leader_unit: Unit = null
var deployment_cells: Array[Vector2i] = []
var exploration_mouse_target: Vector2 = Vector2.INF

@onready var tilemap: TileMapLayer = get_node_or_null("TileMapLayer")
@onready var grid: GridManager = $GridManager
@onready var combat: CombatManager = $CombatManager
@onready var turn: TurnManager = $TurnManager
@onready var progression: ProgressionManager = $ProgressionManager
@onready var exploration: ExplorationManager = $ExplorationManager
@onready var deployment: DeploymentManager = $DeploymentManager
@onready var camera: Camera2D = $Cursor/Camera2D

func _ready():
	if tilemap:
		PartyManager.active_tile_size = float(tilemap.tile_set.tile_size.x)
		print("Küresel Hücre Boyutu Okundu: ", PartyManager.active_tile_size)
	
	_register_units()
	grid.setup_astar(tilemap, camera)
	
	if has_node("Cursor"):
		$Cursor.visible = false
		$Cursor.set_process_unhandled_input(false)
		$Cursor.map_limit = grid.astar.region
		$Cursor.cursor_selected.connect(_on_cursor_selected)
		
	if has_node("UI"):
		$UI/ActionMenu/AttackButton.pressed.connect(_on_attack_pressed)
		$UI/ActionMenu/WaitButton.pressed.connect(_on_wait_pressed)
		$UI/EndTurnButton.visible = false
		$UI/ActionMenu.visible = false
		$UI/TopBar.visible = false
		if $UI.has_node("VictoryLabel"): $UI/VictoryLabel.visible = false
		if $UI.has_node("DefeatLabel"): $UI/DefeatLabel.visible = false
		if $UI.has_node("ContinueButton"):
			$UI/ContinueButton.pressed.connect(_on_continue_pressed)
			$UI/ContinueButton.visible = false
		if $UI.has_node("StartBattleButton"):
			$UI/StartBattleButton.pressed.connect(_on_start_battle_pressed)
			$UI/StartBattleButton.visible = false
		if $UI.has_node("LevelUpPanel/VBoxContainer/OkButton"):
			$UI/LevelUpPanel/VBoxContainer/OkButton.pressed.connect(_on_level_up_ok_pressed)
			$UI/LevelUpPanel.visible = false
		
	if leader_unit and camera:
		camera.reparent(leader_unit)
		camera.position = Vector2.ZERO
		
	print("--- KEŞİF MODU AKTİF ---")
	

func _register_units():
	for child in get_children():
		if child is Unit:
			grid_units[child.grid_pos] = child
			grid.astar.set_point_solid(child.grid_pos, true)
			if not child.stats.is_enemy and leader_unit == null:
				leader_unit = child

func _process(delta: float) -> void:
	if not is_combat_active and not is_preparation_active:
		exploration.handle_movement(self, delta)

func start_preparation_phase():
	deployment.start_preparation_phase(self)

func _on_start_battle_pressed():
	is_preparation_active = false
	is_combat_active = true
	grid.clear_move_range()
	if has_node("UI/StartBattleButton"): $UI/StartBattleButton.visible = false
	if has_node("UI/TopBar"): $UI/TopBar.visible = true
	turn.initialize_queue(self)
	turn.start_next_turn(self)

func _return_to_exploration():
	# ÇÖZÜM 1: Keşif moduna dönerken duraklatmayı tamamen kaldırıyoruz!
	get_tree().paused = false
	
	is_combat_active = false
	is_preparation_active = false
	_deselect_unit()
	
	if camera and leader_unit:
		camera.reparent(leader_unit)
		camera.position = Vector2.ZERO
		
	if has_node("Cursor"):
		$Cursor.visible = false
		$Cursor.set_process_unhandled_input(false)
		
	if has_node("UI"):
		$UI/TopBar.visible = false
		if $UI.has_node("VictoryLabel"): $UI/VictoryLabel.visible = false
		if $UI.has_node("ContinueButton"): $UI/ContinueButton.visible = false
		
	# Savaş bitince lider dışındaki sonradan doğan diğer parti üyelerini sahneden temizleyelim
	for child in get_children():
		if child is Unit and child != leader_unit and not child.stats.is_enemy:
			grid.astar.set_point_solid(child.grid_pos, false)
			grid_units.erase(child.grid_pos)
			child.queue_free()
			
	leader_unit.has_moved = false
	leader_unit.has_acted = false
	leader_unit.modulate = Color.WHITE

func _on_continue_pressed():
	_return_to_exploration()

func _unhandled_input(event: InputEvent) -> void:
	if is_combat_active:
		if has_node("UI/ActionMenu") and $UI/ActionMenu.visible:
			var is_right_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed
			var is_esc = event.is_action_pressed("ui_cancel")
			if is_right_click or is_esc:
				_on_cursor_canceled()
				get_viewport().set_input_as_handled()

func _on_cursor_selected(cursor_pos: Vector2i):
	if is_preparation_active:
		deployment.handle_preparation_click(self, cursor_pos)
		return

	if is_combat_active:
		await turn.handle_combat_click(self, cursor_pos)

func _on_cursor_canceled():
	if is_preparation_active: selected_unit = null; return
	if not is_combat_active or (selected_unit and selected_unit.is_moving): return
	if is_selecting_attack_target:
		is_selecting_attack_target = false
		grid.clear_move_range()
		_show_action_menu(selected_unit)
		return
	if has_node("UI/ActionMenu") and $UI/ActionMenu.visible:
		_hide_action_menu()
		if current_movement_left > 0:
			valid_moves = grid.get_valid_move_cells(selected_unit.grid_pos, current_movement_left, tilemap)
			grid.draw_move_range(valid_moves)
		return
	_deselect_unit()

func _select_unit(unit: Unit):
	selected_unit = unit
	current_movement_left = unit.movement_left
	valid_moves = grid.get_valid_move_cells(unit.grid_pos, current_movement_left, tilemap)
	grid.draw_move_range(valid_moves)

func _deselect_unit():
	selected_unit = null
	valid_moves.clear()
	current_movement_left = 0
	grid.clear_move_range()

func move_unit_to(unit: Unit, target_pos: Vector2i, path: Array[Vector2i]):
	grid.astar.set_point_solid(unit.grid_pos, false)
	grid_units.erase(unit.grid_pos)
	unit.move_along_path(path)
	await unit.movement_finished
	grid_units[unit.grid_pos] = unit
	grid.astar.set_point_solid(unit.grid_pos, true)

func _show_action_menu(unit: Unit):
	if not has_node("UI/ActionMenu"): return
	var screen_pos = unit.get_global_transform_with_canvas().get_origin()
	var menu_size = $UI/ActionMenu.size
	$UI/ActionMenu.global_position = screen_pos - Vector2($UI/ActionMenu.size.x / 2.0, $UI/ActionMenu.size.y + 24.0)
	$UI/ActionMenu.visible = true
	if has_node("Cursor"): $Cursor.set_process_unhandled_input(false)

func _hide_action_menu():
	if has_node("UI/ActionMenu"): $UI/ActionMenu.visible = false
	if has_node("Cursor"): $Cursor.set_process_unhandled_input(true)

func _on_attack_pressed():
	if selected_unit == null: return
	valid_attacks = [selected_unit.grid_pos + Vector2i.UP, selected_unit.grid_pos + Vector2i.DOWN, selected_unit.grid_pos + Vector2i.LEFT, selected_unit.grid_pos + Vector2i.RIGHT]
	_hide_action_menu()
	grid.draw_attack_range(valid_attacks)
	is_selecting_attack_target = true

func _on_wait_pressed():
	if selected_unit: _complete_unit_turn(selected_unit)

func _complete_unit_turn(unit: Unit):
	if not is_combat_active or unit == null: _hide_action_menu(); return
	unit.has_acted = true
	unit.movement_left = 0
	unit.modulate = Color(0.4, 0.4, 0.4, 1.0)
	_deselect_unit()
	_hide_action_menu()
	turn._complete_active_turn(self)

func _on_cursor_moved(new_grid_pos: Vector2i):
	if grid_units.has(new_grid_pos): _show_unit_info(grid_units[new_grid_pos])
	else: _hide_unit_info()

func _show_unit_info(unit: Unit):
	if not has_node("UI/InfoPanel"): return
	var p = $UI/InfoPanel
	p.get_node("NameLabel").text = unit.stats.unit_name
	p.get_node("HPLabel").text = "HP: " + str(unit.stats.hp) + "/" + str(unit.stats.max_hp)
	p.get_node("StatsLabel").text = "ATK: " + str(unit.stats.attack) + " DEF: " + str(unit.stats.defense)
	p.visible = true

func _hide_unit_info():
	if has_node("UI/InfoPanel"): $UI/InfoPanel.visible = false

func check_game_over_conditions():
	if check_victory_conditions(): return
	check_defeat_conditions()

func check_victory_conditions() -> bool:
	var enemies_left = 0
	for unit in grid_units.values():
		if is_instance_valid(unit) and unit.stats.is_enemy: enemies_left += 1
	if enemies_left == 0:
		is_combat_active = false
		_deselect_unit() 
		get_tree().paused = true
		if has_node("UI/TopBar"): $UI/TopBar.visible = false
		if has_node("UI/VictoryLabel"): $UI/VictoryLabel.visible = true
		if has_node("UI/ContinueButton"): $UI/ContinueButton.visible = true
		if has_node("Cursor"): $Cursor.set_process_unhandled_input(false)
		return true
	return false

func check_defeat_conditions() -> bool:
	var players_left = 0
	for unit in grid_units.values():
		if is_instance_valid(unit) and not unit.stats.is_enemy:
			players_left += 1
			
	if players_left == 0:
		print("--- OYUN BİTTİ ---")
		_deselect_unit() # Seçimleri ve mavi alanları temizle
		if has_node("UI/DefeatLabel"):
			$UI/DefeatLabel.visible = true
		if has_node("Cursor"):
			$Cursor.set_process_unhandled_input(false)
			
		# ÇÖZÜM 2: Sahne yeniden yüklenmeden önce duraklatmayı kaldırıyoruz
		# yoksa yeni yüklenen sahne de donuk (paused) başlar!
		get_tree().paused = false
		
		get_tree().create_timer(5.0).timeout.connect(get_tree().reload_current_scene)
		return true
		
	return false

# Düşman itme anında en yakın boş kareyi bulur
func _find_closest_walkable_cell(start_pos: Vector2i) -> Vector2i:
	if grid.is_cell_walkable(start_pos, tilemap):
		return start_pos
	for r in range(1, 4):
		for x in range(-r, r + 1):
			for y in range(-r, r + 1):
				if abs(x) == r or abs(y) == r:
					var test_cell = start_pos + Vector2i(x, y)
					if grid.is_cell_walkable(test_cell, tilemap):
						return test_cell
	return start_pos

# Sınıf Seçim Menüsü (GÜNCELLENDİ: Seçim yapıldığında sinyal fırlatır)
func show_promotion_choice_menu(unit: Unit, choices: Array[Promotion]):
	if not has_node("UI/PromotionPanel"): return
	var panel = $UI/PromotionPanel
	var container = $UI/PromotionPanel/ChoiceContainer
	
	for child in container.get_children():
		child.queue_free()
		
	for promo in choices:
		var btn = Button.new()
		btn.text = "Sınıf Değiştir: " + promo.new_class_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func():
			progression.execute_promotion(unit, promo)
			panel.visible = false
			promotion_completed.emit() # Sinyali fırlatıp ProgressionManager'a devam etmesini söylüyoruz!
			if has_node("Cursor"):
				$Cursor.set_process_unhandled_input(true)
		)
		container.add_child(btn)
		
	panel.visible = true
	get_tree().paused = true 
	if has_node("Cursor"):
		$Cursor.set_process_unhandled_input(false)

# Seviye atlama ekranını açar ve artan statları yazdırır
func show_level_up_panel(unit: Unit, hp_add: int, atk_add: int, def_add: int):
	if not has_node("UI/LevelUpPanel"): return
	
	var panel = $UI/LevelUpPanel
	var text_node = $UI/LevelUpPanel/VBoxContainer/StatText
	text_node.text = unit.stats.unit_name + " SEVİYE ATLADI!\n\n" \
		+ "Yeni Seviye: " + str(unit.stats.level) + "\n" \
		+ "Max HP: +" + str(hp_add) + " (Toplam: " + str(unit.stats.max_hp) + ")\n" \
		+ "ATK: +" + str(atk_add) + " (Toplam: " + str(unit.stats.attack) + ")\n" \
		+ "DEF: +" + str(def_add) + " (Toplam: " + str(unit.stats.defense) + ")"
		
	panel.visible = true
	get_tree().paused = true
	if has_node("Cursor"):
		$Cursor.set_process_unhandled_input(false)

# Level Up ekranında [OK] butonuna tıklandığında çalışır
func _on_level_up_ok_pressed():
	if has_node("UI/LevelUpPanel"):
		$UI/LevelUpPanel.visible = false
	level_up_completed.emit() # Sinyali fırlatıp ProgressionManager'a devam etmesini söylüyoruz
