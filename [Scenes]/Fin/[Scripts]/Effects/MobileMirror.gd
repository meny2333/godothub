extends Node3D
class_name MobileMirror

signal shattered

const MIRROR_VISUAL_LAYER: int = 1 << 19
const MIN_REFLECTION_EDGE: int = 64

## 主视口到反射视口的分辨率比例。
@export_range(0.1, 1.0, 0.05) var resolutionScale: float = 0.5
## 反射视口最长边上限，用于限制移动端 GPU 开销。
@export_range(128, 2048, 64) var maxResolution: int = 768

@export_group("破碎效果")
@export_range(2, 12, 1) var fragmentColumns: int = 6
@export_range(2, 8, 1) var fragmentRows: int = 4
@export_range(0.0, 0.45, 0.01) var fragmentIrregularity: float = 0.38
@export_range(0.1, 20.0, 0.1) var fragmentImpulse: float = 4.0
@export_range(0.0, 2.0, 0.05) var fragmentTorque: float = 0.2
@export_range(0.0, 2.0, 0.05) var fragmentGravity: float = 0.55
@export_range(0.1, 10.0, 0.1) var fragmentLifetime: float = 3.0

@onready var _reflectionViewport: SubViewport = $ReflectionViewport
@onready var _reflectionCamera: Camera3D = $ReflectionViewport/ReflectionCamera
@onready var _mirrorSurface: MeshInstance3D = $MirrorSurface

var _sourceCamera: Camera3D
var _reflectionSize: Vector2i = Vector2i.ZERO
var _isShattered: bool = false
var _reflectionCleanupTween: Tween
var _fragments: Array[RigidBody3D] = []


func _ready() -> void:
	_mirrorSurface.layers = MIRROR_VISUAL_LAYER
	_reflectionViewport.world_3d = get_viewport().world_3d
	var mirrorMaterial: ShaderMaterial = _mirrorSurface.material_override as ShaderMaterial
	if mirrorMaterial != null:
		mirrorMaterial.set_shader_parameter("reflection_texture", _reflectionViewport.get_texture())
	_updateReflectionSize()


func _process(_delta: float) -> void:
	var currentCamera: Camera3D = get_viewport().get_camera_3d()
	if currentCamera == null or currentCamera == _reflectionCamera:
		return
	_sourceCamera = currentCamera
	_updateReflectionSize()
	_copyCameraSettings()
	_updateReflectedTransform()


func _updateReflectionSize() -> void:
	var sourceSize: Vector2 = get_viewport().get_visible_rect().size
	if sourceSize.x <= 0.0 or sourceSize.y <= 0.0:
		return
	var scaleFactor: float = resolutionScale
	var longestEdge: float = maxf(sourceSize.x, sourceSize.y) * scaleFactor
	if longestEdge > float(maxResolution):
		scaleFactor *= float(maxResolution) / longestEdge
	var targetSize: Vector2i = Vector2i(
		maxi(MIN_REFLECTION_EDGE, int(round(sourceSize.x * scaleFactor))),
		maxi(MIN_REFLECTION_EDGE, int(round(sourceSize.y * scaleFactor)))
	)
	if targetSize == _reflectionSize:
		return
	_reflectionSize = targetSize
	_reflectionViewport.size = targetSize


func _copyCameraSettings() -> void:
	_reflectionCamera.projection = _sourceCamera.projection
	_reflectionCamera.fov = _sourceCamera.fov
	_reflectionCamera.size = _sourceCamera.size
	_reflectionCamera.near = _sourceCamera.near
	_reflectionCamera.far = _sourceCamera.far
	_reflectionCamera.frustum_offset = _sourceCamera.frustum_offset
	_reflectionCamera.h_offset = _sourceCamera.h_offset
	_reflectionCamera.v_offset = _sourceCamera.v_offset
	_reflectionCamera.keep_aspect = _sourceCamera.keep_aspect
	_reflectionCamera.environment = _sourceCamera.environment
	_reflectionCamera.attributes = _sourceCamera.attributes
	_reflectionCamera.cull_mask = _sourceCamera.cull_mask & ~MIRROR_VISUAL_LAYER


func _updateReflectedTransform() -> void:
	var planeNormal: Vector3 = global_basis.z.normalized()
	if planeNormal.is_zero_approx():
		return
	var cameraTransform: Transform3D = _sourceCamera.global_transform
	var reflectedPosition: Vector3 = _reflectPoint(cameraTransform.origin, global_position, planeNormal)
	var reflectedForward: Vector3 = _reflectVector(-cameraTransform.basis.z, planeNormal).normalized()
	var reflectedUp: Vector3 = _reflectVector(cameraTransform.basis.y, planeNormal).normalized()
	if reflectedForward.is_zero_approx() or reflectedUp.is_zero_approx():
		return
	_reflectionCamera.global_position = reflectedPosition
	_reflectionCamera.look_at(reflectedPosition + reflectedForward, reflectedUp)


