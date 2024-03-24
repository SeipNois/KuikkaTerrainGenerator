/*
 * ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## 
 * Base class for terrain agents that generate heightmap features.
 * base class implements [method GenerationProcess] loop similar to
 * Godot's [method Node._Process] and [method Node._PhysicsProcess]. 
 * [method GenerationProcess] acts as generation step for advancing agent
 * should be called by [TerrainServerGD] for each agent in its
 * own [method Node._Process] or [method Node._PhysicsProcess] loop.
 */

using Godot;
using System;


[GlobalClass]
public partial class TerrainAgent : Node
{	
	// Signal to be emitted when this agent has finished its 
	// generation process and no more generation steps need to be run.
	[Signal]
	public delegate void GenerationFinishedEventHandler();

	public RandomNumberGenerator rng = new RandomNumberGenerator();

/*
	// Generation seed for taking random actions to make process deterministic.
	public int seed {
		get { return seed; }
		set { seed = value; rng.SetSeed(seed); }
	}

	// Starting state for RandomNumberGenerator rng.
	public int state {
		get { return state; }
		set { state = value; rng.SetState(state); }
	}
*/


	// Tokens remaining for this agent. Each run of [method GenerationProcess] will consume
	// tokens and generation is considered finished when all tokens are consumed.
	public int tokens {
		get { return tokens; }
		set { 
			tokens = value; 
			if (tokens <= 0) 
			{ 
				EmitSignal(SignalName.GenerationFinished);
			}
		}
	}

	// Reference to heightmap agent uses as reference and which it should edit with
	// its behaviour.
	public Image heightmap;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		this.SetProcess(false);
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		if (this.tokens > 0) {
			GenerationProcess();
		}
	}
	
	// Generation step to run each frame for this agent in [method Process] 
	// or [method PhysicsProcess]
	public virtual void GenerationProcess() 
	{
		
	}

	// Make necessary preparations to set starting state of agent and start generation process.
	public virtual void StartGeneration() {
		// Start generation if agent has tokens. Otherwise consider generation instantly finished.
		if (this.tokens > 0) {
			this.SetProcess(true);
		}
		else {
			EmitSignal(SignalName.GenerationFinished);
		}
	}
}
