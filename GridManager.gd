# grid_manager.gd
class_name GridManager
extends Node

var astar = AStarGrid2D.new()
var highlight_container: Node2D

# VERİ ODAKLI ÇİZİM RENKLERİ (Editörden serbestçe değiştirilebilir)
@export_group("Grid Highlights")
@export var move_range_color: Color = Color(0.0, 0.0, 1.0, 0.18)      # Şeffaf Mavi
@export var attack_range_color: Color = Color(1.0, 0.0, 0.0, 0.22)    # Şeffaf Kırmızı
@export var deployment_zone_color: Color = Color(1.0, 0.9, 0.6, 0.25) # Yarı Şeffaf Sarı/Beyaz

func _ready():
	highlight_container = Node2D.new()
	add_child(highlight_container)

func setup_astar(tilemap: TileMapLayer, camera: Camera2D = null):
	if tilemap == null:
		push_error("HATA: GridManager'a gönderilen TileMapLayer NULL!")
		return
		
	var tile_size: Vector2i = tilemap.tile_set.tile_size
	var map_rect = tilemap.get_used_rect()
	astar.region = map_rect
	astar.cell_size = tile_size
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	if camera:
		camera.limit_left = map_rect.position.x * tile_size.x
		camera.limit_top = map_rect.position.y * tile_size.y
		camera.limit_right = map_rect.end.x * tile_size.x
		camera.limit_bottom = map_rect.end.y * tile_size.y
		
	var solid_count = 0
	for cell in tilemap.get_used_cells():
		var tile_data = tilemap.get_cell_tile_data(cell)
		if tile_data and tile_data.get_custom_data("is_solid") == true:
			astar.set_point_solid(cell, true)
			solid_count += 1
			
	print("--- ASTAR HAZIRLANDI ---")
	print("Hücre Boyutu (Dinamik): ", tile_size)
	print("Kaydedilen Toplam Engel (Solid) Sayısı: ", solid_count)

func is_cell_walkable(pos: Vector2i, tilemap: TileMapLayer, ignore_pos: Vector2i = Vector2i(-999, -999)) -> bool:
	if tilemap == null: return false
	if not tilemap.get_used_rect().has_point(pos):
		return false 
	if pos != ignore_pos and astar.is_point_solid(pos):
		return false
	if tilemap.get_cell_source_id(pos) == -1:
		return false
	return true

func get_valid_move_cells(start_pos: Vector2i, move_range: int, tilemap: TileMapLayer) -> Array[Vector2i]:
	var valid_cells: Array[Vector2i] = []
	var queue: Array[Dictionary] = [{"pos": start_pos, "cost": 0}]
	var visited := {}
	visited[start_pos] = 0
	
	while not queue.is_empty():
		var current = queue.pop_front()
		var curr_pos = current["pos"]
		var curr_cost = current["cost"]
		
		if curr_pos != start_pos:
			valid_cells.append(curr_pos)
			
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for dir in directions:
			var neighbor = curr_pos + dir
			var next_cost = curr_cost + 1
			
			if next_cost <= move_range:
				if is_cell_walkable(neighbor, tilemap):
					if not visited.has(neighbor) or next_cost < visited[neighbor]:
						visited[neighbor] = next_cost
						queue.append({"pos": neighbor, "cost": next_cost})
						
	return valid_cells

func draw_move_range(cells: Array[Vector2i]):
	clear_move_range()
	var t_size = PartyManager.active_tile_size
	for cell in cells:
		var rect = ColorRect.new()
		rect.size = Vector2(t_size, t_size)
		rect.position = Vector2(cell.x * t_size, cell.y * t_size)
		rect.color = move_range_color # Veriden okur
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight_container.add_child(rect)

func draw_attack_range(cells: Array[Vector2i]):
	clear_move_range() 
	var t_size = PartyManager.active_tile_size
	for cell in cells:
		var rect = ColorRect.new()
		rect.size = Vector2(t_size, t_size)
		rect.position = Vector2(cell.x * t_size, cell.y * t_size)
		rect.color = attack_range_color # Veriden okur
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight_container.add_child(rect)

func draw_deployment_zone(cells: Array[Vector2i]):
	clear_move_range() 
	var t_size = PartyManager.active_tile_size
	for cell in cells:
		var rect = ColorRect.new()
		rect.size = Vector2(t_size, t_size)
		rect.position = Vector2(cell.x * t_size, cell.y * t_size)
		rect.color = deployment_zone_color # Veriden okur
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight_container.add_child(rect)

func clear_move_range():
	if highlight_container:
		for child in highlight_container.get_children():
			child.queue_free()
