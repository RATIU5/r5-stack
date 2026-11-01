# Allocators

Examples were checked with Odin dev-2026-10. Statements marked (unconfirmed) were read from `core/mem`, `core/mem/virtual` or `base/runtime` source and not run. Everything else was observed by running it. If in doubt, run a quick check on your machine and compiler. Names are `mem.*` (`core:mem`), `vmem.*` (`core:mem/virtual`).

## Rules
- Do not default every allocation to `context.allocator`. Pick the allocator from the lifetime and size behavior of the data, then pass it explicitly.
- Libraries take `allocator := context.allocator` and use it for everything they own. Applications choose and pass allocators.
- Put `#+vet explicit-allocators` at the top of files that must never use the implicit one. `make([]int, 4)` then fails: "Parameter 'allocator' ... must be explicitly provided".
- Free what you allocate with the same allocator. Arenas free in bulk, so skip per-item `delete` on them.
- Any performance claim needs a measurement with `core:time` or a benchmark, on the real build flags. See Measuring.
- Zero-initialization is the default: `make`, `new` and the arenas zero memory. `mem.alloc_bytes_non_zeroed` does not (first byte 170 from a dirty buffer vs 0).

## Complexity ladder (try the top rung first)
1. Static: size known at compile time, lives for the whole program. A global `table: Table` or `[N]T` array, zeroed by default. No allocator, no free.
2. Fixed capacity: allocate the worst case once, up front (arena over a buffer or reserved pages). Pointers stay stable because nothing moves.
3. Pages from the OS: `vmem.reserve` a large virtual range, `commit` as you grow, `release` at the end. Demand paging means untouched pages cost no physical RAM. `vmem.arena_init_static` wraps this.
4. Linear (bump) allocation with bulk reset: arena, scratch, frame arena. Data of one lifetime is packed in a line and dies together.
5. Fixed-size slots: pool or free list when objects of one size are created and destroyed at random.
6. General heap (`context.allocator`): only for unpredictable sizes with independent lifetimes.
Resizable arrays that `realloc` move data and break pointers. Prefer fixed capacity plus a `count`. To delete without compaction, mark the slot dead (a flag or a free-list link) and reuse it, or treat an edit as add plus delete.

## Decision table
| Data | Allocator |
|---|---|
| Global tables, config, size known at compile time | static array |
| Everything from one load, level or request, freed together | `vmem.Arena` growing, or `mem.Arena` over a buffer |
| Per-frame or per-tick scratch | frame arena (two `vmem.Arena`, flip each frame) or `context.temp_allocator` |
| Short temporaries inside one call tree | `context.temp_allocator` with a temp guard |
| Nested lifetimes, strict LIFO | `mem.Stack` or `mem.Small_Stack` |
| Many same-size objects, random create/destroy | pool (custom, below) |
| Mixed sizes, individual frees, want low fragmentation | `mem.Buddy_Allocator` or `tlsf.Allocator` |
| Individual frees mostly in order, bulk rollback | `mem.Rollback_Stack` |
| Unknown growth, no fixed bound, one lifetime | `vmem.Arena` growing or `mem.Dynamic_Arena` |
| Shared between threads | wrap with `mem.Mutex_Allocator`, or one arena per thread |
| Hunting leaks and bad frees | `mem.Tracking_Allocator` over the real one |
| Must never allocate here | `mem.panic_allocator()` |
| Unknown, small program | `context.allocator` (libc heap) |

## Catalog
Columns per entry: pattern, lifetime and reset, fragmentation, cost, threads, alignment and zeroing, failure modes, pros and cons, choose when.

### mem.Arena
Fixed buffer you own: `mem.arena_init(&a, buf[:])`, `mem.arena_allocator(&a)`. Bump only; `free(p, a)` returns `Mode_Not_Implemented`, reclaim with `mem.arena_free_all`. None internally, O(1) alloc, no per-allocation header. Not thread safe (unconfirmed). Zeroes on `Alloc`; padding counts toward the offset. Returns `Out_Of_Memory` when full; resize copies to new space and wastes the old block. Pro: simplest, cheapest, stable pointers. Con: fixed size, no early free. Choose for bounded per-task data on the stack or a static buffer.

