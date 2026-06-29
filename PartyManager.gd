# partymanager.gd (Autoload / Singleton)
# Bu script tüm sahnelerde arka planda yaşar ve kahramanların verisini korur.
extends Node

# Oyuncunun şu ana kadar topladığı kahramanların listesi (UnitStats kopyaları)
var active_heroes: Array[UnitStats] = []
var active_tile_size: float = 16.0

func _ready():
	var archer_base = load("res://Resources/archer_stats.tres")
	if archer_base:
		var dupe = archer_base.duplicate()
		active_heroes.append(dupe)
		print("DEBUG: Diskten Okçu Yüklendi. Adı: ", dupe.unit_name) # Konsolda "Archer" yazmalı
		
	
