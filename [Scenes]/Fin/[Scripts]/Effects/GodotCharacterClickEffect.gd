extends Node3D

const RING_DURATION: float = 1.05
const CORE_DURATION: float = 0.46
const FLASH_DURATION: float = 0.86
const LIGHT_DURATION: float = 0.55

@onready var flash: MeshInstance3D = $Flash
@onready var outerRing: MeshInstance3D = $OuterRing
@onready var innerRing: MeshInstance3D = $InnerRing
@onready var coreMesh: MeshInstance3D = $Core
@onready var sparks: GPUParticles3D = $Sparks
@onready var glowLight: OmniLight3D = $GlowLight

var flashMaterial: ShaderMaterial
var outerMaterial: StandardMaterial3D
var innerMaterial: StandardMaterial3D
var coreMaterial: StandardMaterial3D

func _ready() -> void:
	flashMaterial = flash.material_override as ShaderMaterial
	outerMaterial = outerRing.material_override as StandardMaterial3D
	innerMaterial = innerRing.material_override as StandardMaterial3D
	coreMaterial = coreMesh.material_override as StandardMaterial3D
	if flashMaterial == null or outerMaterial == null or innerMaterial == null or coreMaterial == null:
		queue_free()
		return

	flashMaterial.set_shader_parameter("intensity", 4.0)
	flashMaterial.set_shader_parameter("ring_radius", 0.12)
	if sparks:
		sparks.restart()
		sparks.emitting = true
	_start_animation()


func _start_animation() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector3(1.35, 1.35, 1.35), FLASH_DURATION) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_flash_intensity, 4.0, 0.0, FLASH_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_flash_radius, 0.12, 1.0, FLASH_DURATION) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(outerRing, "scale", Vector3(5.5, 5.5, 5.5), RING_DURATION) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(innerRing, "scale", Vector3(4.0, 4.0, 4.0), RING_DURATION) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(outerRing, "rotation:y", TAU, RING_DURATION)
	tween.tween_property(innerRing, "rotation:y", -TAU, RING_DURATION)
	tween.tween_method(_set_outer_alpha, 1.0, 0.0, RING_DURATION)
	tween.tween_method(_set_inner_alpha, 1.0, 0.0, RING_DURATION)
	tween.tween_property(coreMesh, "scale", Vector3(4.0, 4.0, 4.0), CORE_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_core_alpha, 1.0, 0.0, CORE_DURATION)
	tween.tween_property(glowLight, "light_energy", 0.0, LIGHT_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(queue_free)


func _set_flash_intensity(intensity: float) -> void:
	flashMaterial.set_shader_parameter("intensity", intensity)


func _set_flash_radius(radius: float) -> void:
	flashMaterial.set_shader_parameter("ring_radius", radius)


func _set_outer_alpha(alpha: float) -> void:
	_set_material_alpha(outerMaterial, alpha)


func _set_inner_alpha(alpha: float) -> void:
	_set_material_alpha(innerMaterial, alpha)


func _set_core_alpha(alpha: float) -> void:
	_set_material_alpha(coreMaterial, alpha)


func _set_material_alpha(material: StandardMaterial3D, alpha: float) -> void:
	var color: Color = material.albedo_color
	color.a = alpha
	material.albedo_color = color
