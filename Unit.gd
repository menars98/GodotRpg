# unit.gd
class_name Unit
extends Area2D # Fizik motoruna ihtiyaç olmadığı için Area2D seçtik

@export var stats: UnitStats

@export var grid_pos := Vector2i(0, 0)
var movement_left: int = 0
var is_moving := false
var has_moved := false
var has_acted := false 

# Hareket bittiğinde Main scriptine haber vermek için sinyal tanımlıyoruz
signal movement_finished

func _ready() -> void:
	var t_size = PartyManager.active_tile_size
	# EĞER: Editörde birimi elinle sürükleyip bıraktıysan ve grid_pos (0,0) olarak kaldıysa,
	# durduğu yerin koordinatlarından grid pozisyonunu otomatik olarak hesaplasın:
	if grid_pos == Vector2i(0, 0) and position != Vector2.ZERO:
		grid_pos = Vector2i(floor(position.x / t_size), floor(position.y / t_size))
		
	if stats:
		stats = stats.duplicate()
		movement_left = stats.move_range
		if has_node("AnimatedSprite2D") and stats.sprite_frames:
			$AnimatedSprite2D.sprite_frames = stats.sprite_frames
			
	# Tam kare hücresinin ortasına hizala
	position = grid_to_world(grid_pos)
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("idle")

func grid_to_world(gpos: Vector2i) -> Vector2:
	var t_size = PartyManager.active_tile_size
	return Vector2(gpos.x * t_size + t_size / 2.0,
				   gpos.y * t_size + t_size / 2.0)

# Bu fonksiyon artık Unit'in kendi içinde yer alıyor
func move_along_path(path: Array[Vector2i]):
	if path.is_empty():
		movement_finished.emit()
		return
		
	is_moving = true
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("walk") # Varsa yürüme animasyonu
	
	var tween = create_tween()
	
	for point in path:
		var target_world_pos = grid_to_world(point)
		# 0.15 saniyede bir sonraki kareye yumuşak geçiş yap
		tween.tween_property(self, "position", target_world_pos, 0.15)
		# Her kareye ulaştığında birimin grid pozisyonunu güncelle
		tween.tween_callback(func(): grid_pos = point)
		
	# Tüm tween hareketleri bittiğinde tetiklenecek fonksiyonu bağlıyoruz
	tween.finished.connect(_on_movement_finished)

func _on_movement_finished():
	is_moving = false
	has_moved = true # Tur içinde hareket ettiğini işaretle
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("idle")
			# Yukarıdaki Main sahnesine hareketin tamamlandığını haber veriyoruz
	movement_finished.emit()
	
