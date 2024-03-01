class_name ErrorObject


## Returns true if no error.
func ok() -> bool:
	return false


## Returns the error description.
func what() -> String:
	return 'Error.'


func _to_string() -> String:
	return what()