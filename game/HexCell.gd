# A hexagonal grid cell
#
# Ref: https://www.redblobgames.com/grids/hexagons/
#
# The hexes use a flat-topped orientation,
# the axial coordinates use +y => N, +x => NE,
# and offset coords have odd rows shifted up half a step.
#
# Using y instead of z makes following the reference more tricky,
# but is more consistent with Godot's Vector2 objects (which have x and y).

extends Node

# We use unit-size flat-topped hexes
const size = Vector2(1, sqrt(3)/2)
const DIR_N = Vector3(0, 1, -1)
const DIR_NE = Vector3(1, 0, -1)
const DIR_SE = Vector3(1, -1, 0)
const DIR_S = Vector3(0, -1, 1)
const DIR_SW = Vector3(-1, 0, 1)
const DIR_NW = Vector3(-1, 1, 0)


# Cube coords are canonical
var cube_coords = Vector3(0, 0, 0) setget set_cube_coords, get_cube_coords
# but other coord systems can be used
var axial_coords setget set_axial_coords, get_axial_coords
var offset_coords setget set_offset_coords, get_offset_coords


"""
	Handle coordinate access and conversion
"""
func axial_to_cube_coords(val):
	# Returns the Vector3 cube coordinates for an axial Vector2
	var x = val.x
	var y = val.y
	return Vector3(x, y, -x - y)
	
func round_coords(val):
	# Rounds floaty coordinate to the nearest whole number cube coords
	if typeof(val) == TYPE_VECTOR2:
		val = axial_to_cube_coords(val)
	
	# Straight round them
	var rounded = Vector3(round(val.x), round(val.y), round(val.z))
	
	# But recalculate the one with the largest diff so that x+y+z=0
	var diffs = (rounded - val).abs()
	if diffs.x > diffs.y and diffs.x > diffs.z:
		rounded.x = -rounded.y - rounded.z
	elif diffs.y > diffs.z:
		rounded.y = -rounded.x - rounded.z
	else:
		rounded.z = -rounded.x - rounded.y
	
	return rounded
	

func get_cube_coords():
	# Returns a Vector3 of the cube coordinates
	return cube_coords
	
func set_cube_coords(val):
	# Sets the position from a Vector3 of cube coordinates
	if val.x + val.y + val.z != 0:
		print("WARNING: Invalid cube coordinates for hex (x+y+z!=0): ", val)
		return
	cube_coords = round_coords(val)
	
func get_axial_coords():
	# Returns a Vector2 of the axial coordinates
	return Vector2(cube_coords.x, cube_coords.y)
	
func set_axial_coords(val):
	# Sets position from a Vector2 of axial coordinates
	set_cube_coords(axial_to_cube_coords(val))
	
func get_offset_coords():
	# Returns a Vector2 of the offset coordinates
	var x = int(cube_coords.x)
	var y = int(cube_coords.y)
	var off_y = y + (x - (x & 1)) / 2
	return Vector2(x, off_y)
	
func set_offset_coords(val):
	# Sets position from a Vector2 of offset coordinates
	var x = int(val.x)
	var y = int(val.y)
	var cube_y = y - (x - (x & 1)) / 2
	self.set_axial_coords(Vector2(x, cube_y))
	

"""
	Finding our neighbours
"""
func get_adjacent(dir):
	# Returns a HexCell instance for the given direction from this.
	# Intended for one of the DIR_* consts, but really any Vector2 or x+y+z==0 Vector3 will do.
	if typeof(dir) == TYPE_VECTOR2:
		dir = axial_to_cube_coords(dir)
	var cell = get_script().new()
	cell.cube_coords = self.cube_coords + dir
	return cell
	
func get_all_adjacent():
	# Returns an array of HexCell instances representing adjacent locations
	var cells = Array()
	for coord in [DIR_N, DIR_NE, DIR_SE, DIR_S, DIR_SW, DIR_NW]:
		var cell = get_script().new()
		cell.cube_coords = self.cube_coords + coord
		cells.append(cell)
	return cells
	
func distance_to(target):
	# Returns the number of hops from this hex to another
	if typeof(target) == TYPE_VECTOR2:
		target = axial_to_cube_coords(target)
	return (
			abs(cube_coords.x - target.x)
			+ abs(cube_coords.y - target.y)
			+ abs(cube_coords.z - target.z)
			) / 2
	
