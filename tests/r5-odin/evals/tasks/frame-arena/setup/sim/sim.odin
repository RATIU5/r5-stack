package sim

Particle :: struct {
	pos, vel: [2]f32,
	id:       u32,
}

simulate :: proc(frames, per_frame: int) -> u64 {
	checksum: u64
	for f in 0 ..< frames {
		items := make([dynamic]^Particle, 0, 0)
		for i in 0 ..< per_frame {
			p := new(Particle)
			p.id = u32(f * per_frame + i)
			p.pos = {f32(i), f32(f)}
			append(&items, p)
		}
		for p in items {
			checksum += u64(p.id) + u64(p.pos.x) + u64(p.pos.y)
			free(p)
		}
		delete(items)
	}
	return checksum
}
