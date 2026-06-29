# combat_manager.gd
class_name CombatManager
extends Node

# Editörden sürükleyip bırakacağımız hasar veri tablomuz (Damage Matrix)
@export var damage_matrix: DamageMatrix

func execute_combat(main_scene: Node, attacker: Unit, defender: Unit):
	print("--- SAVAŞ BAŞLADI (CombatManager) ---")
	
	var modifier = 1.0
	if damage_matrix:
		modifier = damage_matrix.get_modifier(attacker.stats.damage_type, defender.stats.armor_type)
	
	var base_damage = attacker.stats.attack - defender.stats.defense
	var damage = int(max(1, base_damage) * modifier)
	
	if modifier > 1.1:
		print("Kritik Zayıflık! Etkili Vuruş!")
	elif modifier < 0.9:
		print("Zırh Güçlü! Etkisiz Vuruş!")
		
	defender.stats.hp -= damage
	print(defender.stats.unit_name, " ", damage, " hasar aldı! Can: ", defender.stats.hp, "/", defender.stats.max_hp)
	
	# Karşı Saldırı Kontrolü
	if defender.stats.hp > 0:
		var counter_modifier = 1.0
		if damage_matrix:
			counter_modifier = damage_matrix.get_modifier(defender.stats.damage_type, attacker.stats.armor_type)
			
		var base_counter_damage = defender.stats.attack - attacker.stats.defense
		var counter_damage = int(max(1, base_counter_damage) * counter_modifier)
		
		attacker.stats.hp -= counter_damage
		print(attacker.stats.unit_name, " karşı saldırıdan ", counter_damage, " hasar aldı!")
		
		# A. SALDIRAN DÜŞMANIN KARŞI ATANLA ÖLMESİ DURUMU (Yapay zeka turunda ölüm)
		if attacker.stats.hp <= 0:
			print(attacker.stats.unit_name, " SAVAŞTA ÖLDÜ!")
			_kill_unit(main_scene, attacker)
			
			if attacker.stats.is_enemy and not defender.stats.is_enemy:
				await main_scene.progression.gain_xp(main_scene, defender, 200)
				
			# ÇÖZÜM: Tüm seviye/terfi işleri bitti. Savaş hala aktifse oyunu devam ettir (Unpause)!
			if main_scene.is_combat_active:
				main_scene.get_tree().paused = false
				if main_scene.has_node("Cursor"):
					main_scene.get_node("Cursor").set_process_unhandled_input(true)
					
			main_scene.check_game_over_conditions()
				
	# B. SAVUNAN DÜŞMANIN İLK ATANLA ÖLMESİ DURUMU (Oyuncu turunda ölüm)
	else:
		print(defender.stats.unit_name, " ÖLDÜ!")
		_kill_unit(main_scene, defender)
		
		if defender.stats.is_enemy and not attacker.stats.is_enemy:
			await main_scene.progression.gain_xp(main_scene, attacker, 200)
			
		# ÇÖZÜM: Tüm seviye/terfi işleri bitti. Savaş hala aktifse oyunu devam ettir (Unpause)!
		if main_scene.is_combat_active:
			main_scene.get_tree().paused = false
			if main_scene.has_node("Cursor"):
				main_scene.get_node("Cursor").set_process_unhandled_input(true)
				
		main_scene.check_game_over_conditions()

func _kill_unit(main_scene: Node, unit: Unit):
	main_scene.grid.astar.set_point_solid(unit.grid_pos, false)
	main_scene.grid_units.erase(unit.grid_pos)
	unit.queue_free()

# Yardımcı Fonksiyon (check_game_over içermeyen temiz silme):
func _kill_unit_no_check(main_scene: Node, unit: Unit):
	main_scene.grid.astar.set_point_solid(unit.grid_pos, false)
	main_scene.grid_units.erase(unit.grid_pos)
	unit.queue_free()
