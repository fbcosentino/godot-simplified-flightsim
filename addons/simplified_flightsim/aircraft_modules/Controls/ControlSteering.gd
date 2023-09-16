# This script is just an example of one way to implement a control module
# the way input is handled here is by no means a requirement whatsoever
# You can (and are actually expected to) modify this or write your own module

extends AircraftModule
class_name AircraftModule_ControlSteering

@export var ControlActive: bool = true

# There should be only one steering and one steering control in the aircraft
var steering_module = null

func _ready():
	ReceiveInput = true


func setup(aircraft_node):
	aircraft = aircraft_node
	steering_module = aircraft.find_modules_by_type("steering").pop_front()
	print("steering found: %s" % str(steering_module))

func receive_input(event):
	if (not steering_module) or (not ControlActive):
		return
	
	if (event is InputEventKey) and (not event.echo):
		
		var axis_z = 0.0
		if Input.is_key_pressed(KEY_A):
			axis_z -= 1.0
		if Input.is_key_pressed(KEY_D):
			axis_z += 1.0
		
		steering_module.set_z(axis_z)
		
		var axis_x = 0.0
		if Input.is_key_pressed(KEY_W):
			axis_x -= 1.0
		if Input.is_key_pressed(KEY_S):
			axis_x += 1.0
		
		steering_module.set_x(axis_x)
		
		# Y axis positive turns plane left
		var axis_y = 0.0
		if Input.is_key_pressed(KEY_Q):
			axis_y += 1.0
		if Input.is_key_pressed(KEY_E):
			axis_y -= 1.0
		
		steering_module.set_y(axis_y)
