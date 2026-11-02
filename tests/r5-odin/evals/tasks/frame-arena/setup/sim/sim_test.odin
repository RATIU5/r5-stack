package sim

import "core:mem"
import "core:testing"

expected :: proc(frames, per_frame: int) -> u64 {
	f := u64(frames)
	p := u64(per_frame)
	return p * (p + 1) * f * (f - 1) / 2 + f * p * (p - 1)
}

@(test)
checksum_is_unchanged :: proc(t: ^testing.T) {
	testing.expect_value(t, simulate(100, 2000), expected(100, 2000))
	testing.expect_value(t, simulate(1, 1), expected(1, 1))
}

@(test)
makes_only_a_handful_of_heap_allocations :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
	context.allocator = mem.tracking_allocator(&track)

	checksum := simulate(200, 2000)
	testing.expect_value(t, checksum, expected(200, 2000))
	testing.expect(t, track.total_allocation_count <= 50, "at most 50 heap allocations in total")
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}
