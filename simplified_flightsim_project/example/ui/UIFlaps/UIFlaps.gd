extends Control

# flaps module sends the following dictionary:
# values = {
#     "flap": float <0.0 - 1.0>
# }

func update_interface(values: Dictionary):
	$Panel/FlapDial.rotation_degrees = values["flap"]*(-45)
