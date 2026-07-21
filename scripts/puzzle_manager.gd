extends Node
@export var room : Node3D
#this is the main manager of the game, and is mainly tasked with checking
#if the given solution is correct or not

#the solution is encoded as an array of strings representing
#jack-socket combinations, with the jacks being numbers 01-04
#and the sockets being double letters AA-DD
#XXXX is a special combination telling the game to ignore the socket
var sample_solution : Array[String] = [
	"XXXX",
	"AA02",
	"BB03",
	"XXXX"
]

#now we simply check the solution
var correct : bool = true
func check_solution():
	#first, we update the player's given solution and assume it's good
	room.get_solution()
	correct = true
	#then we check if all the combinations are there
	for i in sample_solution:
	#we move ahead if the solution is irrelevant
		if i == "XXXX":
			pass
		#we move ahead if the solution is allright
		elif room.solution.has(i):
			pass
		#otherwise we set the flag to false
		else :
			correct = false

#just for testing
func debug_solution():
	if correct:
		print("You did it! You solved the puzzle!")
	else:
		print("Unfortunately, the provided solution is not correct")

func _process(_delta):
	if Inputs.debug_pressed():
		check_solution()
		debug_solution()
