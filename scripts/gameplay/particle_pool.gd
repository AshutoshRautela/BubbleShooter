class_name BubbleParticlePool
extends RefCounted

const MAX_PARTICLES_MOBILE := 90
const MAX_PARTICLES_DESKTOP := 180

var particles: Array[Dictionary] = []
var rng: RandomNumberGenerator
var mobile_low_fx: bool = false


func _init(rng_ref: RandomNumberGenerator, mobile: bool = false) -> void:
	rng = rng_ref
	mobile_low_fx = mobile


func max_particles() -> int:
	return MAX_PARTICLES_MOBILE if mobile_low_fx else MAX_PARTICLES_DESKTOP


func is_empty() -> bool:
	return particles.is_empty()


func clear() -> void:
	particles.clear()


func update(delta: float) -> bool:
	if particles.is_empty():
		return false
	var write_index: int = 0
	for read_index in range(particles.size()):
		var particle: Dictionary = particles[read_index]
		var remaining: float = particle["life"] - delta
		if remaining <= 0.0:
			continue
		var position: Vector2 = particle["position"]
		var velocity: Vector2 = particle["velocity"]
		position += velocity * delta
		velocity *= 0.96
		velocity.y += 320.0 * delta
		particle["life"] = remaining
		particle["position"] = position
		particle["velocity"] = velocity
		particles[write_index] = particle
		write_index += 1
	if write_index != particles.size():
		particles.resize(write_index)
	return not particles.is_empty()


func spawn_burst(center: Vector2, bubble_color: Color, count: int, size_scale: float, bubble_radius: float) -> void:
	var limit: int = max_particles()
	for _index in range(count):
		if particles.size() >= limit:
			break
		var angle: float = rng.randf_range(0.0, TAU)
		var speed: float = rng.randf_range(bubble_radius * 3.6, bubble_radius * 7.4)
		var life: float = rng.randf_range(0.22, 0.5)
		var particle_color: Color = bubble_color.lerp(Color(1.0, 1.0, 1.0, 1.0), rng.randf_range(0.1, 0.35))
		particles.append({
			"position": center,
			"velocity": Vector2.RIGHT.rotated(angle) * speed,
			"life": life,
			"max_life": life,
			"size": size_scale * rng.randf_range(0.8, 1.5),
			"color": particle_color,
		})


func spawn_spark(center: Vector2, spark_color: Color, push: Vector2, bubble_radius: float) -> void:
	if particles.size() >= max_particles():
		return
	var particle_color: Color = spark_color.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.4)
	particles.append({
		"position": center,
		"velocity": push + Vector2(rng.randf_range(-50.0, 50.0), rng.randf_range(-80.0, 40.0)),
		"life": 0.16,
		"max_life": 0.16,
		"size": bubble_radius * 0.16,
		"color": particle_color,
	})


func spawn_impact_sparks(center: Vector2, bubble_color: Color, bubble_radius: float) -> void:
	var spark_count: int = 10 if mobile_low_fx else 16
	for index in range(spark_count):
		var angle: float = TAU * float(index) / float(spark_count) + rng.randf_range(-0.22, 0.22)
		var push: Vector2 = Vector2.RIGHT.rotated(angle) * rng.randf_range(120.0, 220.0)
		spawn_spark(center + push.normalized() * bubble_radius * 0.14, bubble_color.lightened(0.18), push, bubble_radius)
