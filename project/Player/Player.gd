extends KinematicBody2D

signal ourSignal

var sBullet = preload("res://weapon/Bullet.tscn")

var vel = Vector2()

func _process(delta):
	vel = Vector2()
	if Input.is_action_pressed("ui_left"):
		vel.x = -1.0
	if Input.is_action_pressed("ui_right"):
		vel.x = 1.0
	if Input.is_action_pressed("ui_up"):
		vel.y = -1.0
	if Input.is_action_pressed("ui_down"):
		vel.y = 1.0
		
	move_and_slide(vel.normalized()*200.0)
	
	#ready
	#init
	#enter_tree

func _input(event):
	if event.is_action_pressed("shoot"):
		shoot()

func shoot():
	
	var bullet = sBullet.instance()
	Game.getCurrentStage().addProjectile(bullet)
	bullet.global_position = global_position
	
	var vec = get_global_mouse_position() - global_position
	vec = vec.normalized() * 10.0	
	bullet.setVelocity(vec)

func _ready():
	$Timer.connect("timeout", self, "_onTimer_timeout")
	yield(get_tree(), "idle_frame")
	get_tree().call_group("zombies","set_player",self)

func _onTimer_timeout():
	rotate(30)
	
	