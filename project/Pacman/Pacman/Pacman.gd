extends KinematicBody2D

signal playerCollision
signal ghostCollision

export var movementSpeed = 20
onready var timer = $Timer
onready var boostTimer = $BoostTimer
enum States {NORMAL, CHASING_PLAYER, CHASING_GHOSTS, RUNNING_AWAY}
var lastDirection = Vector2(-1,0)
onready var map = self.get_tree().get_root().get_node("/root/Root/LevelPacman/TileMap")
var currentState = States.NORMAL
var ableToTeleport = true
var isBoosted = false
var astarPath = []
const POINT_RADIUS = 3
var targetPosition = Vector2()
var targetPointWorld = Vector2()
var velocity = Vector2()

func _init():
	pass
	
func _ready():
	changeState(States.NORMAL)
	timer.connect("timeout", self, "_onTimer_timeout")
	boostTimer.connect("timeout", self, "_onBoostTimer_timeout")

func _process(delta):
	if Input.is_key_pressed(KEY_J):
		currentState = States.CHASING_PLAYER
	if Input.is_action_just_pressed("ui_page_up"):
		targetPosition = get_parent().get_node("Player").global_position
		changeState(States.CHASING_PLAYER)
	var arrivedToNextPoint = moveTo(targetPointWorld)
	if arrivedToNextPoint:
		astarPath.remove(0)
		if len(astarPath) == 0:
			changeState(States.CHASING_PLAYER)
			return
		targetPointWorld = astarPath[0]
	if not ableToTeleport and timer.is_stopped():
		timer.start()
	
	
func recalculate():
	map.recalculatePath()

func changeState(newState):
	currentState = newState
	if newState == States.CHASING_PLAYER:
		var toDisconnectIndex = map.calculatePointIndex(map.world_to_map(self.global_position - lastDirection * map.cell_size))
		map.pointToDisconnect = toDisconnectIndex
		var currentTileIndex = map.calculatePointIndex(map.world_to_map(self.global_position))
		astarPath = map.getPath(global_position, targetPosition)
		if not astarPath or len (astarPath) == 1:
			targetPosition = get_parent().get_node("Player").global_position
			return
		targetPointWorld = astarPath[0]
	if newState == States.NORMAL:
		astarPath = map.getPathToRandomTile(global_position, map.Modes.BOTTOM_HALF)
		if not astarPath or len (astarPath) == 1:
			return
		targetPointWorld = astarPath[0]
	if newState == States.CHASING_GHOSTS:
		if isBoosted:
			astarPath = map.getPathToRandomGhost(global_position)
			if not astarPath or len(astarPath) == 1:
				return
			targetPointWorld = astarPath[0]
		else:
			changeState(States.NORMAL)
	
func moveTo(worldPosition):
	var ARRIVE_DISTANCE = 2.0
	var desiredVelocity = (worldPosition - global_position).normalized() * movementSpeed
	var steering = desiredVelocity - velocity
	velocity += steering
	lastDirection =  velocity.normalized()
	var result = move_and_collide(velocity * get_process_delta_time())
	
	if result and result.collider.is_in_group("Player"):
		emit_signal("playerCollision")
	elif result and result.collider.is_in_group("Ghost"):
		emit_signal("ghostCollision", result.collider)

	var angle = velocity.angle()
	rotation = angle

	return global_position.distance_to(worldPosition) < ARRIVE_DISTANCE

	
func _onTimer_timeout():
	ableToTeleport = true
	
func _onBoostTimer_timeout():
	isBoosted = false
	changeState(States.NORMAL)