extends Control

# InstrumentAttitude module sends the following dictionary:
# values = {
#     "roll": float <-180.0 - +180.0>
#     "pitch": float <-90.0 - +90.0>
#     "bearing": float <-90.0 - +90.0>
# }

func update_interface(values: Dictionary):
	$Panel/Horizon/InnerPanel/CenterRef.rotation_degrees = -values["roll"]
	$Panel/Horizon/InnerPanel/CenterRef/Ground.position.y = (values["pitch"]/90.0)*71.0
	$Panel/Compass/InnerPanel/CenterRef.rotation_degrees = (-values["bearing"])
	$UIGForce/Panel/Bar.value = values["g"]
