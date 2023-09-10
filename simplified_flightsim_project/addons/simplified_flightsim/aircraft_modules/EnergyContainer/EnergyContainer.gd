extends AircraftModule
class_name AircraftModule_EnergyContainer

signal update_interface(values)

@export var ContainerActive: bool = true

@export var MaxCapacity: float = 100.0

@onready var current_level = MaxCapacity

# You don't really *need* to use this property, as any node can receive the
# signals. This is just a helper to automatically connect all possible signals
# assigning the node just once 
@export var UINode: NodePath
@onready var ui_node = get_node_or_null(UINode)

func _ready():
	if ui_node:
		connect("update_interface", Callable(ui_node, "update_interface"))
	
	ModuleType = "energy_container"

func setup(aircraft_node):
	aircraft = aircraft_node
	request_update_interface()

# ----------------------------------------------------------------------------


func request_update_interface():
	var message = {
		"energy_level": current_level,
		"energy_soc": (current_level / MaxCapacity), # state of charge = normalized to full
		"energy_max": MaxCapacity,
		"energy_active": ContainerActive,
	}
	emit_signal("update_interface", message)

func energy_container_toggle_active():
	ContainerActive = not ContainerActive
	request_update_interface()

func consume_energy(value: float) -> bool:
	# Returns true when empty
	current_level = max(current_level - value, 0.0)
	request_update_interface()
	return (current_level == 0)

func load_energy(value: float) -> bool:
	# Returns true when full
	current_level = min(current_level + value, MaxCapacity)
	request_update_interface()
	return (current_level == MaxCapacity)
