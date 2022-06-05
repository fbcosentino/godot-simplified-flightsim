extends Control

# flaps module sends the following dictionary:
# values = {
#     "flap": float <0.0 - 1.0>
# }

func update_interface(values: Dictionary):
	$Panel/FlapDial.rect_rotation = values["flap"]*(-45)
