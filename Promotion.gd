# promotion.gd
class_name Promotion
extends Resource

@export var required_level: int = 3
@export var new_class_name: String = "Lord"

# --- TEK SEFERLİK EVRİM BONUSLARI (Promotion Bonuses) ---
@export var bonus_max_hp: int = 15
@export var bonus_attack: int = 5
@export var bonus_defense: int = 3
@export var bonus_speed: int = 1

# --- YENİ SINIFIN BÜYÜME ORANLARI (New Growth Rates) ---
@export var new_hp_growth: int = 10
@export var new_attack_growth: int = 2
@export var new_defense_growth: int = 4
@export var new_speed_growth: int = 1

# Yeni sınıfın animasyon paketi
@export var new_sprite_frames: SpriteFrames
