# The LandingGear module demonstrates how to deal with timed/animated features
# using states and Timer node callbacks

extends AircraftModuleSpatial
class_name AircraftModule_LandingGear

signal update_interface(values)

@export var GearCollisionShape: NodePath
@onready var landing_gear_collision_shape = get_node_or_null(GearCollisionShape)

enum LandingGearInitialStates {
	STOWED,
	DEPLOYED
}
@export var InitialState: LandingGearInitialStates = LandingGearInitialStates.STOWED

@export var DeployStowTime: float = 1.0 # secs
@export var DeploySound: AudioStream
@export var StowSound: AudioStream

# You don't really *need* to use this property, as any node can receive the
# signals. This is just a helper to automatically connect all possible signals
# assigning the node just once 
@export var UINode: NodePath
@onready var ui_node = get_node_or_null(UINode)

var sfx_player = null

var move_timer = Timer.new()

var is_deploying = false
var is_stowing = false
var is_deployed = false
var is_stowed = true


func _ready():
	add_child(move_timer)
	move_timer.one_shot = true
	move_timer.connect("timeout", Callable(self, "_on_move_timer_timeout"))
	
	if DeploySound or StowSound:
		sfx_player = AudioStreamPlayer.new()
		add_child(sfx_player)
	
	if ui_node:
		connect("update_interface", Callable(ui_node, "update_interface"))
	
	ModuleType = "landing_gear"

func setup(aircraft_node):
	aircraft = aircraft_node
	if landing_gear_collision_shape:
		aircraft.register_safe_collider(landing_gear_collision_shape)
	
	match InitialState:
		LandingGearInitialStates.STOWED:
			is_stowed = true
			is_deployed = false
		
		LandingGearInitialStates.DEPLOYED:
			is_stowed = false
			is_deployed = true
	
	if landing_gear_collision_shape:
		landing_gear_collision_shape.disabled = not is_deployed
	
	request_update_interface()


#func receive_input(event):
#	pass

#func process_physic_frame(delta):
#	pass

#func process_render_frame(delta):
#	pass

func _on_move_timer_timeout():
	if is_deploying:
		_on_deploy_completed()
	if is_stowing:
		_on_stow_completed()


# -----------------------------------------------------------------------------

func request_update_interface():
	var message = {
		"lgear_deploying": is_deploying,
		"lgear_stowing": is_stowing,
		"lgear_down": is_deployed,
		"lgear_up": is_stowed,
	}
	emit_signal("update_interface", message)


func deploy():
	if is_deployed or is_deploying:
		return
	
	var timer_time = DeployStowTime
	var sfx_position = 0.0
	
	# Do we have to abort a stowing process?
	if is_stowing:
		timer_time = DeployStowTime - move_timer.time_left
		sfx_position = move_timer.time_left
		
		move_timer.stop()
		sfx_player.stop()
	
	# Start process
	move_timer.start(timer_time)
	
	if DeploySound:
		sfx_player.stream = DeploySound
		sfx_player.play(sfx_position)
	
	is_deploying = true
	is_stowing = false
	is_stowed = false
	request_update_interface()


func _on_deploy_completed():
	is_deploying = false
	is_deployed = true
	
	if landing_gear_collision_shape:
		landing_gear_collision_shape.disabled = false
	
	request_update_interface()



func stow():
	if is_stowed or is_stowing:
		return
	
	var timer_time = DeployStowTime
	var sfx_position = 0.0
	
	# Do we have to abort a deploying process?
	if is_deploying:
		timer_time = DeployStowTime - move_timer.time_left
		sfx_position = move_timer.time_left
		
		move_timer.stop()
		sfx_player.stop()
	
	# Start process
	move_timer.start(timer_time)
	
	if StowSound:
		sfx_player.stream = StowSound
		sfx_player.play(sfx_position)
	
	is_deployed = false
	is_deploying = false
	is_stowing = true
	
	if landing_gear_collision_shape:
		landing_gear_collision_shape.disabled = true
	
	request_update_interface()


func _on_stow_completed():
	is_stowing = false
	is_stowed = true
	
	request_update_interface()
