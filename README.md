# Drone-Game
Multi-drones single-target game. 
Written in x86 Assembly, implmenting a user-mode co-routine ("multi-thread") simulation of a drones game.
Suppose a 100x100 game board. Suppose group of N drones which see the same target from different points of view and from different distance.
Each drone tries to detect where is the target on the game board, in order to destroy it. 
Drones may destroy the target only if the target is in drone’s field-of-view, and if the target is no more than some maximal distance from the drone.
When the current target is destroyed, some new target appears on the game board in some randomly chosen place. 
The first drone that destroys T targets is the winner of the game. 
Each drone has three-dimensional position on the game board: coordinate x, coordinate y, and direction (angle from x-axis). 
Drones move randomly chosen distance in randomly chosen angle from their current place. 
After each movement, a drone calls mayDestroy(…) function with its new position on the board. mayDestroy(…) function returns TRUE if the caller drone may destroy the target, otherwise returns FALSE.
If the current target is destroyed, new target is created at random position on the game board. Note that drones do not know the coordinates of the target on the board game.
