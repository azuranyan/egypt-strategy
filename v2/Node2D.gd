extends Node2D

var global_var := 5



func _ready():
	var lambda1 := func():
		global_var += 5
	lambda1.call()
	print(global_var)
	
	var local_var := 5
	var lambda2:= func():
		local_var += 5
	lambda2.call()
	print(local_var)
	
	

func modify_me(x):
	x += 5
