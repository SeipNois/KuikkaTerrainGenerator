extends Node

## Singleton timer util for KuikkaTerrainGen to use waiting operations similar
## to get_tree().create_timer()


## Create new one shot timer.
func create_timer(time: float) -> Timer:
	var timer = Timer.new()
	timer.timeout.connect(
		func(): 
			remove_child(timer)
			timer.queue_free())
	timer.one_shot = true
	add_child(timer)
	timer.start(time)
	
	return timer
