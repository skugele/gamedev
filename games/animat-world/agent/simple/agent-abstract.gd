extends KinematicBody2D

#################
# exported vars #
#################
export(float) var MAX_SPEED = 500
export(float) var MAX_ROTATION = 1.5
export(float) var MAX_MANDIBLE_APERATURE_IN_DEGREES = 45

export(float) var APERATURE_ACCELERATION = 400
export(int) var ACCELERATION = 500
export(int) var FRICTION = 5000

#############
# constants #
#############


################
# onready vars #
################
onready var id = null

# references to sensors and effectors
onready var hairs = []
onready var antennae = []
onready var mandibles = []

# indicators of sensory activity

# tactile
onready var active_hairs = [] # 1d int array
onready var active_antennae = [] # 1d int array

# olfactory
onready var active_scents = {} # dictionary of scent emitters ids -> active scent areas
onready var ignored_scents = [] # ignore own smells
onready var combined_scent_sig = null

# current state vars
onready var velocity = Vector2.ZERO
onready var mandible_aperature = 0 # in degrees

########
# vars #
########
var signature = null

###########
# signals #
###########
signal hair_activity_change(activity)
signal antennae_activity_change(activity)
signal smell_activity_change(activity)
signal velocity_change(value)
signal rotation_change(value)
signal mandible_aperture_change(value)

#############
# functions #
#############
func _ready():
	id = Globals.generate_unique_id()
	
	init_sensors()
	init_effectors()	

	signature = Globals.normalize([0,0,1,1,1])
	init_scent_areas([100, 250, 500, 1000])

	# build list of ignored smells (i.e., ignore agent's own smells)	
	for area in $Smell/ScentAreas.get_children():
		ignored_scents.append(area)

func _process(delta):
	pass

func get_combined_scent(active_scents):
	var combined_scent_sig = Globals.NULL_SMELL

	for id in active_scents.keys():
		var scent = active_scents[id][-1]
		var distance = distance_from_scent(scent)
		print('distance: ', distance)
		var scaling_factor = 1 - distance / Globals.SMELL_DETECTABLE_RADIUS
		print('scent signature (unscaled): ', scent.signature)
		print('scaling_factor: ', scaling_factor)
		var scaled_scent = Globals.scale(scent.signature, scaling_factor)
		print('scent signature (scaled): ', scaled_scent)

		combined_scent_sig = Globals.add_vectors(combined_scent_sig, scaled_scent)

	return combined_scent_sig

func init_scent_areas(radii):
	for r in radii:
		$Smell.add_scent_area(r, signature)	
			
func get_activity_level():
	
	var combined_scent = get_combined_scent(active_scents)
	print('combined signature: ', combined_scent)
	var level = Globals.get_magnitude(combined_scent)
	
	return level
		

func init_effectors():
	
	# mandibles
	for mandible in $Mandibles.get_children():
		mandibles.append(mandible)
		
	set_mandible_aperature(mandible_aperature)
		
func init_sensors():
	
	# hairs
	var sensor_id = 0
	for hair in $Hairs.get_children():
		hair.id = sensor_id
		hairs.append(hair)
		active_hairs.append(0)
		
		# configure signals
		hair.connect("hair_active", self, "_on_hair_active")
		hair.connect("hair_inactive", self, "_on_hair_inactive")
		
		sensor_id += 1
		
	# antennae
	sensor_id = 0
	for antenna in $Antennae.get_children():
		antenna.id = sensor_id		
		antennae.append(antenna)
		
		active_antennae.append(0)
		
		# configure signals
		antenna.connect("antenna_detected_smell", self, "_on_antenna_detected_smell")
		antenna.connect("antenna_lost_smell", self, "_on_antenna_lost_smell")
		
		antenna.connect("antenna_detected_object", self, "_on_antenna_detected_object")
		antenna.connect("antenna_lost_object", self, "_on_antenna_lost_object")
		
		sensor_id += 1

func set_rotation(degrees):
	rotation = degrees
	
func set_mandible_aperature(degrees):
	mandibles[0].rotation_degrees = degrees
	mandibles[1].rotation_degrees = -degrees
	
func distance_from_scent(scent):
	var distance = Globals.SMELL_DETECTABLE_RADIUS
	
	for antenna in antennae:
		var detector_pos = antenna.smell_detector.global_position
		var scent_pos = scent.global_position
		
		distance = min(distance, detector_pos.distance_to(scent_pos))
	
	return distance
	
func add_scent(scent):	
	if active_scents.has(scent.smell_emitter_id):
		active_scents[scent.smell_emitter_id].push_back(scent)
	else:
		active_scents[scent.smell_emitter_id] = [scent]
	
func remove_scent(scent):
	if len(active_scents[scent.smell_emitter_id]) <= 1:
		active_scents.erase(scent.smell_emitter_id)
	else:
		var removed_scent = active_scents[scent.smell_emitter_id].pop_back()
		print('removing: ', removed_scent)		
		
func _on_hair_active(hair):
	active_hairs[hair.id] += 1
	emit_signal("hair_activity_change", active_hairs)

func _on_hair_inactive(hair):
	active_hairs[hair.id] -= 1
	emit_signal("hair_activity_change", active_hairs)

func _on_antenna_detected_smell(antenna, scent):
	if ignored_scents.find(scent) != -1:
		return
		
	print('adding: ', scent)
	add_scent(scent)
	print(active_scents.values())
	emit_signal("smell_activity_change", get_activity_level())

func _on_antenna_lost_smell(antenna, scent):
	if ignored_scents.find(scent) != -1:
		return
		
	print('removing: ', scent)
	remove_scent(scent)
	print(active_scents.values())
	emit_signal("smell_activity_change", get_activity_level())
	
func _on_antenna_detected_object(antenna, body):
	active_antennae[antenna.id] += 1
	emit_signal("antennae_activity_change", active_antennae)
	
func _on_antenna_lost_object(antenna, body):
	active_antennae[antenna.id] -= 1
	emit_signal("antennae_activity_change", active_antennae)