## 隐藏完整镜面，并从当前镜面尺寸生成仍使用实时反射的物理碎片。
func shatter(impactPosition: Vector3) -> bool:
	if _isShattered:
		return false
	_isShattered = true
	_mirrorSurface.visible = false
	_spawnFragments(impactPosition)
	_reflectionCleanupTween = create_tween()
	_reflectionCleanupTween.tween_interval(fragmentLifetime + 0.8)
	_reflectionCleanupTween.tween_callback(_disableReflection)
	shattered.emit()
	return true


func resetShatter() -> void:
	if not _isShattered:
		return
	if _reflectionCleanupTween != null and _reflectionCleanupTween.is_valid():
		_reflectionCleanupTween.kill()
	_reflectionCleanupTween = null
	for fragment: RigidBody3D in _fragments:
		if is_instance_valid(fragment):
			fragment.queue_free()
	_fragments.clear()
	_isShattered = false
	_mirrorSurface.visible = true
	_reflectionViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	set_process(true)


func _spawnFragments(impactPosition: Vector3) -> void:
	var quad: QuadMesh = _mirrorSurface.mesh as QuadMesh
	var fragmentParent: Node = get_parent()
	if quad == null or fragmentParent == null:
		return

	var xAxis: Vector3 = global_basis.x.normalized()
	var yAxis: Vector3 = global_basis.y.normalized()
	var planeNormal: Vector3 = global_basis.z.normalized()
	var worldSize: Vector2 = Vector2(
		quad.size.x * global_basis.x.length(),
		quad.size.y * global_basis.y.length()
	)
	var cellSize: Vector2 = Vector2(
		worldSize.x / float(fragmentColumns),
		worldSize.y / float(fragmentRows)
	)
	var fragmentThickness: float = maxf(0.04, minf(cellSize.x, cellSize.y) * 0.025)
	var fragmentMaterial: ShaderMaterial = _createFragmentMaterial()
	var physicsMaterial: PhysicsMaterial = PhysicsMaterial.new()
	physicsMaterial.friction = 0.35
	physicsMaterial.bounce = 0.18
	var normalSign: float = signf((global_position - impactPosition).dot(planeNormal))
	var burstNormal: Vector3 = planeNormal * (-1.0 if is_zero_approx(normalSign) else normalSign)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.randomize()
	var points: PackedVector2Array = PackedVector2Array()
	for row: int in range(fragmentRows + 1):
		for column: int in range(fragmentColumns + 1):
			var pointX: float = -worldSize.x * 0.5 + float(column) * cellSize.x
			var pointY: float = -worldSize.y * 0.5 + float(row) * cellSize.y
			if column > 0 and column < fragmentColumns:
				pointX += random.randf_range(-cellSize.x, cellSize.x) * fragmentIrregularity
			if row > 0 and row < fragmentRows:
				pointY += random.randf_range(-cellSize.y, cellSize.y) * fragmentIrregularity
			points.append(Vector2(pointX, pointY))

	var triangleIndices: PackedInt32Array = Geometry2D.triangulate_delaunay(points)
	for triangleOffset: int in range(0, triangleIndices.size(), 3):
		var pointA: Vector2 = points[triangleIndices[triangleOffset]]
		var pointB: Vector2 = points[triangleIndices[triangleOffset + 1]]
		var pointC: Vector2 = points[triangleIndices[triangleOffset + 2]]
		_spawnTriangleFragment(
			fragmentParent,
			pointA,
			pointB,
			pointC,
			worldSize,
			fragmentThickness,
			fragmentMaterial,
			physicsMaterial,
			xAxis,
			yAxis,
			impactPosition,
			burstNormal,
			random,
			triangleOffset / 3
		)


