# C patterns and their Odin replacements

Verified on Odin dev-2026-10 (`dev-2026-10-nightly:84bc3fc`). Code blocks compile with `-vet -vet-cast -strict-style`. Tags: `[run]` ran and printed the stated result, `[src]` read from core source only.

## Stance: data first, allocation per lifetime
- Design the data before the code. Plain structs in contiguous arrays, one array per kind of thing. Related things refer to each other by index or handle, not by pointer.
- Know the count, lifetime and owner of every allocation before writing it. Choose the allocator from that (`allocators.md`).
- Per-object `new` and `make` are fine when the allocator is passed in and suits the lifetime. The allocator is the last or second-to-last argument: `new(T, a)`, `make([]T, n, a)`, `strings.clone(s, a)`. `append` and map inserts use the allocator stored in the container when it was made `[run]`. Put the allocator in a procedure's signature as `allocator := context.allocator` and pass it down.
- The trap is omitting it. Without an argument, `new`, `make`, `append`, `strings.clone` and `fmt.aprintf` draw from `context.allocator`, whose default is libc `calloc`, `realloc` and `free` on Unix `[src: base/runtime/heap_allocator_unix.odin]`. `context.allocator.procedure == runtime.default_allocator_proc` is true in a fresh program `[run]`. That is `malloc` per object by accident.
- `context.allocator = a` at the top of a scope redirects every omitted argument below it. `runtime.default_context()` ignores that and returns the default heap `[run]`.
- Use the default heap on purpose: few, large, long-lived allocations such as startup config or a loaded asset. Say so by name.
- Smells to flag in review: `new`, `make` or `free` with no allocator argument inside a loop, a struct that holds pointers to sibling structs, `[dynamic]^T`, a hand-built linked list, a per-frame allocation with no arena, `context.allocator` handed to a short-lived helper.
- Measured cost of per-node heap allocation versus arena and pool: see "Measuring" in `allocators.md` (heap 24.2 ms, arena 13.1 ms, pool 10.6 ms for 1M nodes on one machine).

## Arrays of plain data
```odin
Particle :: struct {
	pos, vel: [2]f32,
	life:     f32,
}

Particles :: struct {
	pos, vel: [dynamic][2]f32,
	life:     [dynamic]f32,
}

step :: proc(ps: ^Particles) {
	for i in 0 ..< len(ps.pos) {
		ps.pos[i] += ps.vel[i]
	}
}

step_soa :: proc(soa: ^#soa[dynamic]Particle) {
	for &p in soa {
		p.pos.x += 1
	}
}
```
- `Particles` is hand-written struct-of-arrays. `#soa[dynamic]Particle` gives the same layout with array-of-structs syntax and `append_soa` `[run]`.
- Pick SoA when a loop touches one or two fields of many items. Keep one struct when every field is used together.
- Reserve once (`reserve(&ps.pos, n)`) when the count is known.

## Indices and handles instead of pointers
```odin
Node :: struct {
	value: int,
	next:  int,
}

Handle :: struct {
	index, gen: u32,
}

Slot :: struct {
	gen:  u32,
	live: bool,
	item: int,
}

slots_alloc :: proc(slots: ^[dynamic]Slot, item: int) -> Handle {
	for &s, i in slots {
		if !s.live {
			s.live = true
			s.item = item
			return {u32(i), s.gen}
		}
	}
	append(slots, Slot{live = true, item = item})
	return {u32(len(slots) - 1), 0}
}

slots_free :: proc(slots: []Slot, h: Handle) {
	s := &slots[h.index]
	if s.live && s.gen == h.gen {
		s.live = false
		s.gen += 1
	}
}

slots_get :: proc(slots: []Slot, h: Handle) -> (item: int, ok: bool) {
	s := slots[h.index]
	if !s.live || s.gen != h.gen {
		return
	}
	return s.item, true
}
```
- `Node.next` is an index into a `[]Node`, so the list survives growth and moves. A pointer into a `[dynamic]` went stale after 1000 appends `[run]`.
- A freed slot is reused and its `gen` is bumped, so an old `Handle` is rejected `[run]` (stale lookup returned `false`, the new handle returned the new item).
- Scan for a free slot is O(n). Keep a free-list index when it matters.

## One arena per lifetime
```odin
frame :: proc() -> int {
	buf: [1024]byte
	arena: mem.Arena
	mem.arena_init(&arena, buf[:])
	a := mem.arena_allocator(&arena)
	nodes := make([dynamic]Node, 0, 16, a)
	append(&nodes, Node{1, -1})
	append(&nodes, Node{2, 0})
	return len(nodes)
}
```
- No `delete` is needed. The arena memory ends with the buffer. Reset an arena per frame or request instead of freeing items. More kinds in `allocators.md`.

