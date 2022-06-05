extends Control

# Engine control module sends the following dictionary:
# values = {
#     "engine_active": bool,
#     "engine_power": float <0.0 - 1.0>
# }

func update_interface(values: Dictionary):
	$Panel/OnlineBox.color = Color.green if values["engine_active"] else Color.red
	$Panel/PowerBar/Cursor.rect_position.y = (1.0-values["engine_power"]) * 80#px
