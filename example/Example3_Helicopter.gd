extends Node3D


var template_explosion = preload("res://example/scenes/Explosion/Explosion.tscn")

@onready var aircraft = get_node("Aircraft")

var is_reloading_fuel = false

var achievement_unlocked = false

func _on_Aircraft_crashed(_impact_velocity):
	var new_explosion = template_explosion.instantiate()
	add_child(new_explosion)
	new_explosion.global_transform.origin = $Aircraft.global_transform.origin
	new_explosion.explode()
	aircraft.queue_free()
	await get_tree().create_timer(2.0).timeout
	var __= get_tree().reload_current_scene()


func _on_Aircraft_parked():
	print("PARKED")
	if $FuelArea1.overlaps_body(aircraft):
		# Parked on runway - refuel
		is_reloading_fuel = true
		print("RELOADING FUEL")
	
	if $FuelArea2.overlaps_body(aircraft):
		# Parked on pad - refuel
		is_reloading_fuel = true
		print("RELOADING FUEL")
		if not achievement_unlocked:
			achievement_unlocked = true
			$Interface/Achievement/AnimationPlayer.play("Show")


func _on_Aircraft_moved():
	# Started moving, if reloading fuel, stop
	if is_reloading_fuel:
		is_reloading_fuel = false
		print("REFUEL STOPPED")

func _physics_process(delta):
	if is_reloading_fuel and is_instance_valid(aircraft):
		var amount_per_second = 5.0
		var is_aircraft_full = aircraft.load_energy("fuel", amount_per_second * delta)
		if is_aircraft_full:
			is_reloading_fuel = false
			print("REFUEL COMPLETE")


func _on_BtnBack_pressed():
	get_tree().change_scene_to_file("res://example/ExampleList.tscn")
