extends AircraftModule
class_name AircraftModule_ControlEnergyContainer

# Restricting containers to a tag can be used to control a group of containers only
# e.g. you can use RestrictEnergyContainerToTag=true and SearchTag="3" in the 
# inspector to control only the container with the "3" tag 
export(bool) var RestrictEnergyContainerToTag = false
export(String) var SearchTag = ""
export(bool) var ControlActive = true

export(KeyScancodes) var KeyToggle = KeyScancodes.KEY_Z

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
			match event.scancode:
				KeyToggle:
					send_to_energy_containers("energy_container_toggle_active")

func send_to_energy_containers(method_name: String, arguments: Array = []):
	for container in energy_containers:
		container.callv(method_name, arguments)
