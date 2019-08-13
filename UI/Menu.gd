extends Control

func _ready():
	Globals.destroyed_entities.clear()

func _on_NewGameBtn_pressed():
	Globals.game_mode = 0
	get_tree().change_scene("res://Maps/Level-0.tscn")

func _on_ContinueBtn_pressed():
	Globals.game_mode = 1
	get_tree().change_scene("res://Maps/Level-Arcade.tscn")

func _on_QuitBtn_pressed():
	get_tree().quit()
