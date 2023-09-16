# This UI display demonstrates reading data from the aircraft directly,
# instead of relying on signals from modules

extends Control

@export var AircraftNode: NodePath
@onready var aircraft = get_node_or_null(AircraftNode)

func _process(_delta):
	if aircraft and is_instance_valid(aircraft):
		$Panel/Altitude/InnerPanel/ValueLabel.text = str(round(aircraft.local_altitude*100)/100)
		$Panel/Speed/InnerPanel/ValueLabel.text = str(round(aircraft.air_velocity*100)/100)
