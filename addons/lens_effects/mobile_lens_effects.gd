@tool
extends WorldEnvironment
class_name MobileLensEffects

const MOBILE_FLARE_SHADER: Shader = preload("res://addons/lens_effects/mobile_lens_flare.gdshader")

@export var sun: DirectionalLight3D:
	set(value):
		sun = value
		update_configuration_warnings()
@export_color_no_alpha var sunColor: Color = Color(1.0, 0.8784314, 0.627451)
@export_range(0.0, 2.0, 0.01) var intensity: float = 0.7
@export_range(0.0, 2.0, 0.01) var rayStrength: float = 0.35
@export_range(0.0, 2.0, 0.01) var flareStrength: float = 0.45

var _overlayLayer: CanvasLayer
var _overlayRect: ColorRect
var _overlayMaterial: ShaderMaterial

func _ready() -> void:
	_ensureOverlay()

func _process(_delta: float) -> void:
	_ensureOverlay()
	var camera: Camera3D = _getActiveCamera()
	var viewportSize: Vector2 = _getViewportSize()
	if sun == null or camera == null or viewportSize.x <= 0.0 or viewportSize.y <= 0.0:
		_overlayMaterial.set_shader_parameter("visibility", 0.0)
		return

	var sunDirection: Vector3 = sun.global_transform.basis.z.normalized()
	var cameraForward: Vector3 = -camera.global_transform.basis.z.normalized()
	var directionVisibility: float = smoothstep(0.0, 0.18, cameraForward.dot(sunDirection))
	var projectionPoint: Vector3 = camera.global_position + sunDirection * maxf(camera.near, 1.0)
	var projectedPosition: Vector2 = camera.unproject_position(projectionPoint) / viewportSize
	var edgeDistance: float = maxf(absf(projectedPosition.x - 0.5), absf(projectedPosition.y - 0.5))
	var edgeVisibility: float = 1.0 - smoothstep(0.52, 0.78, edgeDistance)

	_overlayMaterial.set_shader_parameter("sun_uv", projectedPosition)
	_overlayMaterial.set_shader_parameter("sun_color", Color(sunColor, 1.0))
	_overlayMaterial.set_shader_parameter("visibility", directionVisibility * edgeVisibility)
	_overlayMaterial.set_shader_parameter("intensity", intensity)
	_overlayMaterial.set_shader_parameter("ray_strength", rayStrength)
	_overlayMaterial.set_shader_parameter("flare_strength", flareStrength)

func _ensureOverlay() -> void:
	if is_instance_valid(_overlayLayer):
		return
	_overlayLayer = CanvasLayer.new()
	_overlayLayer.name = "MobileLensOverlay"
	_overlayLayer.layer = -10
	add_child(_overlayLayer)

	_overlayRect = ColorRect.new()
	_overlayRect.name = "LensFlare"
	_overlayRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlayRect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlayLayer.add_child(_overlayRect)

	_overlayMaterial = ShaderMaterial.new()
	_overlayMaterial.shader = MOBILE_FLARE_SHADER
	_overlayRect.material = _overlayMaterial

func _getActiveCamera() -> Camera3D:
	if Engine.is_editor_hint():
		var editorViewport: SubViewport = EditorInterface.get_editor_viewport_3d()
		return editorViewport.get_camera_3d() if editorViewport != null else null
	return get_viewport().get_camera_3d()

func _getViewportSize() -> Vector2:
	if Engine.is_editor_hint():
		var editorViewport: SubViewport = EditorInterface.get_editor_viewport_3d()
		return editorViewport.get_visible_rect().size if editorViewport != null else Vector2.ZERO
	return get_viewport().get_visible_rect().size

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if sun == null:
		warnings.append("Assign a DirectionalLight3D as the lens effect sun reference.")
	return warnings