### vmem.Arena (growing, static, buffer kinds)
`vmem.arena_init_growing`, `arena_init_static(&a, reserved, commit_size)`, `arena_init_buffer`; destroy with `vmem.arena_destroy`. Bump over reserved pages; static reserves one range (default 1 GiB) and commits lazily (unconfirmed); growing chains blocks (1 MiB minimum). Reset with `vmem.arena_free_all`, `arena_static_reset_to`, or scope with `vmem.arena_temp_begin` and `arena_temp_end`. Locked with a mutex on allocation (unconfirmed), so it is safe to share but pays for the lock; `arena_alloc_unguarded` skips it. Memory comes zeroed from the OS and is zeroed again on reset. The buffer kind does not zero your buffer: allocations from a dirty buffer come back dirty (first byte 170). Errors from reserve or commit propagate; the Linux and Darwin paths differ on odd errno values (unconfirmed). Pro: huge address space, stable pointers, no copying. Con: page-granular; reset cost grows with used bytes. Choose as the default arena for level, request and frame data.

### mem.Scratch
`mem.scratch_init(&s, size, backing)`, `scratch_destroy`. Ring-style bump with a backing buffer from the backup allocator. A request that does not fit wraps to offset 0 and silently invalidates earlier allocations; requests larger than the whole buffer go to the backup allocator and are tracked as leaks. Only the latest allocation can be rolled back; freeing others is a no-op (unconfirmed). Not thread safe (unconfirmed). Pro: never fails for small scratch use. Con: silent invalidation; only safe when old results are dead by the next wrap. Choose for rotating temporary buffers, with a size bound you know.

### mem.Stack and mem.Small_Stack
`mem.stack_init(&s, buf[:])` and `small_stack_init`. LIFO. `Stack` frees only the latest allocation; freeing an earlier one returns `Invalid_Pointer`. `Small_Stack` frees any interior pointer and discards everything after it (offset returned to 0 after freeing the first of two); max alignment 128 and one-byte headers (unconfirmed). Stack has a 16-byte header per allocation. No fragmentation, O(1). Not thread safe (unconfirmed). Pro: cheap nested lifetimes. Con: must free in order; small stack never grows in place (unconfirmed). Choose for call-tree-shaped lifetimes.

### mem.Dynamic_Arena
`mem.dynamic_arena_init(&a, block_allocator, array_allocator)`, `dynamic_arena_destroy`, `dynamic_arena_reset`, `dynamic_arena_free_all`. Fixed-size blocks (default 64 KiB) from a backing allocator. Requests of 8000, 65536 and 200000 bytes all succeeded. `free` returns `Mode_Not_Implemented`. Reset keeps unused blocks for reuse (unconfirmed). Tail of a block is abandoned when a request does not fit (unconfirmed). Not thread safe (unconfirmed). Pro: grows without a virtual-memory setup. Con: slack at block ends. Choose when you want growth but not `core:mem/virtual`.

### mem.Buddy_Allocator
`mem.buddy_allocator_init(&b, buf, alignment)`. Power-of-two blocks split and coalesce; the buffer length must be a power of two and the buffer aligned to at least 16, otherwise a runtime assertion fires. Frees coalesce; double free is accepted silently. Internal fragmentation up to a factor of two; low external fragmentation. Alignment is fixed at init (per-call alignment ignored on `Alloc`) (unconfirmed). Not thread safe (unconfirmed). Choose for mixed sizes with individual frees in a fixed arena where predictable fragmentation matters.

### mem.Rollback_Stack
`mem.rollback_stack_init_buffered(&s, buf[:])` or `rollback_stack_init_dynamic`. Stack with out-of-order frees: freeing the last allocation rolls back through freed ones; a double free returns `Invalid_Pointer`. 8-byte header per allocation (unconfirmed). Not thread safe (unconfirmed). Choose when frees are mostly ordered but not guaranteed.

### tlsf.Allocator (core:mem/tlsf)
General-purpose two-level segregated fit over a buffer or growing pools: O(1) alloc and free, 8-byte header per block, bounded fragmentation (unconfirmed). Free merges neighbors; a double free asserts (unconfirmed). No lock (unconfirmed). Choose for a real-time general allocator with individual frees.

