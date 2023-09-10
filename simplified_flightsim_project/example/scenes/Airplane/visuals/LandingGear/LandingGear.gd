extends Node3D


# Any node can receive the "update_interface" signals from the Airplane modules
# This can be used to show realtime representations using the same data
# as the UI controls


func _on_LandingGear_update_interface(values):
	if values["lgear_stowing"]:
		$AnimationPlayer.play("Stow")
	if values["lgear_deploying"]:
		$AnimationPlayer.play("Deploy")
	
	if values["lgear_up"]:
		$AnimationPlayer.play("Stow", -1, 1.0, true) # move to end
	if values["lgear_down"]:
		$AnimationPlayer.play("Deploy", -1, 1.0, true) # move to end
