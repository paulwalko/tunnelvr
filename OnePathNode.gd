extends StaticBody

var i   # use for indexing the nodes on save

# for cycling around each node anti-clockwise and using for generating the areas
var pathvectorseq = [ ]  # [ (arg, pathindex) ]

func _ready():
	pass

func getnodetype():
	return "ntPath"

func set_materialoverride(material, bselected_type):
	$CollisionShape/MeshInstance.material_override = material

	
