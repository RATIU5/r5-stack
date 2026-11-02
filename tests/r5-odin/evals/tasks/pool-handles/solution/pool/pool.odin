package pool

import "base:runtime"

Handle :: struct {
	index, gen: u32,
}

Slot :: struct {
	value: int,
	gen:   u32,
	live:  bool,
}

Pool :: struct {
	slots:      []Slot,
	free:       []u32,
	free_count: int,
	live:       int,
	allocator:  runtime.Allocator,
}

pool_init :: proc(p: ^Pool, capacity: int, allocator := context.allocator) {
	p.allocator = allocator
	p.slots = make([]Slot, capacity, allocator)
	p.free = make([]u32, capacity, allocator)
	for i in 0 ..< capacity {
		p.free[i] = u32(capacity - 1 - i)
	}
	p.free_count = capacity
	p.live = 0
}

pool_destroy :: proc(p: ^Pool) {
	delete(p.slots, p.allocator)
	delete(p.free, p.allocator)
	p^ = {}
}

pool_add :: proc(p: ^Pool, value: int) -> (h: Handle, ok: bool) {
	if p.free_count == 0 {
		return
	}
	p.free_count -= 1
	index := p.free[p.free_count]
	slot := &p.slots[index]
	slot.value = value
	slot.live = true
	p.live += 1
	return Handle{index, slot.gen}, true
}

pool_remove :: proc(p: ^Pool, h: Handle) -> bool {
	if int(h.index) >= len(p.slots) {
		return false
	}
	slot := &p.slots[h.index]
	if !slot.live || slot.gen != h.gen {
		return false
	}
	slot.live = false
	slot.gen += 1
	p.free[p.free_count] = h.index
	p.free_count += 1
	p.live -= 1
	return true
}

pool_get :: proc(p: ^Pool, h: Handle) -> (value: int, ok: bool) {
	if int(h.index) >= len(p.slots) {
		return
	}
	slot := p.slots[h.index]
	if !slot.live || slot.gen != h.gen {
		return
	}
	return slot.value, true
}

pool_len :: proc(p: ^Pool) -> int {
	return p.live
}
