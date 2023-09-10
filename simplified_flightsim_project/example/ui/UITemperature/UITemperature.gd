# This UI display demonstrates reading data from the aircraft directly,
# instead of relying on signals from modules

extends Control

@export var AircraftNode: NodePath
@onready var aircraft = get_node_or_null(AircraftNode)

@onready var bar = $Panel/Bar

func _process(_delta):
	if aircraft and is_instance_valid(aircraft):
		$Panel/TempAircraft/InnerPanel/ValueLabel.text = str(round(aircraft.local_temperature*100)/100)
		$Panel/TempAir/InnerPanel/ValueLabel.text = str(round(aircraft.AirTemperature*100)/100)
		bar.value = clamp( (aircraft.local_temperature + 100.0) / 500.0 , 0.0, 1.0) # -100 to 400
		if aircraft.local_temperature <= 0:
			bar.tint_progress = Color(0.5, 0.5, 1.0, 1.0)
		elif aircraft.local_temperature < 100.0:
			bar.tint_progress = Color(0.5, 1.0, 0.5, 1.0)
		elif aircraft.local_temperature < 300.0:
			bar.tint_progress = Color(1.0, 0.7, 0.0, 1.0)
		else:
			bar.tint_progress = Color(1.0, 0.0, 0.0, 1.0)
