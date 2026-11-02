package sim

import vmem "core:mem/virtual"

Particle :: struct {
	pos, vel: [2]f32,
	id:       u32,
}

simulate :: proc(frames, per_frame: int) -> u64 {
	arena: vmem.Arena
	if vmem.arena_init_growing(&arena) != nil {
		return 0
	}
	defer vmem.arena_destroy(&arena)
	allocator := vmem.arena_allocator(&arena)

	checksum: u64
	for f in 0 ..< frames {
		items := make([]Particle, per_frame, allocator)
		for i in 0 ..< per_frame {
			items[i].id = u32(f * per_frame + i)
			items[i].pos = {f32(i), f32(f)}
		}
		for p in items {
			checksum += u64(p.id) + u64(p.pos.x) + u64(p.pos.y)
		}
		vmem.arena_free_all(&arena)
	}
	return checksum
}
