extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# joystick part / any controllers
var directionnalInputs = Vector3(0,0,0)

# mouse rotation
@onready var head := $Camera3D
const SENSITIVITY = 0.07

var xr_interface: XRInterface


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	xr_interface = XRServer.find_interface("OpenXR")
	
	if xr_interface and xr_interface.is_initialized():
		$MeshInstance3D.queue_free()
	else:
		$XROrigin3D.queue_free()


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		#print("mouse_motion_detect: ", event)
		rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY))
		head.rotate_x(deg_to_rad(-event.relative.y * SENSITIVITY))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	directionnalInputs.x = input_dir.x
	directionnalInputs.z = input_dir.y
	
	var direction: Vector3 = Vector3()
	
	if xr_interface and xr_interface.is_initialized():
		var xr_move = $XROrigin3D/XRController3D_Left.get_vector2("move")
		directionnalInputs.x = xr_move.x
		directionnalInputs.z = -xr_move.y
		
		var cam_basis = $XROrigin3D/XRCamera3D.global_transform.basis
		direction = (cam_basis * directionnalInputs)
		direction.y = 0
		direction = direction.normalized()
	else:
		direction = (get_global_transform().basis * directionnalInputs).normalized()
	
	if direction.x:
		velocity.x = direction.x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if direction.z:
		velocity.z = direction.z * SPEED
	else:
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
