# class_promotion.gd
class_name ClassPromotion
extends Resource

@export var base_class: String = "Fighter"
# Bu sınıfın evrimleşebileceği dalların listesi (.tres dosyaları)
@export var promotions: Array[Promotion] = []
