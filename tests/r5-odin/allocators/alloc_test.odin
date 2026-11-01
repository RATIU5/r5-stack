package allocators

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:mem/tlsf"
import vmem "core:mem/virtual"
import "core:testing"

Free_Node :: struct {
	next: ^Free_Node,
}

Pool :: struct {
	chunk_size: int,
	free_head:  ^Free_Node,
	region:     []byte,
	used:       int,
}

pool_init :: proc(p: ^Pool, region: []byte, chunk_size: int) {
	p.chunk_size = max(chunk_size, size_of(Free_Node))
	p.region = region
	p.free_head = nil
	p.used = 0
}

pool_allocator :: proc(p: ^Pool) -> mem.Allocator {
	return {procedure = pool_proc, data = p}
}

pool_proc :: proc(
	allocator_data: rawptr,
	mode: mem.Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (
	[]byte,
	mem.Allocator_Error,
) {
	p := cast(^Pool)allocator_data
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		if size > p.chunk_size {
			return nil, .Invalid_Argument
		}
		chunk: rawptr
		if p.free_head != nil {
			chunk = p.free_head
			p.free_head = p.free_head.next
		} else {
			if p.used + p.chunk_size > len(p.region) {
				return nil, .Out_Of_Memory
			}
			chunk = &p.region[p.used]
			p.used += p.chunk_size
		}
		bytes := mem.byte_slice(chunk, p.chunk_size)
		if mode == .Alloc {
			mem.zero_slice(bytes)
		}
		return bytes[:size], nil
	case .Free:
		if old_memory == nil {
			return nil, nil
		}
		node := cast(^Free_Node)old_memory
		node.next = p.free_head
		p.free_head = node
		return nil, nil
	case .Free_All:
		p.free_head = nil
		p.used = 0
		return nil, nil
	case .Resize, .Resize_Non_Zeroed:
		return nil, .Mode_Not_Implemented
	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Query_Features}
		}
		return nil, nil
	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}
	return nil, nil
}

Frame_Arenas :: struct {
	arenas:  [2]vmem.Arena,
	current: int,
}

frames_init :: proc(f: ^Frame_Arenas, reserve: uint) -> (err: mem.Allocator_Error) {
	vmem.arena_init_static(&f.arenas[0], reserve) or_return
	vmem.arena_init_static(&f.arenas[1], reserve) or_return
	return nil
}

frames_allocator :: proc(f: ^Frame_Arenas) -> mem.Allocator {
	return vmem.arena_allocator(&f.arenas[f.current])
}

frames_next :: proc(f: ^Frame_Arenas) {
	f.current = 1 - f.current
	vmem.arena_free_all(&f.arenas[f.current])
}

Table :: struct {
	vals: [4]int,
}
table: Table

@(test)
static_is_zero :: proc(t: ^testing.T) {
	testing.expect_value(t, table.vals[3], 0)
}

@(test)
arena_basics :: proc(t: ^testing.T) {
	buf: [256]byte
	a: mem.Arena
	mem.arena_init(&a, buf[:])
	al := mem.arena_allocator(&a)
	p, err := mem.alloc(64, 8, al)
	testing.expect_value(t, err, mem.Allocator_Error.None)
	testing.expect_value(t, mem.free(p, al), mem.Allocator_Error.Mode_Not_Implemented)
	_, err2 := mem.alloc(1024, 8, al)
	testing.expect_value(t, err2, mem.Allocator_Error.Out_Of_Memory)
	mem.free_all(al)
	_, err3 := mem.alloc(200, 8, al)
	testing.expect_value(t, err3, mem.Allocator_Error.None)
}

@(test)
arena_resize_moves :: proc(t: ^testing.T) {
	buf: [512]byte
	a: mem.Arena
	mem.arena_init(&a, buf[:])
	al := mem.arena_allocator(&a)
	p, _ := mem.alloc(16, 8, al)
	q, err := mem.resize(p, 16, 64, allocator = al)
	testing.expect_value(t, err, mem.Allocator_Error.None)
	testing.expect(t, p != q, "resize on arena with a later allocation moved")
	_ = q
}

