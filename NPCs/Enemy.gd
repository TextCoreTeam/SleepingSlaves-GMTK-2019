extends KinematicBody2D

var hp
var damage_amount
var speed
var player
var can_take_dmg = true

var melee_cooldown
var bullet_speed

var visibility_dst
var lose_dst	# Distance at which enemy loses sight of player

var has_range_attack
var has_melee_attack

var mscale = Vector2.ZERO
func _on_takedmg_timeout():
	can_take_dmg = true
	$TakeDMGTimer.stop()
	$Blood.emitting = false

func _ready():
	var cscale = get_scale()
	mscale.x = cscale.x
	mscale.y = cscale.y
	$Blood.emitting = false
	player = get_parent().get_parent().get_node("Player")
	pid = player.get_instance_id()
	$TakeDMGTimer.connect("timeout", self, "_on_takedmg_timeout")
	$ShootTimer.connect("timeout", self, "_on_shoot_timeout")
	$ShootTimer.start()
	pass

var bullet_s = load("res://Projectiles/Bullet.tscn")
func _on_shoot_timeout():
	if (!detected || !has_range_attack):
		return
	var direction = Vector2(cos($Aim.get_rotation()), sin($Aim.get_rotation()))
	var spawn_distance = 70
	var spawn_point = get_global_position() + direction * spawn_distance
	var bullet = bullet_s.instance()
	var world  = get_parent().get_parent()
	bullet.get_node("Bullet_area/Sprite").frame = 0
	world.add_child(bullet)
	bullet.set_global_position(spawn_point)
	bullet.get_node('Bullet_area').velocity = (Vector2(cos($Aim.get_rotation()) * bullet_speed, sin($Aim.get_rotation()) * bullet_speed))
	pass

func _on_AttackCooldown_timeout():
	can_attack = true
	print("Mob can attack again")
	$AttackCooldown.stop()

func mob():	#kludge for mob identification because im a f4g
	pass

func dmg():
	if (can_take_dmg):
		print("Mob took damage")
		$TakeDMGTimer.start(1)
		can_take_dmg = false
		$Blood.emitting = true
		hp -= 1

var pid
var can_attack = true
var collision
var turn_speed = deg2rad(4)

var dir	# vector difference between player and enemy
var dst	# distance to player

var detected = false
var heading_right = true #false->left true->right

func turn_right():
	if (!heading_right):
		heading_right = true
		$Aim.rotation -= turn_speed
		set_scale(Vector2(-mscale.x, mscale.y))

func turn_left():
	if (heading_right):
		heading_right = false
		$Aim.rotation += turn_speed
		set_scale(Vector2(mscale.x, -mscale.y))

var player_in_melee_hitbox = false

func attack(body):
	body.dmg(damage_amount)
	can_attack = false
	$AttackCooldown.start(melee_cooldown)

func _physics_process(delta):
	if (hp < 1):
		player.reward()
		get_parent().get_parent().enemies -= 1
		get_parent().get_parent().get_node("GUI/ECount").text = "Enemies: "+str(get_parent().get_parent().enemies)
		queue_free()
	dst = (player.global_position - global_position).length()
	dir = (player.global_position - global_position).normalized()
	
	if (dst <= visibility_dst && !detected):
		print("Detected player")
		detected = true
	
	if (dst >= lose_dst && detected):
		print("Lost sight of player")
		detected = false
	
	if (detected):
		if $Aim.get_angle_to(player.global_position) > 0:
    		turn_left()
		else:
    		turn_right()
		collision = move_and_collide(dir * speed * delta)
		
		if ($MeleeHitbox.overlaps_body(player) && player_in_melee_hitbox && can_attack && has_melee_attack):
			attack(player)


func _on_MeleeHitbox_body_entered(body):
	print("Est probitie")
	if (has_melee_attack && can_attack && body.has_method("pdmg")):
			player_in_melee_hitbox = true
			attack(body)

func _on_MeleeHitbox_body_exited(body):
	if (body.has_method("pdmg")):
		player_in_melee_hitbox = false
