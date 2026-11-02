package store

import "core:mem"
import "core:testing"

@(test)
add_get_remove :: proc(t: ^testing.T) {
	s: Store
	store_init(&s, 1 << 20)
	defer store_destroy(&s)
	data := []byte{1, 2, 3, 4}
	id, ok := store_add(&s, data)
	testing.expect(t, ok, "add")
	data[0] = 99
	got, found := store_get(&s, id)
	testing.expect(t, found, "get")
	testing.expect_value(t, len(got), 4)
	if len(got) == 4 {
		testing.expect_value(t, got[0], 1)
		testing.expect_value(t, got[3], 4)
	}
	testing.expect(t, store_remove(&s, id), "remove")
	testing.expect(t, !store_remove(&s, id), "second remove is rejected")
	_, found_again := store_get(&s, id)
	testing.expect(t, !found_again, "removed record is gone")
	_, found_unknown := store_get(&s, Id(123456))
	testing.expect(t, !found_unknown, "unknown id")
}

@(test)
full_store_rejects_then_recovers :: proc(t: ^testing.T) {
	s: Store
	store_init(&s, 1 << 20)
	defer store_destroy(&s)
	block: [4096]byte
	ids: [dynamic]Id
	defer delete(ids)
	for {
		id, ok := store_add(&s, block[:])
		if !ok {
			break
		}
		append(&ids, id)
		if len(ids) > 1000 {
			break
		}
	}
	testing.expect(t, len(ids) >= 150, "a 1 MiB store holds at least 150 records of 4 KiB")
	testing.expect(t, len(ids) <= 256, "a 1 MiB store cannot hold more than 256 records of 4 KiB")
	testing.expect(t, store_remove(&s, ids[0]), "remove")
	_, ok := store_add(&s, block[:])
	testing.expect(t, ok, "space freed by remove is reusable")
}

@(test)
churn_makes_few_allocations :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	allocator := mem.tracking_allocator(&track)
	s: Store
	store_init(&s, 8 << 20, allocator)
	buf: [512]byte
	bad := 0
	for i in 0 ..< 20000 {
		size := 16 + (i * 37) % 497
		id, ok := store_add(&s, buf[:size])
		if !ok {
			bad += 1
			continue
		}
		if i % 2 == 0 && !store_remove(&s, id) {
			bad += 1
		}
	}
	testing.expect(t, track.total_allocation_count <= 100, "at most 100 allocations")
	store_destroy(&s)
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, bad, 0)
}
