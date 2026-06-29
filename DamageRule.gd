class_name DamageRule
extends Resource

# Editörde kolayca seçebilmek için hasar ve zırh tiplerini açıyoruz
@export_enum("SLASH", "PIERCE", "BLUNT", "MAGIC") var damage_type: int = 0
@export_enum("UNARMORED", "LIGHT", "HEAVY", "FLYING") var armor_type: int = 0
@export var multiplier: float = 1.0 # Hasar Çarpanı (Örn: 1.3 = %+30 Hasar)