### mem.Tracking_Allocator
Wraps another allocator and records every live allocation. `mem.tracking_allocator_init(&t, context.allocator)`, `mem.tracking_allocator(&t)`, `tracking_allocator_destroy`. Entries are in `t.allocation_map` (live) and `t.bad_free_array` when `t.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array`; a double free then yields 1 bad-free entry. The default callback panics (unconfirmed). Mutex protected (unconfirmed). One map entry per live allocation, so use it in debug builds only.

### mem.Mutex_Allocator
`mem.mutex_allocator_init(&m, backing)`, `mem.mutex_allocator(&m)`. Serializes every call on one mutex over any backing allocator (unconfirmed); compiles and runs. Choose to share a single-threaded arena across threads when contention is low.

### mem.panic_allocator and mem.nil_allocator
`mem.panic_allocator()` panics on any allocation or free: assert that a region never allocates. `mem.nil_allocator()` returns an empty result with no error; `runtime.nil_allocator` instead returns `Out_Of_Memory` (unconfirmed).

### Default heap and temp allocator (base:runtime)
`context.allocator` is the libc-backed heap by default: individual frees, resize in place or by move, over-allocates for alignment (unconfirmed). Costs a call into libc each time. `context.temp_allocator` is a thread-local arena, 4 MiB default (`runtime.DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE` prints 4194304), reset with `free_all(context.temp_allocator)`.
```odin
guard := runtime.default_temp_allocator_temp_begin()
buf := make([]byte, 1024, context.temp_allocator)
fmt.println(len(buf))
runtime.default_temp_allocator_temp_end(guard)
free_all(context.temp_allocator)
```
Scope temp use with begin and end, or call `free_all` at a known point (end of frame, end of request). Never store a temp pointer past that point. A library must not call `free_all(context.temp_allocator)` for its caller.

## Custom allocators
An allocator is `mem.Allocator{procedure, data}`. Implement `.Alloc`, `.Free`, `.Free_All`, `.Query_Features`; return `.Mode_Not_Implemented` for modes you do not support. `.Alloc` must be implemented.
### Pool for fixed-size objects
```odin
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
```
Behavior: freeing then allocating returns the same chunk, zeroed; an oversize request returns `Invalid_Argument`. Zero fragmentation, O(1) alloc and free. Pointers into `region` stay stable. For a single type, skip the allocator interface: keep `[N]T` plus a free list of indices.
### Frame arenas
```odin
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
```
Data from the previous frame stays valid for one more frame. Free-list allocators (variable size) follow the same shape as the pool with a size in each header; prefer `tlsf.Allocator` before writing one.

## Tracking allocator in debug builds
```odin
when ODIN_DEBUG {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)
	defer for _, e in track.allocation_map {
		fmt.eprintln("leak", e.size, e.location)
	}
}
```
`odin test` does this for you: inside a test `context.allocator` is the runner's tracking allocator, not the default heap. It prints `+++ leak 8B @ ... [file:line:proc]` but exits 0; read the output.

## Measuring
1M nodes of 32 bytes, best of 5, `-o:speed`: heap `new`/`free` 24.2 ms, `vmem.Arena` static 13.1 ms, pool 10.6 ms. These are one machine's numbers. The arena figure includes arena setup and first-touch page faults; the pool used a preallocated region. Treat as order of magnitude. Measure your own workload:
```odin
t := time.tick_now()
work()
fmt.println(time.duration_milliseconds(time.tick_since(t)), "ms")
```
Run in a release build, repeat, take the best, and print a checksum so the work is not optimized away.

## Passing allocators
- Take it as a trailing parameter: `proc(..., allocator := context.allocator)`; pass it to every `make`, `new`, `append` (via the container's allocator) and `delete` call inside.
- Store the allocator in the struct that owns the memory, or use a field of the dynamic array. Never free with a different allocator than allocated.
- Scope a swap with `context.allocator = a` inside a block; it is restored at scope exit.

## odx projects
- `transmute` and `#no_bounds_check` are banned: prefer `cast` or restructure. An `odx:ignore` needs the user's approval.
- C-ABI names must be snake_case, Ada_Case or SCREAMING_CASE; use `link_name` for symbols and rename fields.
- odx checks darwin_arm64 and linux_amd64 only.
