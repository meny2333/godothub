@tool
extends MeshInstance3D

@export var width = 16.0:
	set(value):
		if width != value:
			width = value
			if Engine.is_editor_hint():
				call_deferred("_update_mesh")

@export var height = 16.0:
	set(value):
		if height != value:
			height = value
			if Engine.is_editor_hint():
				call_deferred("_update_mesh")

@export var subdivision_w = 8:
	set(value):
		if subdivision_w != value:
			subdivision_w = value
			if Engine.is_editor_hint():
				call_deferred("_update_mesh")

@export var subdivision_h = 8:
	set(value):
		if subdivision_h != value:
			subdivision_h = value
			if Engine.is_editor_hint():
				call_deferred("_update_mesh")

func _enter_tree():
	if Engine.is_editor_hint() and mesh == null:
		create_lowpoly_water()
		_ensure_material()

func _ready():
	if mesh == null:
		create_lowpoly_water()
	_ensure_material()

func _update_mesh():
	create_lowpoly_water()

func _ensure_material():
	if material_override == null:
		var mat = ShaderMaterial.new()
		mat.shader = load("res://#Template/[Materials]/water.gdshader")
		mat.render_priority = 1
		material_override = mat
	elif material_override.shader == null:
		material_override.shader = load("res://#Template/[Materials]/water.gdshader")

func create_lowpoly_water():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var offset_w = width / 2.0
	var offset_h = height / 2.0
	var step_w = width / float(subdivision_w)
	var step_h = height / float(subdivision_h)

	for z in range(subdivision_h):
		for x in range(subdivision_w):
			var x0 = x * step_w - offset_w
			var z0 = z * step_h - offset_h
			var x1 = (x + 1) * step_w - offset_w
			var z1 = (z + 1) * step_h - offset_h

			var v0 = Vector3(x0, 0.0, z0)
			var v1 = Vector3(x1, 0.0, z0)
			var v2 = Vector3(x0, 0.0, z1)
			var v3 = Vector3(x1, 0.0, z1)

			var normal = Vector3.UP
			var uv0 = Vector2(float(x) / subdivision_w, float(z) / subdivision_h)
			var uv1 = Vector2(float(x + 1) / subdivision_w, float(z) / subdivision_h)
			var uv2 = Vector2(float(x) / subdivision_w, float(z + 1) / subdivision_h)
			var uv3 = Vector2(float(x + 1) / subdivision_w, float(z + 1) / subdivision_h)

			st.set_normal(normal)
			st.set_uv(uv0)
			st.add_vertex(v0)
			st.set_uv(uv2)
			st.add_vertex(v2)
			st.set_uv(uv1)
			st.add_vertex(v1)

			st.set_normal(normal)
			st.set_uv(uv2)
			st.add_vertex(v2)
			st.set_uv(uv3)
			st.add_vertex(v3)
			st.set_uv(uv1)
			st.add_vertex(v1)

	st.generate_normals()
	mesh = st.commit()
