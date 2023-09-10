##############################################################################
#  BASE CLASS FOR AIRCRAFT MODULES
# ---------------------------------------------------------------------------
#
# All aircraft modules must inherit this class, and all *MUST* implement
# the setup(aircraft_node) method. All must be placed as direct children of
# an Aircraft node. The properties ReceiveInput, ProcessPhysics and
# ProcessRender, if set, should be set in _ready().
#
# All modules which receive input (ReceiveInput=true) *MUST* have the
# receive_input(event) method implemented (not to be confused with the
# built-in input handling like _input(event), _unhandled_input(event), etc
# which *MUST NOT* be implemented)
#
# All modules which process physics (ProcessPhysics=true) *MUST* have
# the process_physic_frame(delta) implemented (not to be confused with
# the built-in _physics_process(delta) which *MUST NOT* be implemented)
#
# All modules which process visuals/cameras (ProcessRender=true) *MUST*
# have the process_render_frame(delta) method implemented (not to be confused
# with the built-in _process(delta) which *MUST NOT* be implemented)
#
# ModuleType is optional and is a String tag used by other modules to find
# this one. E.g. if all engines have ModuleType="engine", any module can
# find the engine modules by searching for modules with ModuleType == "engine"
# ModuleType must be set in _ready()
# The same applies to ModuleTags, except being an Array of String
#
# The order processing between modules is the scene tree order, and within 
# a same module:
#     setup() is called from Aircraft setup
#     receive_input() is called in sync with the Aircraft's _unhandled_input
#     process_physic_frame() is called in sync with Aircraft's _physics_process
#     process_render_frame() is called in sync with Aircraft's _process


@icon("res://addons/simplified_flightsim/aircraft_modules/AircraftModule_Node_icon.png")
class_name AircraftModule
extends Node


enum KeyScancodes {
	KEY_NONE = -1,
	KEY_SPACE = Key.KEY_SPACE,
	KEY_0 = Key.KEY_0,
	KEY_1 = Key.KEY_1,
	KEY_2 = Key.KEY_2,
	KEY_3 = Key.KEY_3,
	KEY_4 = Key.KEY_4,
	KEY_5 = Key.KEY_5,
	KEY_6 = Key.KEY_6,
	KEY_7 = Key.KEY_7,
	KEY_8 = Key.KEY_8,
	KEY_9 = Key.KEY_9,
	KEY_A = Key.KEY_A,
	KEY_B = Key.KEY_B,
	KEY_C = Key.KEY_C,
	KEY_D = Key.KEY_D,
	KEY_E = Key.KEY_E,
	KEY_F = Key.KEY_F,
	KEY_G = Key.KEY_G,
	KEY_H = Key.KEY_H,
	KEY_I = Key.KEY_I,
	KEY_J = Key.KEY_J,
	KEY_K = Key.KEY_K,
	KEY_L = Key.KEY_L,
	KEY_M = Key.KEY_M,
	KEY_N = Key.KEY_N,
	KEY_O = Key.KEY_O,
	KEY_P = Key.KEY_P,
	KEY_Q = Key.KEY_Q,
	KEY_R = Key.KEY_R,
	KEY_S = Key.KEY_S,
	KEY_T = Key.KEY_T,
	KEY_U = Key.KEY_U,
	KEY_V = Key.KEY_V,
	KEY_W = Key.KEY_W,
	KEY_X = Key.KEY_X,
	KEY_Y = Key.KEY_Y,
	KEY_Z = Key.KEY_Z,
}

@export var ReceiveInput: bool = false
@export var ProcessPhysics: bool = false
@export var ProcessRender: bool = false
@export var ModuleType: String = ""
@export var ModuleTags = [] # (Array, String)
@export var UsesEnergy: bool = false
@export var EnergyType: String = "fuel"

var aircraft = null

func setup(aircraft_node):
	aircraft = aircraft_node

#func receive_input(event):
#	pass

#func process_physic_frame(delta):
#	pass

#func process_render_frame(delta):
#	pass
