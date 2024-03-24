using Godot;
using System;

[GlobalClass]
public partial class LakeAgent : TerrainAgent
{	

	// Members to control movements of the agent.
	private Vector2I startingPosition;
	private Vector2I lastPosition;
	private Vector2I nextDirection;

	private Image brush;


	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		brush = Image.LoadFromFile("res://addons/kuikka_terrain_gen/brushes/128_gaussian.png");
		brush.Resize(32, 32);
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		
	}

	public override void GenerationProcess() {

	}

	public override void StartGeneration() {
		// Set starting point and direction for generation.
		//startingPosition = new Vector2I(rng.RandIntRange(0, this.heightmap.Width), rng.RandIntRange(0, this.heightmap.Height));

		// Start generation loop.
		base.StartGeneration();
	}
}
