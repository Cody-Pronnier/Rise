class_name UltimateCardStyle
extends RefCounted
## Habillage des cartes ultimes : cadre doré lumineux, bandeau doré, reflet qui balaie la carte
## et sujet « overframe » qui respire. CardView décide quand l'appliquer.

const FRAME_COLOR := Color(0.2, 0.14, 0.07)
const FRAME_BORDER: int = 4
const GLOW_SIZE: int = 14
const BANNER_COLOR := Color(0.55, 0.38, 0.1)
const NAME_COLOR := Color(1.0, 0.92, 0.6)
const BREATH_SCALE: float = 1.04
const BREATH_DURATION: float = 2.6

## Bande de lumière diagonale qui traverse la carte, découpée aux coins arrondis.
const SHINE_SHADER: String = """
shader_type canvas_item;
render_mode blend_add;

uniform vec2 rect_size = vec2(170.0, 240.0);
uniform float radius = 12.0;
uniform float speed = 0.3;
uniform float strength = 0.3;

float rounded_box(vec2 point, vec2 half_size, float r) {
	vec2 q = abs(point) - (half_size - vec2(r));
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 point = UV * rect_size - rect_size * 0.5;
	float inside = 1.0 - smoothstep(-1.0, 0.0, rounded_box(point, rect_size * 0.5, radius));
	float position = mix(-0.6, 2.4, fract(TIME * speed));
	float band = smoothstep(0.16, 0.0, abs(UV.x + UV.y * 0.6 - position));
	COLOR = vec4(vec3(1.0, 0.92, 0.65) * band * strength * inside, 1.0);
}
"""

static var _shine_material: ShaderMaterial


static func shine_material() -> ShaderMaterial:
	if _shine_material == null:
		var shader := Shader.new()
		shader.code = SHINE_SHADER
		_shine_material = ShaderMaterial.new()
		_shine_material.shader = shader
	return _shine_material


static func frame_style(radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = UiStyle.box(FRAME_COLOR, radius, UiStyle.GOLD, FRAME_BORDER)
	return UiStyle.with_shadow(style, Color(UiStyle.GOLD, 0.55), GLOW_SIZE)


static func banner_style() -> StyleBoxFlat:
	return UiStyle.with_margins(UiStyle.box(BANNER_COLOR, 6, UiStyle.GOLD, 2), 6.0, 3.0)


## Le sujet grandit légèrement depuis sa base, en boucle. Le tween vit avec le nœud.
static func start_breathing(subject: Control) -> Tween:
	subject.pivot_offset = Vector2(subject.size.x / 2.0, subject.size.y)
	var tween: Tween = subject.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(subject, "scale", Vector2.ONE * BREATH_SCALE, BREATH_DURATION / 2.0)
	tween.tween_property(subject, "scale", Vector2.ONE, BREATH_DURATION / 2.0)
	return tween
