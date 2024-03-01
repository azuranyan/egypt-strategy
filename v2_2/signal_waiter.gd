class_name SignalWaiter
extends Object


signal signal_received


var _signal: Signal
var _is_waiting: bool = false
var _has_received: bool = false
var _value: Variant


func _init(signal_: Signal, autostart: bool = false) -> void:
	_signal = signal_
	if autostart:
		wait_for_value.call_deferred()


func wait_for_value() -> Variant:
	if _is_waiting:
		push_error('already waiting!')
		return
	_is_waiting = true
	_has_received = false
	_value = await _signal
	signal_received.emit()
	_has_received = true
	_is_waiting = false
	return _value


func is_waiting() -> bool:
	return _is_waiting


func has_value() -> bool:
	return _has_received


func value() -> Variant:
	return _value