package pool

import "core:mem"
import "core:testing"

@(test)
fills_and_rejects_when_full :: proc(t: ^testing.T) {
	p: Pool
	pool_init(&p, 4)
	defer pool_destroy(&p)
	handles: [4]Handle
	for i in 0 ..< 4 {
		h, ok := pool_add(&p, i * 10)
		testing.expect(t, ok, "add succeeds while there is room")
		handles[i] = h
	}
	testing.expect_value(t, pool_len(&p), 4)
	_, full_ok := pool_add(&p, 99)
	testing.expect(t, !full_ok, "add fails when full")
	v, got := pool_get(&p, handles[2])
	testing.expect_value(t, v, 20)
	testing.expect(t, got, "get finds a live handle")
}

@(test)
rejects_stale_handles_after_reuse :: proc(t: ^testing.T) {
	p: Pool
	pool_init(&p, 1)
	defer pool_destroy(&p)
	old, _ := pool_add(&p, 1)
	testing.expect(t, pool_remove(&p, old), "remove succeeds")
	testing.expect(t, !pool_remove(&p, old), "double remove is rejected")
	_, got := pool_get(&p, old)
	testing.expect(t, !got, "a removed handle is stale")
	fresh, ok := pool_add(&p, 2)
	testing.expect(t, ok, "the slot is reused")
	_, got_old := pool_get(&p, old)
	testing.expect(t, !got_old, "the old handle stays stale after reuse")
	v, got_new := pool_get(&p, fresh)
	testing.expect_value(t, v, 2)
	testing.expect(t, got_new, "the fresh handle works")
}

@(test)
invalid_handles_are_rejected :: proc(t: ^testing.T) {
	p: Pool
	pool_init(&p, 2)
	defer pool_destroy(&p)
	testing.expect(t, !pool_remove(&p, Handle{index = 50, gen = 0}), "out of range index")
	_, got := pool_get(&p, Handle{index = 50, gen = 0})
	testing.expect(t, !got, "out of range get")
}

@(test)
churn_does_not_allocate :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	allocator := mem.tracking_allocator(&track)
	p: Pool
	pool_init(&p, 64, allocator)
	setup := track.total_allocation_count
	bad := 0
	for i in 0 ..< 100000 {
		h, ok := pool_add(&p, i)
		v, got := pool_get(&p, h)
		if !ok || !got || v != i || !pool_remove(&p, h) {
			bad += 1
		}
	}
	testing.expect_value(t, bad, 0)
	testing.expect_value(t, track.total_allocation_count, setup)
	testing.expect_value(t, pool_len(&p), 0)
	testing.expect(t, setup <= 4, "setup uses a handful of allocations")
	pool_destroy(&p)
	testing.expect_value(t, len(track.allocation_map), 0)
}
