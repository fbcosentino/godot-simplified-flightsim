extends Node3D

@export var AircraftNode: NodePath
@onready var aircraft = get_node_or_null(AircraftNode)

@export var StartShowingTemperature: float = 100.0

var mat : StandardMaterial3D

var is_showing = false

func _ready():
	# Material must be made unique in order to have independent mesh copies
	mat = $MeshInstance3D.get_surface_override_material(0).duplicate()
	$MeshInstance3D.set_surface_override_material(0, mat)

func _process(_delta):
	if is_instance_valid(aircraft):
		var temp_factor = clamp( (aircraft.local_temperature - StartShowingTemperature) / (aircraft.MaxTemperature - StartShowingTemperature) , 0.0, 1.0)
		if temp_factor > 0:
			if not is_showing:
				is_showing = true
				show()
			mat.albedo_color = lerp(Color.BLACK, Color.WHITE, temp_factor)
		
		elif is_showing:
			is_showing = false
			hide()
			mat.albedo_color = Color.BLACK
