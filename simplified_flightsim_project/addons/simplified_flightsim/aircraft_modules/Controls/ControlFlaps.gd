extends AircraftModule
class_name AircraftModule_ControlFlaps

export(bool) var ControlActive = true

# There should be only one flaps and one flaps control in the aircraft
var flaps_module = null

func _ready():
	ReceiveInput = true


func setup(aircraft_node):
	aircraft = aircraft_node
	flaps_module = aircraft.find_modules_by_type("flaps").pop_front()
	print("flaps found: %s" % str(flaps_module))

func receive_input(event):
	if (not flaps_module) or (not ControlActive):
		return
	
	if (event is InputEventKey) and (not event.echo):
		
		if Input.is_key_pressed(KEY_G):
			flaps_module.flap_increase_position(-0.2)
		if Input.is_key_pressed(KEY_B):
			flaps_module.flap_increase_position(0.2)
