# This script is just an example of one way to implement a control module
# the way input is handled here is by no means a requirement whatsoever
# You can (and are actually expected to) modify this or write your own module

extends AircraftModule
class_name AircraftModule_ControlFlaps

@export var ControlActive: bool = true

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