@(test)
dirty_buffer_alloc :: proc(t: ^testing.T) {
	buf: [64]byte
	for &b in buf {
		b = 170
	}
	a: mem.Arena
	mem.arena_init(&a, buf[:])
	al := mem.arena_allocator(&a)
	z, _ := mem.alloc_bytes(8, 8, al)
	testing.expect_value(t, z[0], 0)
	for &b in buf {
		b = 170
	}
	mem.free_all(al)
	nz, _ := mem.alloc_bytes_non_zeroed(8, 8, al)
	testing.expect_value(t, nz[0], 170)
}

@(test)
vmem_static_and_temp :: proc(t: ^testing.T) {
	a: vmem.Arena
	testing.expect_value(t, vmem.arena_init_static(&a, 1 << 20), nil)
	defer vmem.arena_destroy(&a)
	al := vmem.arena_allocator(&a)
	x, _ := mem.alloc(100, 8, al)
	used := a.total_used
	tmp := vmem.arena_temp_begin(&a)
	y, _ := mem.alloc(1000, 8, al)
	testing.expect(t, y != nil && x != nil, "allocs")
	vmem.arena_temp_end(tmp)
	testing.expect_value(t, a.total_used, used)
}

@(test)
vmem_growing_and_constants :: proc(t: ^testing.T) {
	a: vmem.Arena
	testing.expect_value(t, vmem.arena_init_growing(&a), nil)
	defer vmem.arena_destroy(&a)
	al := vmem.arena_allocator(&a)
	for _ in 0 ..< 4 {
		_, err := mem.alloc(512 * 1024, 8, al)
		testing.expect_value(t, err, mem.Allocator_Error.None)
	}
	fmt.println(
		"static reserve",
		vmem.DEFAULT_ARENA_STATIC_RESERVE_SIZE,
		"growing min",
		vmem.DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE,
	)
	testing.expect_value(t, vmem.DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE, 1 << 20)
	testing.expect_value(t, vmem.DEFAULT_ARENA_STATIC_RESERVE_SIZE, 1 << 30)
}

@(test)
vmem_buffer_dirty :: proc(t: ^testing.T) {
	buf: [128]byte
	for &b in buf {
		b = 170
	}
	a: vmem.Arena
	testing.expect_value(t, vmem.arena_init_buffer(&a, buf[:]), nil)
	al := vmem.arena_allocator(&a)
	p, _ := mem.alloc_bytes(8, 8, al)
	fmt.println("vmem buffer first byte", p[0])
}

@(test)
scratch_wraps :: proc(t: ^testing.T) {
	s: mem.Scratch
	testing.expect_value(t, mem.scratch_init(&s, 256), nil)
	defer mem.scratch_destroy(&s)
	al := mem.scratch_allocator(&s)
	a, _ := mem.alloc(200, 8, al)
	b, _ := mem.alloc(200, 8, al)
	testing.expect(t, a == b, "wraps to offset 0 and reuses the start")
	big, err := mem.alloc(4096, 8, al)
	testing.expect_value(t, err, mem.Allocator_Error.None)
	testing.expect(t, big != nil, "larger than the buffer goes to the backup allocator")
	testing.expect(t, len(s.leaked_allocations) == 1, "tracked as leak")
}

@(test)
stack_lifo :: proc(t: ^testing.T) {
	buf: [512]byte
	s: mem.Stack
	mem.stack_init(&s, buf[:])
	al := mem.stack_allocator(&s)
	a, _ := mem.alloc(16, 8, al)
	b, _ := mem.alloc(16, 8, al)
	testing.expect_value(t, mem.free(a, al), mem.Allocator_Error.Invalid_Pointer)
	testing.expect_value(t, mem.free(b, al), mem.Allocator_Error.None)
	testing.expect_value(t, mem.free(a, al), mem.Allocator_Error.None)
	testing.expect_value(t, size_of(mem.Stack_Allocation_Header), 16)
}

