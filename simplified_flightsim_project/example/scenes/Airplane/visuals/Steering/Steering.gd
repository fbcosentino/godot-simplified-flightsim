extends Node3D



# Any node can receive the "update_interface" signals from the Airplane modules
# This can be used to show realtime representations using the same data
# as the UI controls

var target_aileron_angle = 0.0
var target_elevator_angle = 0.0
var target_rudder_angle = 0.0

func _on_Steering_update_interface(values):
	if values["energy_failed"]:
		target_aileron_angle = 0.0
		target_elevator_angle = 0.0
		target_rudder_angle = 0.0
	else:
		target_aileron_angle = deg_to_rad(values["axis_z"]*60.0)
		target_elevator_angle = deg_to_rad(values["axis_x"]*60.0)
		target_rudder_angle = deg_to_rad(values["axis_y"]*60.0)

func _process(delta):
	$AileronLeft.rotation.x = lerp($AileronLeft.rotation.x, target_aileron_angle, delta*5.0)
	$AileronRight.rotation.x = lerp($AileronRight.rotation.x, -target_aileron_angle, delta*5.0)
	$Elevator.rotation.x = lerp($Elevator.rotation.x, -target_elevator_angle, delta*5.0)
	$Rudder.rotation.y = lerp($Rudder.rotation.y, -target_rudder_angle, delta*5.0)
	
