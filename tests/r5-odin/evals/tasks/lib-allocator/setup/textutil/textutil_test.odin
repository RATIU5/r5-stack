package textutil

import "core:mem"
import "core:testing"

@(test)
uses_the_given_allocator :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)

	buf: [1024]byte
	arena: mem.Arena
	mem.arena_init(&arena, buf[:])
	result := join_lines([]string{"a", "bc"}, mem.arena_allocator(&arena))
	testing.expect_value(t, result, "a\nbc")
	testing.expect_value(t, len(track.allocation_map), 0)
}
