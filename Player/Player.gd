extends KinematicBody2D

var can_walk = false

var motion = Vector2.ZERO
const thrust_v = 1300
const speed_max_v = 350

var mana = 0
var max_mana = 10

var thrust = 1300
var speed_max = 350

var retract_step
var knock_resistance = 170
var sword_spawn_distance = 20
var money = 0
var hp = 10
var dead = false
var resistance_factor = 1

var can_throw = true
var has_sword = true
var throw_cooldown = 0.8

var knock_dir = Vector2.ZERO
var knock_baking = false

var mousepos
var aim_speed = deg2rad(3)
var sword_s = load("res://Projectiles/Sword.tscn")
var sword_speed = 600
onready var world = get_parent()
var my_weapon = null

var charge_pressed = true

var velo_bonus #velocity bonus when thrown back by sword
func _on_progress_timeout():
	if ($TextureProgress.value < $TextureProgress.max_value &&
		Input.is_action_pressed("Charge")):
		$TextureProgress.value += 3.5
	else:
		$TextureProgress.visible = false
		sword_speed = sword_speed + 5 * $TextureProgress.value
		velo_bonus = $TextureProgress.value
		can_throw = false
		has_sword = false
		$SwordSprite.visible = false
		throw_sword()
		$RetractBar.visible = true
		$RetractTimer.start(retract_step)
		$ThrowTimer.start(throw_cooldown)
		$ChargeTimer.stop()
		$TextureProgress.value = 0
		sword_speed = 600
	
func knockback(velocity, maxspeed, kthrust, use_bonus):
	if (!false):
		print("Knock bonus: " + str(velo_bonus) + " " + str(use_bonus))
		if (use_bonus):
			if (velo_bonus > 0 && velo_bonus < 100):
				velo_bonus *= 3
			else:
				velo_bonus *= 6.1
			thrust = kthrust + velo_bonus
		else:
			thrust = kthrust
		speed_max = maxspeed
		knock_baking = true
		knock_dir = velocity.clamped(1) * (-1)
		print (str(knock_dir) + " | " + str(thrust) + " / "+ str(maxspeed))

var can_possess = false
var possess_active = false #flag for possession spell activation

func add_mana(amt = 5):
	mana += amt
	if (mana >= max_mana):
		mana = max_mana
		can_possess = true

func reward(money_r):
	money += money_r
	get_parent().update_score(money)

func dmg(amt):
	hp -= amt
	$HPBar.value = hp
	$HPBar.update()
	$HPLabel.text = str(hp)

func return_sword():
	has_sword = true
	my_weapon.get_node("RigidBody2D").knock_speed_max = 3000
	my_weapon.get_node("RigidBody2D").knock_thrust = 5000
	my_weapon.get_node("RigidBody2D").upgraded = ""
	my_weapon.get_node("RigidBody2D").dmg_num = 1
	$RetractAnim.hide()
	$AnimationPlayer.stop()
	#$SwordSprite.visible = true

var sword_knock_thrust = 2500	#knockback on sword throw
var sword_knock_speed_max = 3000
onready var vertical_spawn_dst = sword_spawn_distance + 30
var aim_vertical = -1 #-1 -> no 0 -> up 1 -> down
func throw_sword():
	var rot = $MousePtr.get_rotation()
	mousepos = get_global_mouse_position()
	var spawn_point
	var direction = Vector2(cos(rot), sin(rot))
	if (aim_vertical == 0 || aim_vertical == 1):
		spawn_point = get_global_position() + direction * vertical_spawn_dst
	else:
		spawn_point = get_global_position() + direction * sword_spawn_distance		
	var sword = sword_s.instance()	
	if (aim_vertical == 1):
		sword.get_node("RigidBody2D/Sprite").flip_v = true
	var world  = get_parent()
	world.add_child(sword)
	sword.set_global_position(spawn_point)
	sword.get_node('RigidBody2D').linear_velocity = (Vector2(cos(rot) * sword_speed, sin(rot) * sword_speed))
	knockback(sword.get_node('RigidBody2D').linear_velocity, sword_knock_speed_max, sword_knock_thrust, false)
	my_weapon = sword

func resummon_weapon():
	print("User-triggered bruh moment")
	my_weapon.get_node("RigidBody2D").return_back()
	
var rbar_step
onready var map = get_parent().get_node("Navigation2D/TileMap")
func _ready():
	$HPBar.max_value = hp
	$HPBar.value = hp
	$HPLabel.text = str(hp)
	$HPBar.update()
	rbar_step = $RetractBar.max_value / 20
	retract_step = throw_cooldown / 20
	if (Globals.checkpoint != Vector2.ZERO):
		global_position = Globals.checkpoint
	start_scale = scale
	$RetractTimer.connect("timeout", self, "_on_retract_timeout")
	$ThrowTimer.connect("timeout", self, "_on_throw_timeout")
	$ChargeTimer.connect("timeout", self, "_on_progress_timeout")

