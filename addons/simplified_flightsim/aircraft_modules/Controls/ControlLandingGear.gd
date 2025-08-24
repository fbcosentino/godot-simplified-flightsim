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
class_name AircraftModule_ControlLandingGear

# Restricting landing gears to a tag can be used to control a group of gears only
# e.g. you can use RestrictGearToTag=true and SearchTag="wheels" in the 
# inspector to control only the gear with the "wheels" tag for landing runways,
# while the ship could also have a "feet" gear to e.g. land upright on mud
@export var RestrictGearToTag: bool = false
@export var SearchTag: String = ""
@export var ControlActive: bool = true

var landing_gear_modules = []

func _ready():
	ReceiveInput = true

func setup(aircraft_node):
	aircraft = aircraft_node
	if RestrictGearToTag:
		landing_gear_modules = aircraft.find_modules_by_type_and_tag("landing_gear", SearchTag)
	else:
		landing_gear_modules = aircraft.find_modules_by_type("landing_gear")
	print("landing_gear found: %s" % str(landing_gear_modules))


func receive_input(event):
	if not ControlActive:
		return
	
	if (event is InputEventKey) and (not event.echo):
		if event.pressed:
			match event.keycode:
				KEY_J:
					send_to_landing_gears("stow")
				KEY_M:
					send_to_landing_gears("deploy")


func send_to_landing_gears(method_name: String, arguments: Array = []):
	for gear in landing_gear_modules:
		gear.callv(method_name, arguments)
