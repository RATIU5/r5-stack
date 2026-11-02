package main

import "../pool"
import "core:fmt"
import "core:mem"

RING :: 1024
OPS :: 2000000

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	allocator := mem.tracking_allocator(&track)

	p: pool.Pool
	pool.pool_init(&p, RING, allocator)
	handles: [RING]pool.Handle
	sum: u64
	for i in 0 ..< OPS {
		slot := i % RING
		if i >= RING {
			v, _ := pool.pool_get(&p, handles[slot])
			sum += u64(v)
			pool.pool_remove(&p, handles[slot])
		}
		handles[slot], _ = pool.pool_add(&p, i)
	}
	for slot in 0 ..< RING {
		v, _ := pool.pool_get(&p, handles[slot])
		sum += u64(v)
		pool.pool_remove(&p, handles[slot])
	}
	allocations := track.total_allocation_count
	pool.pool_destroy(&p)
	fmt.println("sum", sum)
	fmt.println("allocations", allocations)
	fmt.println("live", len(track.allocation_map))
}
