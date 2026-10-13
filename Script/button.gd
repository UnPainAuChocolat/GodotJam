extends MeshInstance3D

func activate():
	var membres = get_tree().get_nodes_in_group("oppenable")
	for node in membres:
		node.get_parent().show()
