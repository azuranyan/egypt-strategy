class_name Settings
extends Resource


enum CameraFollow {DISABLED, ALWAYS, CURSOR_ONLY}

enum UndoMoveBehavior {UNDO_MOVE, UNDO_SELECT}

enum UnitHUD {FULL, SIMPLIFIED, HP_BARS_ONLY}

enum EnemyActions {NORMAL, FAST}

enum CursorMode {TYPE_A, TYPE_B}

enum WaitAfterEvent {WAIT_FOR_INPUT, DONT_WAIT}

enum DialogueAutosave {DISABLED, ON_EVENT_START, BEFORE_EVENT_START}

enum WindowMode {FULLSCREEN, WINDOWED}


@export_group("Gameplay")
#region Gameplay Settings
@export_subgroup("Battle")
@export var camera_follow: CameraFollow
@export var auto_end_turn: bool
@export var undo_move_behavior: UndoMoveBehavior
@export var unit_hud: UnitHUD
@export var enemy_actions: EnemyActions
@export var cursor_mode: CursorMode

@export_subgroup("Overworld")
@export var wait_after_event: bool
@export var defeat_if_home_territory_captured: bool
@export var show_marching_animations: bool

@export_subgroup("Dialogue")
@export var dialogue_autosave: DialogueAutosave
#endregion Gameplay Settings


@export_group("Controls")
#region Control Settings
@export_enum("Mouse and Keyboard", "Controller") var control_mode: String = "Controller"
#endregion Control Settings


@export_group("Video")
#region Video Settings
@export var window_mode: WindowMode
@export var vsync: bool
@export var show_fps: bool
#endregion Video Settings


@export_group("Audio")
#region Audio Settings
@export_range(0.0, 1.0) var master_volume: float

@export_subgroup("Audio Balance")
@export_range(0.0, 1.0) var music_volume: float
@export_range(0.0, 1.0) var voice_volume: float
@export_range(0.0, 1.0) var sound_effects_volume: float
#endregion Audio Settings

