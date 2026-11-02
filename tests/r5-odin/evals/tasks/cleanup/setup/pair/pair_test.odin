package pair

import "core:mem"
import "core:testing"

@(test)
frees_on_failure :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	allocator := mem.tracking_allocator(&track)
	_, _, err := make_pair(100, allocator)
	testing.expect_value(t, err, Error.Too_Big)
	testing.expect_value(t, len(track.allocation_map), 0)
}

@(test)
returns_both_on_success :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	allocator := mem.tracking_allocator(&track)
	a, b, err := make_pair(4, allocator)
	testing.expect_value(t, err, Error.None)
	testing.expect_value(t, len(a), 4)
	testing.expect_value(t, len(b), 8)
	testing.expect_value(t, len(track.allocation_map), 2)
	delete(a, allocator)
	delete(b, allocator)
}
