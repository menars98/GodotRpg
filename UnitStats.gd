# unit_stats.gd
class_name UnitStats
extends Resource

enum DamageType { SLASH, PIERCE, BLUNT, MAGIC }
enum ArmorType { UNARMORED, LIGHT, HEAVY, FLYING }

@export var unit_name: String = "Fighter"
@export var max_hp: int = 100
@export var hp: int = 100
@export var attack: int = 20
@export var defense: int = 10
@export var move_range: int = 3
@export var is_enemy: bool = false
@export var speed: int = 10
@export var sprite_frames: SpriteFrames
@export var exploration_speed: float = 140.0

@export var level: int = 1
@export var experience: int = 0

# VERİ ODAKLI YENİ EKLEMELER:
@export var damage_type: DamageType = DamageType.SLASH
@export var armor_type: ArmorType = ArmorType.UNARMORED

# --- SEVİYE BAŞINA BÜYÜME ORANLARI (Growth Rates) ---
@export var hp_growth: int = 6        # Seviye atladıkça gelecek HP miktarı
@export var attack_growth: int = 4    # Seviye atladıkça gelecek ATK miktarı
@export var defense_growth: int = 2   # Seviye atladıkça gelecek DEF miktarı
@export var speed_growth: int = 1     # Seviye atladıkça gelecek Hız miktarı
