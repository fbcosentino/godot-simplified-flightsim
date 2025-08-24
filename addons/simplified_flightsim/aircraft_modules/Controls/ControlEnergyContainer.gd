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
class_name AircraftModule_ControlEnergyContainer

# Restricting containers to a tag can be used to control a group of containers only
# e.g. you can use RestrictEnergyContainerToTag=true and SearchTag="3" in the 
# inspector to control only the container with the "3" tag 
@export var RestrictEnergyContainerToTag: bool = false
@export var SearchTag: String = ""
@export var ControlActive: bool = true

@export var KeyToggle: KeyScancodes = KeyScancodes.KEY_Z

var energy_containers = []

func _ready():
	ReceiveInput = true
	
func setup(aircraft_node):
	aircraft = aircraft_node
	if RestrictEnergyContainerToTag:
		energy_containers = aircraft.find_modules_by_type_and_tag("energy_container", SearchTag)
	else:
		energy_containers = aircraft.find_modules_by_type("energy_container")
	print("energy containers found: %s" % str(energy_containers))

func receive_input(event):
	if not ControlActive:
		return
	
	if (event is InputEventKey) and (not event.echo):
		if event.pressed:
			match event.keycode:
				KeyToggle:
					send_to_energy_containers("energy_container_toggle_active")

func send_to_energy_containers(method_name: String, arguments: Array = []):
	for container in energy_containers:
		container.callv(method_name, arguments)
