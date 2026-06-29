# progression_table.gd
class_name ProgressionTable
extends Resource

# Editörde hata vermeden pürüzsüzce listelenen sınıflar dizisi
@export var classes: Array[ClassPromotion] = []

# Belirtilen sınıfın olası terfi yollarını arar ve döner
func get_promotions_for(current_class: String) -> Array[Promotion]:
	for item in classes:
		# DÜZELTME: item.class_name yerine item.base_class okuyoruz
		if item.base_class == current_class:
			return item.promotions
	return []
