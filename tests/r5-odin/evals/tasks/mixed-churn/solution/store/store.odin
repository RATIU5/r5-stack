package store

import "base:runtime"
import "core:mem/tlsf"

Id :: distinct u32

Record :: struct {
	data: []byte,
	live: bool,
}

Store :: struct {
	region:    []byte,
	heap:      tlsf.Allocator,
	records:   [dynamic]Record,
	free_ids:  [dynamic]Id,
	allocator: runtime.Allocator,
}

store_init :: proc(s: ^Store, capacity: int, allocator := context.allocator) {
	s.allocator = allocator
	s.region = make([]byte, capacity, allocator)
	_ = tlsf.init_from_buffer(&s.heap, s.region)
	s.records = make([dynamic]Record, 0, 1024, allocator)
	s.free_ids = make([dynamic]Id, 0, 1024, allocator)
}

store_destroy :: proc(s: ^Store) {
	tlsf.destroy(&s.heap)
	delete(s.records)
	delete(s.free_ids)
	delete(s.region, s.allocator)
	s^ = {}
}

store_add :: proc(s: ^Store, data: []byte) -> (id: Id, ok: bool) {
	block, err := runtime.mem_alloc_bytes(len(data), 8, tlsf.allocator(&s.heap))
	if err != nil {
		return
	}
	copy(block, data)
	record := Record{data = block[:len(data)], live = true}
	if len(s.free_ids) > 0 {
		id = pop(&s.free_ids)
		s.records[id] = record
	} else {
		id = Id(len(s.records))
		append(&s.records, record)
	}
	return id, true
}

store_get :: proc(s: ^Store, id: Id) -> (data: []byte, ok: bool) {
	if int(id) >= len(s.records) || !s.records[id].live {
		return
	}
	return s.records[id].data, true
}

store_remove :: proc(s: ^Store, id: Id) -> bool {
	if int(id) >= len(s.records) || !s.records[id].live {
		return false
	}
	runtime.mem_free(raw_data(s.records[id].data), tlsf.allocator(&s.heap))
	s.records[id] = {}
	append(&s.free_ids, id)
	return true
}