func _spawnTriangleFragment(
	fragmentParent: Node,
	pointA: Vector2,
	pointB: Vector2,
	pointC: Vector2,
	worldSize: Vector2,
	fragmentThickness: float,
	fragmentMaterial: ShaderMaterial,
	physicsMaterial: PhysicsMaterial,
	xAxis: Vector3,
	yAxis: Vector3,
	impactPosition: Vector3,
	burstNormal: Vector3,
	random: RandomNumberGenerator,
	fragmentIndex: int
) -> void:
	var signedDoubleArea: float = (pointB - pointA).cross(pointC - pointA)
	var area: float = absf(signedDoubleArea) * 0.5
	if area <= 0.001:
		return
	if signedDoubleArea < 0.0:
		var swapPoint: Vector2 = pointB
		pointB = pointC
		pointC = swapPoint

	var center2D: Vector2 = (pointA + pointB + pointC) / 3.0
	var vertices: PackedVector3Array = PackedVector3Array([
		Vector3(pointA.x - center2D.x, pointA.y - center2D.y, 0.0),
		Vector3(pointB.x - center2D.x, pointB.y - center2D.y, 0.0),
		Vector3(pointC.x - center2D.x, pointC.y - center2D.y, 0.0)
	])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([
		Vector3.FORWARD,
		Vector3.FORWARD,
		Vector3.FORWARD
	])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([
		Vector2(pointA.x / worldSize.x + 0.5, 0.5 - pointA.y / worldSize.y),
		Vector2(pointB.x / worldSize.x + 0.5, 0.5 - pointB.y / worldSize.y),
		Vector2(pointC.x / worldSize.x + 0.5, 0.5 - pointC.y / worldSize.y)
	])
	var fragmentMesh: ArrayMesh = ArrayMesh.new()
	fragmentMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var halfThickness: float = fragmentThickness * 0.5
	var convexPoints: PackedVector3Array = PackedVector3Array()
	for vertex: Vector3 in vertices:
		convexPoints.append(vertex + Vector3(0.0, 0.0, halfThickness))
		convexPoints.append(vertex - Vector3(0.0, 0.0, halfThickness))
	var fragmentShape: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	fragmentShape.points = convexPoints

	var center: Vector3 = global_position + xAxis * center2D.x + yAxis * center2D.y
	var fragment: RigidBody3D = RigidBody3D.new()
	fragment.name = "MirrorFragment_%03d" % fragmentIndex
	fragment.collision_layer = 0
	fragment.collision_mask = 6
	fragment.gravity_scale = fragmentGravity
	fragment.mass = clampf(area * 0.02, 0.05, 2.0)
	fragment.physics_material_override = physicsMaterial
	fragmentParent.add_child(fragment)
	_fragments.append(fragment)
	fragment.global_transform = Transform3D(global_basis.orthonormalized(), center)

	var meshInstance: MeshInstance3D = MeshInstance3D.new()
	meshInstance.name = "Mesh"
	meshInstance.layers = MIRROR_VISUAL_LAYER
	meshInstance.mesh = fragmentMesh
	meshInstance.material_override = fragmentMaterial
	meshInstance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fragment.add_child(meshInstance)
	var collisionShape: CollisionShape3D = CollisionShape3D.new()
	collisionShape.name = "Collision"
	collisionShape.shape = fragmentShape
	fragment.add_child(collisionShape)

	var radialDirection: Vector3 = center - impactPosition
	if radialDirection.is_zero_approx():
		radialDirection = burstNormal
	var launchDirection: Vector3 = (
		radialDirection.normalized() * 0.35
		+ burstNormal
		+ Vector3.UP * random.randf_range(0.05, 0.25)
	).normalized()
	fragment.apply_central_impulse(
		launchDirection * fragmentImpulse * random.randf_range(0.75, 1.25) * fragment.mass
	)
	fragment.apply_torque_impulse(Vector3(
		random.randf_range(-1.0, 1.0),
		random.randf_range(-1.0, 1.0),
		random.randf_range(-1.0, 1.0)
	) * fragmentTorque * fragment.mass)

	var cleanupTween: Tween = fragment.create_tween()
	cleanupTween.tween_interval(fragmentLifetime + random.randf_range(-0.35, 0.35))
	cleanupTween.tween_property(fragment, "scale", Vector3.ZERO, 0.35)
	cleanupTween.finished.connect(fragment.queue_free)


func _createFragmentMaterial() -> ShaderMaterial:
	var sourceMaterial: ShaderMaterial = _mirrorSurface.material_override as ShaderMaterial
	var material: ShaderMaterial = sourceMaterial.duplicate() as ShaderMaterial
	material.set_shader_parameter("reflection_texture", _reflectionViewport.get_texture())
	material.set_shader_parameter("frame_width", 0.0)
	return material


func _disableReflection() -> void:
	set_process(false)
	_reflectionViewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _reflectPoint(point: Vector3, planeOrigin: Vector3, planeNormal: Vector3) -> Vector3:
	var distance: float = (point - planeOrigin).dot(planeNormal)
	return point - planeNormal * distance * 2.0


func _reflectVector(vector: Vector3, planeNormal: Vector3) -> Vector3:
	return vector - planeNormal * vector.dot(planeNormal) * 2.0
