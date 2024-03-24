/*
 *	Auto-load (singleton) class to define API running terrain generation process. 
 *	API can be used on runtime to generate with parameters loaded from configuration file or in editor
 *	through related editor tab. Generation produces image file that can then be saved on disk or
 *	used as heightmap for supporting terrain.
 */

// FIXME: Redone in GDscript as there is bug with calling C# class static
// functions apparently present still in Godot 4.2 See #86256, #86972

using Godot;
using System;

[Tool]
//[GlobalClass]
public partial class TerrainServer : Node
{	
	// Reference to singleton instance.
	public static TerrainServer _instance;
	public static TerrainServer Instance => _instance;

	public override void _EnterTree()
	{	
		// Class should be singleton. Don't allow creating new instances if _instance is defined.
		if (_instance != null) {
			this.QueueFree();
			return;
		}
		_instance = this;
	}

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
	
	// Return singleton instance if present.
	public static TerrainServer GetInstance()
	{
		return Instance;
	}

	// Main interface function for generating terrain. Returns generated heightmap as [Image].
	public ImageTexture GenerateTerrain(int width, int height) {
		return GenerateTest(width, height);
	}


	// Generation functions

	// Test generation
	private ImageTexture GenerateTest(int width, int height) {
		ImageTexture heightmap = new ImageTexture(); // = new NoiseTexture2D(width, height);

		return heightmap;
	}
}
