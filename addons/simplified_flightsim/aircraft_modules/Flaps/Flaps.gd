# The Flaps module demonstrates how to deal with timed/animated features
# using delta in physics frames

extends AircraftModule
class_name AircraftModule_Flaps

signal update_interface(values)

# When flap is fully deployed, lift is multiplied by this factor
@export var LiftFlapFactor: float = 1.2

# When flap is fully deployed, forward drag is multiplied by this factor
@export var DragFlapFactor: float = 1.25

@export var MoveSpeed: float = 1.0 # movement span per second

# You don't really *need* to use this property, as any node can receive the
# signals. This is just a helper to automatically connect all possible signals
# assigning the node just once 
@export var UINode: NodePath
@onready var ui_node = get_node_or_null(UINode)

@export var FlapSoundLoop: AudioStream

var sfx_player = null

var flap_position = 0.0
var target_flap_position = 0.0
var is_moving = false

func _ready():
	if FlapSoundLoop:
		sfx_player = AudioStreamPlayer.new()
		add_child(sfx_player)
		sfx_player.stream = FlapSoundLoop
	
	ProcessPhysics = true
	ModuleType = "flaps"
	
	if ui_node:
		connect("update_interface", Callable(ui_node, "update_interface"))

func setup(aircraft_node):
	aircraft = aircraft_node
	request_update_interface()

func request_update_interface():
	var message = {
		"flap": target_flap_position
	}
	emit_signal("update_interface", message)

func process_physic_frame(delta):
	if not aircraft:
		return
	
	# Move flap
	if is_moving:
		var frame_move_delta = MoveSpeed * delta
		# Close enough to complete it?
		if abs(target_flap_position - flap_position) <= frame_move_delta:
			# Just complete it
			flap_position = target_flap_position
			is_moving = false
			sfx_player.stop()
		else:
			# Still some way to go
			flap_position += (frame_move_delta) if target_flap_position > flap_position else (-frame_move_delta)
	
	
	# Apply effects
	if flap_position > 0:
		aircraft.lift_intensity *= lerp(1.0, LiftFlapFactor, flap_position)
		aircraft.drag_intensity_vector.z *= lerp(1.0, DragFlapFactor, flap_position)



func flap_set_position(value: float):
	if flap_position == value:
		return
	
	target_flap_position = value
	if not is_moving:
		is_moving = true
		if FlapSoundLoop:
			sfx_player.play()
	
	request_update_interface()

func flap_increase_position(step: float):
	var new_value = clamp(flap_position + step, 0.0, 1.0)
	if new_value != flap_position:
		flap_set_position(new_value)