func _on_retract_timeout():
	$RetractBar.value += rbar_step
	if ($RetractBar.value >= $RetractBar.max_value):
		$RetractTimer.stop()
		$RetractBar.visible = false
		$RetractBar.value = 0

func _on_throw_timeout():
	print("can throw again")
	can_throw = true
	$ThrowTimer.stop()

var start_scale
var flipped = false # !flipped -> facing right
func flip():
	if (!flipped):
		flipped = true
		$Sprite.flip_h = true
		$SwordSprite.flip_h = true
		$SwordSprite.position = Vector2(-28, 13) #TODO pridumat kak flipat ego bez etoy xuini
	else:
		flipped = false
		scale.x = start_scale.x
		$Sprite.flip_h = false
		$SwordSprite.flip_h = false
		$SwordSprite.position = Vector2(26, 13)

func turn_right():
	$MousePtr.look_at(mousepos)
	$SwordSprite.look_at(mousepos)
	if (flipped):
		flip()
	
func turn_left():
	$MousePtr.look_at(mousepos)
	$SwordSprite.look_at(mousepos)
	if (!flipped):
		flip()

func pdmg():
	pass

var mouse_angle
func _input(event):
	mousepos = get_global_mouse_position()
	mouse_angle = rad2deg($MousePtr.get_angle_to(mousepos))
	if (mousepos.x > self.global_position.x):
    	turn_right()
	else:
    	turn_left()
	
	if event is InputEventMouseButton:
		if (!get_parent().wpaused && event.is_pressed() && event.button_index == BUTTON_LEFT && can_throw && has_sword):
			$TextureProgress.visible = true
			$ChargeTimer.start()
			
		elif (can_throw &&	#kuldaun ne tolko na brosok, no i na vozvrat
		event.is_pressed() &&
		event.button_index == BUTTON_LEFT &&
		!has_sword):
			resummon_weapon()

func do_resistance(amt):
	if (motion.length() > amt):
		motion -= motion.normalized() * amt
	else:
		motion = Vector2.ZERO
	
func move(amt):
	motion += amt
	motion = motion.clamped(speed_max)

func direction():
	var axis = Vector2.ZERO
	axis.x = int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
	axis.y = int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
	return axis.normalized()

func die():
	if (!dead):
		dead = true
		Globals.score = money
		get_tree().change_scene("res://UI/Death.tscn")

var axis = Vector2.ZERO
var collision

var standing_on
var void_timeout = 0.99
var standing_offset = Vector2(0, 30)
func _physics_process(delta):
	standing_on = (map.get_cellv(map.world_to_map(global_position + standing_offset)))
	if (standing_on != -1 && !$VoidTimer.is_stopped()):
		print("No longer above the void")
		$FadeTimer.stop()
		$Sprite.modulate.a = 1
		$VoidTimer.stop()
	if (axis == Vector2.ZERO &&
	motion == Vector2.ZERO &&
	standing_on == -1 &&
	$VoidTimer.is_stopped()):
		print("Void timer start")
		$FadeTimer.start()
		$VoidTimer.start(void_timeout)
	if (can_throw && !has_sword && $AnimationPlayer.current_animation != "RetractAnim"):
		$RetractAnim.show()
		$AnimationPlayer.play("RetractAnim")
	if (hp < 1):
		die()
		visible = false
	if (!dead && !knock_baking):
		axis = direction()
	if (!knock_baking && !can_walk):
		axis = Vector2.ZERO
	
	if (knock_baking):
		axis = knock_dir
		thrust -= knock_resistance
		if (thrust <= thrust_v):
			thrust = thrust_v
			knock_baking = false
			speed_max = speed_max_v
	
	if (axis == Vector2.ZERO):
		do_resistance(thrust * delta * resistance_factor)
	else:
		move(axis * thrust * delta)
	motion = move_and_slide(motion)
	
	collision = move_and_collide(Vector2.ZERO)
	if (collision):
		if (collision.get_collider().has_method("pick")):
			collision.collider.queue_free()
			return_sword()


func _on_AimUp_area_entered(area):
	if (area.has_method("mouseptr")):
		aim_vertical = 0


func _on_AimDown_area_entered(area):
	if (area.has_method("mouseptr")):
		aim_vertical = 1


func _on_AimUp_area_exited(area):
	if (area.has_method("mouseptr")):
		aim_vertical = -1


func _on_AimDown_area_exited(area):
	if (area.has_method("mouseptr")):
		aim_vertical = -1


func _on_VoidTimer_timeout():
	if (standing_on == -1):
		die()
	print("Bruh")
	$VoidTimer.stop()
	$FadeTimer.stop()


func _on_FadeTimer_timeout():
	var amt = 0.09
	if ($Sprite.modulate.a - amt > 0):
		$Sprite.modulate.a -= amt