package main

import "../store"
import "core:fmt"
import "core:mem"

CAPACITY :: 32 * 1024 * 1024
LIVE_LIMIT :: 24 * 1024 * 1024
OPS :: 300000

Rng :: struct {
	state: u64,
}

next :: proc(r: ^Rng) -> u64 {
	r.state ~= r.state << 13
	r.state ~= r.state >> 7
	r.state ~= r.state << 17
	return r.state
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	allocator := mem.tracking_allocator(&track)

	s: store.Store
	store.store_init(&s, CAPACITY, allocator)

	ids: [dynamic]store.Id
	sizes: [dynamic]int
	tags: [dynamic]int
	rng := Rng{88172645463325252}
	live_bytes, peak_live, failed, corrupt := 0, 0, 0, 0

	for op in 0 ..< OPS {
		size := 16 + int(next(&rng) % 4081)
		remove_now := live_bytes + size > LIVE_LIMIT || (len(ids) > 0 && next(&rng) % 4 == 0)
		if remove_now && len(ids) > 0 {
			k := int(next(&rng) % u64(len(ids)))
			data, ok := store.store_get(&s, ids[k])
			if !ok || len(data) != sizes[k] {
				corrupt += 1
			} else {
				for j in 0 ..< len(data) {
					if data[j] != byte(tags[k] + j) {
						corrupt += 1
						break
					}
				}
			}
			store.store_remove(&s, ids[k])
			live_bytes -= sizes[k]
			unordered_remove(&ids, k)
			unordered_remove(&sizes, k)
			unordered_remove(&tags, k)
		} else {
			buf := make([]byte, size)
			for j in 0 ..< size {
				buf[j] = byte(op + j)
			}
			id, ok := store.store_add(&s, buf)
			delete(buf)
			if ok {
				append(&ids, id)
				append(&sizes, size)
				append(&tags, op)
				live_bytes += size
				peak_live = max(peak_live, live_bytes)
			} else {
				failed += 1
			}
		}
	}

	allocations := track.total_allocation_count
	store.store_destroy(&s)
	fmt.println("failed_adds", failed)
	fmt.println("corrupt", corrupt)
	fmt.println("allocations", allocations)
	fmt.println("peak_live_bytes", peak_live)
	fmt.println("live", len(track.allocation_map))
}
