extends Node3D



# Any node can receive the "update_interface" signals from the Airplane modules
# This can be used to show realtime representations using the same data
# as the UI controls

func _on_Steering_update_interface(values):
		var is_roll_r = (values["axis_z"] > 0)
		var is_roll_l = (values["axis_z"] < 0)
		
		var is_pitch_u = (values["axis_x"] > 0)
		var is_pitch_d = (values["axis_x"] < 0)
		
		var is_yaw_r = (values["axis_y"] < 0)
		var is_yaw_l = (values["axis_y"] > 0)
		
		$RollLD.visible = is_roll_r
		$RollRU.visible = is_roll_r
		
		$RollLU.visible = is_roll_l
		$RollRD.visible = is_roll_l
		
		$PitchBU.visible = is_pitch_u
		$PitchFD.visible = is_pitch_u
		
		$PitchBD.visible = is_pitch_d
		$PitchFU.visible = is_pitch_d
		
		$YawFL.visible = is_yaw_r
		$YawBR.visible = is_yaw_r
		
		$YawFR.visible = is_yaw_l
		$YawBL.visible = is_yaw_l
