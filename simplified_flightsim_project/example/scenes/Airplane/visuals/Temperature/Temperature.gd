extends Spatial

export(NodePath) var AircraftNode
onready var aircraft = get_node_or_null(AircraftNode)

export(float) var StartShowingTemperature = 100.0

var mat : SpatialMaterial

var is_showing = false

func _ready():
	# Material must be made unique in order to have independent mesh copies
	mat = $MeshInstance.get_surface_material(0).duplicate()
	$MeshInstance.set_surface_material(0, mat)

func _process(_delta):
	if is_instance_valid(aircraft):
		var temp_factor = clamp( (aircraft.local_temperature - StartShowingTemperature) / (aircraft.MaxTemperature - StartShowingTemperature) , 0.0, 1.0)
		if temp_factor > 0:
			if not is_showing:
				is_showing = true
				show()
			mat.albedo_color = lerp(Color.black, Color.white, temp_factor)
		
		elif is_showing:
			is_showing = false
			hide()
			mat.albedo_color = Color.black
