# 3droomgenerationgdscript
3D Room Generation GDScript made for Godot 4.2.1

This is a GDScript file used for creating randomly generated 3D dungeons in the Godot Engine.
This script is essentially a 3D recreation of Derek Yu's Spelunky level generation.

TO USE
- Attach the script to a Node3D
- Assign room_size_in_meters to your desired single room size
- After creating rooms in your desired size for a given room type, add the room scenes the the correct Array in the Node3D's Inspector
- Adjust the columns, rows, layers, layer drop cooldown, extraction placment attempts, and bonus placement attempts to your liking and you're ready to go!

NOTES
- Before instantiating the rooms, the script prints out the array that defines the level generation in the format of a grid.
  This print function allows for a better understanding of what the script is doing, but can easily be disabled by commenting out print_grid() in the _ready() function.
- Extraction rooms are always placed near the main path, like a shop in Spelunky.
- Bonus rooms are never placed near the main path, similar to something like an altar in Spelunky.
- As it is now, all mainpath rooms must have openings on all four walls to ensure a path, although I intend to design a system that dynamically removes geometry from walls. Because this system
  will likely be implemented in my individual room script (and might be implemented drastically differently for different desired outcomes) I will likely never include that systmen in this
  repo. If you are curious to hear how I am approaching this problem please feel free to reach out - blumakesgames@gmail.com
- Of course you can use this system however you like, but it may be in your interset to fill bulk rooms with random sets of openings to create emergent pathing away from the main path.
  This would be how you give the player access to the bonus rooms.
- This script generates levels that start at the top and end at the bottom. If you would like to reverse this it will require switching around some math in the script.
  If you would like with this feel free to reach out - blumakesgames@gmail.com
