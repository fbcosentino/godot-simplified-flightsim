# This script is just an example of one way to implement a control module
# the way input is handled here is by no means a requirement whatsoever
# You can (and are actually expected to) modify this or write your own module

# ControlFlaps.gd -> shows an example of hardcoded key input via Input.is_key_pressed()
#   passing a keycode
# 
# ControlLandingGear.gd -> shows an example of hardcoded key input via matching
#   event.keycode against a list of keycodes
# 
# ControlEnergyContainer.gd and ControlEngine.gd -> show example of configuring key inputs
#   via keycodes assigned via @export var from a list of keys
# 
# ControlSteering.gd -> shows an example of input handling via input map from the Godot project
#   settings (which is probably what you should do for a regular game)

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
