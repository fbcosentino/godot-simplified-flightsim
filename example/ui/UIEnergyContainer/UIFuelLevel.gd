extends Control


# EnergyContainer module sends the following dictionary:
# values = {
#     "energy_level": float,           # current energy level
#     "energy_soc": float <0.0 - 1.0>, # state-of-charge: 0.0=empty, 1.0=full
#     "energy_max": float,             # maximum capacity
#     "energy_active": bool,           # if this energy container is connected
# }

@export var ActiveColor: Color = Color(0.9, 0.9, 0.5, 1.0)
@export var Caption: String = "Fuel"

func _ready():
	$Panel/Label.text = Caption
	$Panel/Bar.tint_progress = ActiveColor

func update_interface(values: Dictionary):
	$Panel/Bar.value = values["energy_soc"]
	$Panel/Bar.tint_progress = ActiveColor if values["energy_active"] else Color(0.5,0.5,0.5,1.0)