@(test)
small_stack_interior_free :: proc(t: ^testing.T) {
	buf: [512]byte
	s: mem.Small_Stack
	mem.small_stack_init(&s, buf[:])
	al := mem.small_stack_allocator(&s)
	a, _ := mem.alloc(16, 8, al)
	_, _ = mem.alloc(16, 8, al)
	testing.expect_value(t, mem.free(a, al), mem.Allocator_Error.None)
	testing.expect_value(t, s.offset, 0)
}

@(test)
dynamic_arena :: proc(t: ^testing.T) {
	a: mem.Dynamic_Arena
	mem.dynamic_arena_init(&a)
	defer mem.dynamic_arena_destroy(&a)
	al := mem.dynamic_arena_allocator(&a)
	p, err := mem.alloc(100, 8, al)
	testing.expect_value(t, err, mem.Allocator_Error.None)
	testing.expect_value(t, mem.free(p, al), mem.Allocator_Error.Mode_Not_Implemented)
	fmt.println("dynamic block size", a.block_size, "out of band", a.out_band_size)
	testing.expect_value(t, a.block_size, 65536)
	mem.dynamic_arena_reset(&a)
	_, err2 := mem.alloc(100, 8, al)
	testing.expect_value(t, err2, mem.Allocator_Error.None)
}

@(test)
buddy_double_free :: proc(t: ^testing.T) {
	buf, _ := mem.make_aligned([]byte, 4096, 16, context.allocator)
	defer delete(buf)
	b: mem.Buddy_Allocator
	mem.buddy_allocator_init(&b, buf, 16)
	al := mem.buddy_allocator(&b)
	p, _ := mem.alloc(100, 8, al)
	testing.expect_value(t, mem.free(p, al), mem.Allocator_Error.None)
	testing.expect_value(t, mem.free(p, al), mem.Allocator_Error.None)
}

@(test)
rollback_stack :: proc(t: ^testing.T) {
	buf: [1024]byte
	s: mem.Rollback_Stack
	mem.rollback_stack_init_buffered(&s, buf[:])
	al := mem.rollback_stack_allocator(&s)
	a, _ := mem.alloc(16, 8, al)
	b, _ := mem.alloc(16, 8, al)
	testing.expect_value(t, mem.free(a, al), mem.Allocator_Error.None)
	testing.expect_value(t, mem.free(b, al), mem.Allocator_Error.None)
	testing.expect_value(t, mem.free(b, al), mem.Allocator_Error.Invalid_Pointer)
}

@(test)
tlsf_basic :: proc(t: ^testing.T) {
	buf := make([]byte, 1 << 16)
	defer delete(buf)
	a: tlsf.Allocator
	testing.expect_value(t, tlsf.init_from_buffer(&a, buf), tlsf.Error.None)
	defer tlsf.destroy(&a)
	al := tlsf.allocator(&a)
	p, err := mem.alloc(100, 8, al)
	testing.expect_value(t, err, mem.Allocator_Error.None)
	testing.expect_value(t, mem.free(p, al), mem.Allocator_Error.None)
}

@(test)
tracking_bad_free_and_leak :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
	al := mem.tracking_allocator(&track)
	p, _ := mem.alloc(8, 8, al)
	_, _ = mem.alloc(8, 8, al)
	testing.expect_value(t, len(track.allocation_map), 2)
	mem.free(p, al)
	mem.free(p, al)
	testing.expect_value(t, len(track.bad_free_array), 1)
	testing.expect_value(t, len(track.allocation_map), 1)
	free_all_tracking := track.allocation_map
	_ = free_all_tracking
	for ptr in track.allocation_map {
		mem.free(ptr, context.allocator)
	}
}

