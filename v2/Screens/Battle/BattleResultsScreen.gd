extends CanvasLayer
class_name BattleResultsScreen


signal done


func _on_done():
	if $Control.visible:
		await get_tree().create_timer(1.8).timeout
		$AnimationPlayer.play('hide')
		await $AnimationPlayer.animation_finished
	queue_free()
	done.emit()
