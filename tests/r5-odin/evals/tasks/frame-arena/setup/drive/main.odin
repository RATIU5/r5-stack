package main

import "../sim"
import "core:fmt"
import "core:mem"

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)
	checksum := sim.simulate(1000, 10000)
	fmt.println("checksum", checksum)
	fmt.println("allocations", track.total_allocation_count)
	fmt.println("live", len(track.allocation_map))
}
