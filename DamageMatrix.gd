class_name DamageMatrix
extends Resource

# Unreal'daki TArray<FDamageRule> gibi satır satır kuralları tutar
@export var rules: Array[DamageRule] = []

# Matrisi tarayıp eşleşen çarpanı döner, kural yoksa 1.0 (normal hasar) döner
func get_modifier(dmg_type: int, arm_type: int) -> float:
	for rule in rules:
		if rule.damage_type == dmg_type and rule.armor_type == arm_type:
			return rule.multiplier
	return 1.0