## Mapping table
| C pattern | Usual C alternative | Drawback | Odin replacement |
|---|---|---|---|
| `malloc`/`free` per object | arena or pool library | scattered lifetimes, leaks | allocator per lifetime, `defer` |
| `goto cleanup` | `__attribute__((cleanup))` | non-standard | `defer` |
| NUL-terminated `char*` | length-prefixed strings | O(n) length, embedded NUL | `string`; `cstring` only at the FFI edge |
| pointer plus length | `struct {T *p; size_t n;}` | unchecked, drifts apart | `[]T`; `[^]T` for C pointers |
| `void*` | macros, `_Generic` | no type check | `union`, `$T` parameters, `rawptr` at boundaries |
| `errno`, out-params | return codes | easy to ignore | multiple returns, `or_return` |
| `#define FLAG` | enum plus masks | untyped integers | `bit_set` |
| macros, `#ifdef` | inline functions | textual, global | constants, `when`, `#config` |
| headers | include guards | order, duplicates | packages |
| uninitialized memory | `calloc`, `memset` | garbage reads | zero by default, `---` to opt out |

## malloc/free to allocator plus defer
```odin
Err :: enum {
	None,
	Empty,
	Too_Big,
}

LIMIT :: #config(LIMIT, 8)

build :: proc(n: int, allocator := context.allocator) -> (a, b: []int, err: Err) {
	a = make([]int, n, allocator)
	defer if err != nil {
		delete(a, allocator)
	}
	b = make([]int, n * 2, allocator)
	defer if err != nil {
		delete(b, allocator)
	}
	if n > LIMIT {
		err = .Too_Big
		return
	}
	return
}
```
- This replaces `goto fail` cleanup. A deferred statement that checks `err` frees on failure and keeps the result on success. On failure the returned slices are freed but not nil, so the caller must ignore them; assigning `a = nil` inside the defer does not reach the caller `[run]`. Set `err`, then a bare `return`. `return nil, nil, .Too_Big` overwrites `a` and `b` before the defers run, and both leaked `[run]`.
- With a tracking allocator, `build(100)` freed everything and `build(2)` left only the caller's two slices `[run]`.

## Strings
```odin
view :: proc(cs: cstring) -> string {
	return string(cs)
}

copy_of :: proc(cs: cstring, allocator := context.allocator) -> string {
	return strings.clone_from_cstring(cs, allocator)
}

to_c :: proc(s: string) -> cstring {
	return strings.clone_to_cstring(s, context.temp_allocator)
}
```
- `string(cs)` is a zero-copy view. It is valid as long as the C memory is. `clone_from_cstring` copies. `len(cs)` scans for the NUL: a buffer `abc\0z\0` gave 3 `[run]`.
- A `string` is not NUL-terminated. Convert with `clone_to_cstring` at the call into C, and free the clone or use the temp allocator.

## Slices, void*, errors
- Pointer plus length is `[]T`, bounds-checked. `raw_data(xs)` plus `len(xs)` goes to C, and `p[:n]` on a `[^]T` returns a slice without copying `[run]`.
- `void*` becomes a `union` with a type switch for a closed set, `$T` parameters for one algorithm over many types, and `rawptr` only for user data and C callbacks, converted with `cast(^T)`. Syntax in `syntax.md`.
- `errno` and out-params become a last error return and `or_return`. `build(100)` returned `.Too_Big` and `build(2)` returned `.None` `[run]`. Syntax in `syntax.md`.

## Flags
```odin
Flag :: enum c.uint {
	Read  = 0,
	Write = 1,
	Exec  = 2,
}
Flags :: bit_set[Flag;c.uint]
```
- `{.Read, .Write}`, `.Write in f`, `card(f)`. `size_of(Flags)` is 4 `[run]`.
- `cast(c.uint)f` is an error ("Cannot cast"). Pass the `bit_set` straight to a C procedure that takes the integer; see `ffi.md`.

## Macros and #ifdef
- `LIMIT :: #config(LIMIT, 8)` (declared in the `build` example) is overridden with `-define:LIMIT=2`. With 2, `build(4)` returned `.Too_Big` `[run]`.
- `when ODIN_OS == .Darwin {} else {}` selects code at compile time. Declarations are order-independent at package scope, so no forward declarations.

## Uninitialized memory
```odin
scratch :: proc() -> int {
	buf: [8]byte = ---
	buf = {}
	return len(buf)
}
```
- Variables are zeroed. `= ---` skips zeroing and leaves garbage. Use it only when the next statement overwrites all of it.

## Known gaps
- Not covered here: `setjmp`/`longjmp`, variadic C APIs beyond `#c_vararg`, VLAs, inline assembly. Check each against the compiler before claiming anything.
