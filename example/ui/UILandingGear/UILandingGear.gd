extends Control

# flaps module sends the following dictionary:
# values = {
#     "lgear_deploying": bool,
#     "lgear_stowing": bool,
#     "lgear_down": bool,
#     "lgear_up": bool,
# }

func update_interface(values: Dictionary):
	$Panel/GearDeploying.visible = values["lgear_deploying"]
	$Panel/GearDown.visible = values["lgear_down"]
	$Panel/GearStowing.visible = values["lgear_stowing"]
	$Panel/GearUp.visible = values["lgear_up"]
