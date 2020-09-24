# gdscript: processed-food-abstract.gd

extends StaticBody2D

# TODO: I need to refactor the code to have a common base scene between
# processed and unprocessed foods
var signature = null

# food varieties
enum  {
	GOOD,
	BAD
}

var variety = null

func _ready():
	connect("edible_exhausted", self, "_on_edible_exhausted")
	connect("edible_consumed", self, "_on_edible_consumed")

func is_good():
	return variety == GOOD
	
func is_bad():
	return variety == BAD
	
func init_from_unprocessed_food(unprocessed_food_node):
	global_position = unprocessed_food_node.global_position
	
	signature = unprocessed_food_node.signature
	variety = unprocessed_food_node.variety
	
	# TODO: This is ugly. Need to refactor to have the radii as
	# top-level attributes of a scent area, and the scent areas
	# be accessible as a collection variable
	for scent_area in unprocessed_food_node.get_node("Smell/ScentAreas").get_children():
		$Smell.add_scent_area(scent_area.radius, signature)			
	
	$Taste.set_signature(signature)

func _on_edible_consumed():
	print("edible consumed")
	
func _on_edible_exhausted():
	print("edible exhausted")
