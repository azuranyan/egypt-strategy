using Godot;
using System;


public class Actions
{

}


internal struct Action
{
	bool is_move;
	Godot.Vector2 cell;
	bool is_attack;
	Godot.GodotObject attack;

}
