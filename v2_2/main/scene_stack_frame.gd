class_name SceneStackFrame
extends Resource


## The scene path of the callee.
@export var scene_path: String

## The callee packed into a [PackedScene].
@export var scene: PackedScene

## Continuation method to be called when the scene is restored.
@export var continuation_method: StringName

## Serializeable data for the scene.
@export var continuation_data: Dictionary
