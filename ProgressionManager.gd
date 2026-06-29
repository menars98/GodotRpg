# progression_manager.gd

class_name ProgressionManager
extends Node

@export var progression_table: ProgressionTable

# Asenkron XP kazanma (Awaiting seviye atlama)
func gain_xp(main_scene: Node, unit: Unit, amount: int):
	unit.stats.experience += amount
	print(unit.stats.unit_name, " ", amount, " XP kazandı! Toplam: ", unit.stats.experience)
	
	while unit.stats.experience >= 100:
		unit.stats.experience -= 100
		await _level_up(main_scene, unit) # OK butonuna basılana kadar bekler

# Asenkron Seviye Atlama (Awaiting OK butonu ve Terfi Menüsü)
func _level_up(main_scene: Node, unit: Unit):
	unit.stats.level += 1
	
	var hp_add = unit.stats.hp_growth
	var atk_add = unit.stats.attack_growth
	var def_add = unit.stats.defense_growth
	
	unit.stats.max_hp += hp_add
	unit.stats.attack += atk_add
	unit.stats.defense += def_add
	unit.stats.speed += unit.stats.speed_growth
	unit.stats.hp = unit.stats.max_hp
	
	print("!!! SEVİYE ATLADI !!! Yeni Seviye: ", unit.stats.level)
	
	# Ekranda Seviye Atlama kartını göster
	if main_scene.has_method("show_level_up_panel"):
		main_scene.show_level_up_panel(unit, hp_add, atk_add, def_add)
		
	# Oyuncu [OK] butonuna basana kadar bu fonksiyonun çalışmasını DURDUR!
	await main_scene.level_up_completed
	
	# OK butonuna basıldıktan sonra terfi kontrolünü tetikle ve onun da bitmesini BEKLE (await)
	await _check_for_promotion(main_scene, unit)

# Asenkron Terfi Kontrolü (Awaiting Sınıf Seçim Butonları)
func _check_for_promotion(main_scene: Node, unit: Unit):
	if progression_table == null:
		return
		
	var current_class = unit.stats.unit_name
	var rules = progression_table.get_promotions_for(current_class)
	
	if rules.size() > 0:
		var available_promotions: Array[Promotion] = []
		for promo in rules:
			if unit.stats.level >= promo.required_level:
				available_promotions.append(promo)
				
		if available_promotions.size() == 1:
			execute_promotion(unit, available_promotions[0])
		elif available_promotions.size() > 1:
			# Seçim menüsünü aç
			main_scene.show_promotion_choice_menu(unit, available_promotions)
			# Oyuncu yeni sınıfını seçene kadar bu fonksiyonun çalışmasını DURDUR!
			await main_scene.promotion_completed

func execute_promotion(unit: Unit, promo: Promotion):
	if promo == null: return
	print("!!! EVRİM GERÇEKLEŞTİ !!! ", unit.stats.unit_name, " -> ", promo.new_class_name)
	
	unit.stats.unit_name = promo.new_class_name
	unit.stats.max_hp += promo.bonus_max_hp
	unit.stats.hp = unit.stats.max_hp
	unit.stats.attack += promo.bonus_attack
	unit.stats.defense += promo.bonus_defense
	unit.stats.speed += promo.bonus_speed
	
	unit.stats.hp_growth = promo.new_hp_growth
	unit.stats.attack_growth = promo.new_attack_growth
	unit.stats.defense_growth = promo.new_defense_growth
	unit.stats.speed_growth = promo.new_speed_growth
	
	if promo.new_sprite_frames:
		if unit.has_node("AnimatedSprite2D"):
			unit.get_node("AnimatedSprite2D").sprite_frames = promo.new_sprite_frames
			unit.get_node("AnimatedSprite2D").play("idle")
			
	print("Tebrikler! Karakteriniz başarıyla terfi etti: ", unit.stats.unit_name)
