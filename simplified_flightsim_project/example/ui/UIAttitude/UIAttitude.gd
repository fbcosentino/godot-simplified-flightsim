extends Control

# InstrumentAttitude module sends the following dictionary:
# values = {
#     "roll": float <-180.0 - +180.0>
#     "pitch": float <-90.0 - +90.0>
#     "bearing": float <-90.0 - +90.0>
# }

func update_interface(values: Dictionary):
	$Panel/Horizon/InnerPanel/CenterRef.rect_rotation = values["roll"]
	$Panel/Horizon/InnerPanel/CenterRef/Ground.rect_position.y = (values["pitch"]/90.0)*71.0
	$Panel/Compass/InnerPanel/CenterRef.rect_rotation = (-values["bearing"])
	$UIGForce/Panel/Bar.value = values["g"]