@(test)
mutex_allocator_works :: proc(t: ^testing.T) {
	buf: [256]byte
	a: mem.Arena
	mem.arena_init(&a, buf[:])
	m: mem.Mutex_Allocator
	mem.mutex_allocator_init(&m, mem.arena_allocator(&a))
	al := mem.mutex_allocator(&m)
	p, err := mem.alloc(16, 8, al)
	testing.expect(t, p != nil, "mutex alloc")
	testing.expect_value(t, err, mem.Allocator_Error.None)
}

@(test)
nil_allocators :: proc(t: ^testing.T) {
	p, err := mem.alloc(8, 8, mem.nil_allocator())
	testing.expect(t, p == nil, "mem.nil_allocator returns nil")
	testing.expect_value(t, err, mem.Allocator_Error.None)
	p2, err2 := mem.alloc(8, 8, runtime.nil_allocator())
	testing.expect(t, p2 == nil, "runtime.nil_allocator returns nil")
	testing.expect_value(t, err2, mem.Allocator_Error.Out_Of_Memory)
}

@(test)
temp_allocator :: proc(t: ^testing.T) {
	testing.expect_value(t, runtime.DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE, 4 * 1024 * 1024)
	guard := runtime.default_temp_allocator_temp_begin()
	buf := make([]byte, 1024, context.temp_allocator)
	testing.expect_value(t, len(buf), 1024)
	runtime.default_temp_allocator_temp_end(guard)
	free_all(context.temp_allocator)
}

@(test)
test_context_allocator_is_not_default :: proc(t: ^testing.T) {
	testing.expect(
		t,
		context.allocator.procedure != runtime.default_allocator_proc,
		"tracking in tests",
	)
}

@(test)
dynamic_arena_sizes :: proc(t: ^testing.T) {
	a: mem.Dynamic_Arena
	mem.dynamic_arena_init(&a)
	defer mem.dynamic_arena_destroy(&a)
	al := mem.dynamic_arena_allocator(&a)
	_, e1 := mem.alloc(8000, 8, al)
	_, e2 := mem.alloc(65536, 8, al)
	_, e3 := mem.alloc(200000, 8, al)
	fmt.println("dynamic arena sizes 8000/65536/200000:", e1, e2, e3)
}

@(test)
pool_behaviour :: proc(t: ^testing.T) {
	region: [256]byte
	p: Pool
	pool_init(&p, region[:], 32)
	al := pool_allocator(&p)
	a, _ := mem.alloc(24, 8, al)
	(cast(^int)a)^ = 7
	testing.expect_value(t, mem.free(a, al), mem.Allocator_Error.None)
	b, _ := mem.alloc(24, 8, al)
	testing.expect(t, a == b, "same chunk back")
	testing.expect_value(t, (cast(^int)b)^, 0)
	_, err := mem.alloc(64, 8, al)
	testing.expect_value(t, err, mem.Allocator_Error.Invalid_Argument)
	for _ in 0 ..< 7 {
		_, _ = mem.alloc(24, 8, al)
	}
	_, err2 := mem.alloc(24, 8, al)
	testing.expect_value(t, err2, mem.Allocator_Error.Out_Of_Memory)
}

@(test)
frame_arenas :: proc(t: ^testing.T) {
	f: Frame_Arenas
	testing.expect_value(t, frames_init(&f, 1 << 20), nil)
	defer vmem.arena_destroy(&f.arenas[0])
	defer vmem.arena_destroy(&f.arenas[1])
	prev, _ := mem.alloc(8, 8, frames_allocator(&f))
	(cast(^int)prev)^ = 42
	frames_next(&f)
	cur, _ := mem.alloc(8, 8, frames_allocator(&f))
	(cast(^int)cur)^ = 43
	testing.expect_value(t, (cast(^int)prev)^, 42)
	frames_next(&f)
	again, _ := mem.alloc(8, 8, frames_allocator(&f))
	testing.expect_value(t, (cast(^int)again)^, 0)
	testing.expect_value(t, (cast(^int)cur)^, 43)
}

@(test)
leak_report_demo :: proc(t: ^testing.T) {
	p := new(int)
	_ = p
}
