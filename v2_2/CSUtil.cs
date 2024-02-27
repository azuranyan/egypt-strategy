using Godot;
using System;
using System.Collections.Generic;
using System.Linq;


public partial class CSUtil : Node
{

	private static readonly Vector2[] Directions = { Vector2.Right, Vector2.Left, Vector2.Up, Vector2.Down };
	private static CSUtil _instance;
	public static CSUtil Instance => _instance;


	public override void _EnterTree()
	{
		if (_instance != null)
		{
			QueueFree();
		}
		_instance = this;
	}


	public Vector2[] FloodFill(Vector2 origin, Rect2 bounds, float max_dist, Callable filter)
	{
		List<Vector2> dest = new();
		Stack<Vector2> stack = new();
		stack.Push(origin);

		while (stack.Count > 0)
		{
			Vector2 p = stack.Pop();
			dest.Add(p);

			foreach (Vector2 dir in Directions)
			{
				Vector2 q = p + dir;
				if (bounds.HasPoint(q) && ManhattanDistance(origin, q) <= max_dist && !dest.Contains(q) && filter.Call(q).AsBool())
					stack.Push(q);
			}
		}

		return dest.ToArray();
	}


	// https://stackoverflow.com/questions/1257117/a-working-non-recursive-floodfill-algorithm-written-in-c
	public Vector2[] ScanlineFill(Vector2 origin, Rect2 bounds, float max_dist, Callable filter)
	{
		List<Vector2> dest = new();
		Queue<Vector2> queue = new();
		queue.Enqueue(origin);

		var check = (Vector2 q) => bounds.HasPoint(q) && ManhattanDistance(origin, q) <= max_dist && !dest.Contains(q) && filter.Call(q).AsBool();

		while (queue.Count > 0)
		{
			if (!check(queue.Peek()))
			{
				queue.Dequeue();
				continue;
			}

			Vector2 leftmost = queue.Dequeue();
			leftmost.X -= 1;

			Vector2 rightmost = leftmost;
			rightmost.X += 2;

			while (check(leftmost))
				--leftmost.X;

			while (check(rightmost))
				++rightmost.X;

			bool check_above = true;
			bool check_below = true;
			Vector2 pt = leftmost;
			++pt.X;

			for (; pt.X < rightmost.X; ++pt.X)
			{
				dest.Add(pt);

				Vector2 above = pt;
				--above.Y;
				if (check_above)
				{
					if (check(above))
					{
						queue.Enqueue(above);
						check_above = false;
					}
				}
				else
				{
					check_above = !check(above);
				}

				Vector2 below = pt;
				++below.Y;
				if (check_below)
				{
					if (check(below))
					{
						queue.Enqueue(below);
						check_below = false;
					}
				}
				else
				{
					check_below = !check(below);
				}
			}
		}

		return dest.ToArray();
	}

	public int ManhattanDistance(Vector2 a, Vector2 b)
	{
		Vector2 diff = (a - b).Abs();
		return (int)(diff.X + diff.Y);
	}

}