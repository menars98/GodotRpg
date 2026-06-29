# cursor.gd
class_name GridCursor
extends Sprite2D

var tween: Tween
var grid_pos := Vector2i(0, 0)
var map_limit := Rect2i(0, 0, 10, 10) # Main'deki harita sınırıyla aynı olmalı

signal cursor_moved(new_pos: Vector2i)
signal cursor_selected(pos: Vector2i) # Enter veya Mouse Sol Click
signal cursor_canceled

func _ready():
	position = grid_to_world(grid_pos)

func _unhandled_input(event: InputEvent) -> void:
	# 1. Klavye Girişleri
	var input_dir := Vector2i.ZERO
	if event.is_action_pressed("ui_up"):    input_dir = Vector2i.UP
	elif event.is_action_pressed("ui_down"):  input_dir = Vector2i.DOWN
	elif event.is_action_pressed("ui_left"):  input_dir = Vector2i.LEFT
	elif event.is_action_pressed("ui_right"): input_dir = Vector2i.RIGHT
	
	if input_dir != Vector2i.ZERO:
		var target_pos = grid_pos + input_dir
		if map_limit.has_point(target_pos): # Kesin sınır kontrolü
			_update_grid_pos(target_pos)
			get_viewport().set_input_as_handled()
			
	# 2. Mouse Hareketi
	if event is InputEventMouseMotion:
		var mouse_grid = world_to_grid(get_global_mouse_position())
		# Mouse koordinatı harita limitleri içindeyse ve hareket ettiyse güncelle
		if map_limit.has_point(mouse_grid) and mouse_grid != grid_pos:
			_update_grid_pos(mouse_grid)

	# 3. Seçim Girişi (Enter veya Mouse Sol Tık)
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		cursor_selected.emit(grid_pos)
		get_viewport().set_input_as_handled()
		
	# 4. İptal Girişi (Sağ Tık veya Esc/Back tuşu)
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed) or event.is_action_pressed("ui_cancel"):
		cursor_canceled.emit()
		get_viewport().set_input_as_handled()

func _update_grid_pos(new_pos: Vector2i):
	grid_pos = new_pos
	cursor_moved.emit(grid_pos)
	
	# Eğer çalışan eski bir kayma hareketi varsa onu durdur
	if tween:
		tween.kill()
		
	# Yeni kayma hareketini başlat (0.08 saniye çok akıcı hissettirir)
	tween = create_tween()
	var target_world_pos = grid_to_world(grid_pos)
	tween.tween_property(self, "position", target_world_pos, 0.08)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func grid_to_world(gpos: Vector2i) -> Vector2:
	var t_size = PartyManager.active_tile_size
	return Vector2(gpos.x * t_size + t_size / 2.0, gpos.y * t_size + t_size / 2.0)

func world_to_grid(wpos: Vector2) -> Vector2i:
	var t_size = PartyManager.active_tile_size
	return Vector2i(floor(wpos.x / t_size), floor(wpos.y / t_size))
