# Odin and the C ABI

Verified on Odin dev-2026-10 (`dev-2026-10-nightly:84bc3fc`) on darwin_arm64 with Apple clang 21. Code blocks compile with `-vet -vet-cast -strict-style` and were linked against a real C library built from the prototypes below. Tags: `[run]` ran with the stated result, `[src]` read from core source only, `[unverified]` not run. Linux and Windows branches were not run.

## Stance
- Bind the smallest surface the program needs, by hand. A generator exists (`odin-c-bindgen`) but was not run for this skill `[unverified]`.
- Cross the boundary with flat data: plain structs, and arrays as pointer plus count. No Odin allocator, `string`, `[dynamic]` or `map` crosses it.
- Whoever allocates, frees. Name wrapper procedures in pairs (`make_x`, `free_x`) so the owner is visible in the call.
- Do not let C code pick the memory strategy by accident. C that returns heap memory hands you one allocation per call. Prefer an API that fills a buffer you own (an arena slice or a fixed array), as `fill` below does.

## The C side used for the examples
```c
typedef struct { float x, y; } Vec2;
typedef struct { uint8_t tag; int32_t id; double w; } Rec;
typedef enum { MODE_A = 1, MODE_B = 4 } Mode;
typedef int (*visit_fn)(void *user, int v);
int sum_i32(const int32_t *xs, size_t n);
Vec2 vec_add(Vec2 a, Vec2 b);
size_t rec_size(void);
int visit(const int32_t *xs, size_t n, visit_fn f, void *user);
char *make_name(int n);
void free_name(char *p);
int32_t *make_table(size_t n);
void fill(int32_t *out, size_t n, Mode m);
unsigned flags_echo(unsigned f);
```

## Importing and declaring
```odin
foreign import lib "liblib.a"

when ODIN_OS == .Darwin {
	foreign import libc "system:System"
} else {
	foreign import libc "system:c"
}

@(default_calling_convention = "c")
foreign lib {
	sum_i32 :: proc(xs: [^]c.int32_t, n: c.size_t) -> c.int ---
	vec_add :: proc(a, b: Vec2) -> Vec2 ---
	rec_size :: proc() -> c.size_t ---
	visit :: proc(xs: [^]c.int32_t, n: c.size_t, f: Visit_Fn, user: rawptr) -> c.int ---
	make_name :: proc(n: c.int) -> cstring ---
	free_name :: proc(p: cstring) ---
	make_table :: proc(n: c.size_t) -> [^]c.int32_t ---
	fill :: proc(out: [^]c.int32_t, n: c.size_t, m: Mode) ---
	flags_echo :: proc(f: Flags) -> Flags ---
}

@(default_calling_convention = "c")
foreign libc {
	strlen :: proc(s: cstring) -> c.size_t ---
	@(link_name = "free")
	c_free :: proc(p: rawptr) ---
}
```
- A relative path in `foreign import` finds a static library next to the build `[run]`. `system:System` links libc on macOS `[run]`. The `system:c` branch is what core's own runtime uses on other Unix targets `[src: base/runtime/heap_allocator_unix.odin]`.
- `@(default_calling_convention = "c")` makes every procedure in the block C. Add `link_name = "x"` to bind a C symbol under another Odin name, or `link_prefix = "vec_"` on the block to drop a shared prefix: `add :: proc(a, b: [2]c.float) -> [2]c.float ---` called `vec_add` `[run]`.
- Procedures in a foreign block end with `---` and have no body.

## C types
| C | Odin | Size on darwin_arm64 |
|---|---|---|
| `int`, `unsigned` | `c.int`, `c.uint` (`i32`, `u32`) | 4 |
| `long` | `c.long` (`i64` here) | 8, differs by platform |
| `long long` | `c.longlong` | 8 |
| `size_t` | `c.size_t` (`uint`) | 8 |
| `char` | `c.char` | 1 |
| `_Bool` | `c.bool` | 1 |
| `float`, `double` | `c.float`, `c.double` | 4, 8 |
| `const char *` | `cstring` | 8 |
| `T *` (one) | `^T` | 8 |
| `T *` (array) | `[^]T` | 8 |
| `void *` | `rawptr` | 8 |
- Sizes are `[run]`. Use the `c.*` names in foreign declarations so a different platform picks its own width. Use plain `i32` and `f32` for your own data.
- A string literal converts to `cstring` implicitly. A `string` variable does not: "Cannot assign value 's' of type 'string' to 'cstring'" `[run]`.

## Structs and layout
```odin
Vec2 :: struct {
	x, y: c.float,
}

Rec :: struct {
	tag: c.uint8_t,
	id:  c.int32_t,
	w:   c.double,
}
#assert(size_of(Rec) == 16)
#assert(offset_of(Rec, id) == 4)
#assert(offset_of(Rec, w) == 8)

Mode :: enum c.int {
	A = 1,
	B = 4,
}

Flag :: enum c.uint {
	Read  = 0,
	Write = 1,
	Exec  = 2,
	Extra = 3,
}
Flags :: bit_set[Flag;c.uint]

Visit_Fn :: #type proc "c" (user: rawptr, v: c.int32_t) -> c.int
```
- Fields keep declaration order and C alignment. `Rec` was 16 bytes with `id` at 4 and `w` at 8 in Odin and in C, checked by calling `rec_size` and the offset helpers `[run]`.
- Pin every foreign struct with `#assert` on size and offsets. A mismatch becomes a compile error.
- `struct #packed` matched `#pragma pack(1)` (5 bytes) and `struct #raw_union` matched a C union (4 bytes) `[run]`.
- `struct #align(16)` aligns the whole struct, not a field. C `_Alignas(16) int32_t b` after a `uint8_t` is size 32, offset 16. Odin `#align(16)` on the outer struct gave size 16, offset 4. Wrap the field instead: `W :: struct #align(16) {v: i32}` gave size 32, offset 16 `[run]`. A field-level `#align` is a syntax error `[run]`.
- A small vector can be `[2]c.float` for `Vec2`: passed and returned by value with the same result `[run]`. Structs of two floats by value also worked `[run]`.
- `Mode` and `Flags` pass by value. `flags_echo({.Read, .Write})` returned `{Read, Write, Extra}`, so the `bit_set` carries the C integer unchanged `[run]`.

## Calling C
```odin
use_c :: proc() {
	xs := []i32{1, 2, 3, 4}
	_ = sum_i32(raw_data(xs), c.size_t(len(xs)))
	_ = vec_add({1, 2}, {3, 4})

	buf := make([]i32, 3, context.temp_allocator)
	fill(raw_data(buf), c.size_t(len(buf)), .B)

	name := make_name(7)
	defer free_name(name)
	_ = string(name)

	tbl := make_table(5)
	defer c_free(tbl)
	_ = tbl[:5]

	cs := strings.clone_to_cstring("hello", context.temp_allocator)
	_ = strlen(cs)
}
```
- `sum_i32` returned 10 and `vec_add` returned `{4, 6}` `[run]`. `fill` wrote `[4, 4, 4]` into an Odin-owned buffer `[run]`.
- `raw_data(xs)` plus `c.size_t(len(xs))` is the standard way to pass a slice. Slices are not valid C types.
- `string(name)` is a view of C memory, valid until `free_name`. `tbl[:5]` turns a returned `[^]T` into a slice without copying `[run]`.
- Free what C allocated with C's free: `free_name(name)` and `c_free(tbl)` ran clean `[run]`. Do not `delete` it with an Odin allocator. On Unix the default heap is libc, so it can look like it works `[src]`, but another platform or a custom `context.allocator` breaks it `[unverified]`.
- Memory C only reads or fills can come from any Odin allocator. Prefer a frame arena or a fixed array over a `make` per call.
- Struct-of-arrays fits C well. Pass each column as pointer plus count and keep the columns in one arena.

## Callbacks
```odin
Callback_State :: struct {
	calls: int,
	ctx:   runtime.Context,
}

on_visit :: proc "c" (user: rawptr, v: c.int32_t) -> c.int {
	st := cast(^Callback_State)user
	context = st.ctx
	st.calls += 1
	return c.int(v) * 2
}

run_visit :: proc(xs: []i32) -> int {
	st := Callback_State {
		ctx = context,
	}
	_ = visit(raw_data(xs), c.size_t(len(xs)), on_visit, &st)
	return st.calls
}
```
- A `proc "c"` has no `context`. Using `fmt` or an allocator in it is an error until `context` is assigned `[run]`.
- `context = runtime.default_context()` works but resets `context.allocator` to the default heap `[run]`. Pass the caller's `context` through the user-data pointer instead, as above. `visit` called back four times and returned 20 `[run]`.
- The user-data pointer must outlive the call. Taking `&st` of a local is fine when C does not keep it.
- A callback registered with C and called later needs state that lives that long. Allocate it from the lifetime's arena, not per registration.

## Exporting Odin to C
```odin
Counter :: struct {
	count: c.int,
}

@(export, link_name = "r5_add")
add :: proc "c" (a, b: c.int) -> c.int {
	return a + b
}

@(export, link_name = "r5_counter_new")
counter_new :: proc "c" () -> ^Counter {
	context = runtime.default_context()
	return new(Counter)
}

@(export, link_name = "r5_counter_bump")
counter_bump :: proc "c" (ctr: ^Counter) -> c.int {
	ctr.count += 1
	return ctr.count
}

@(export, link_name = "r5_counter_free")
counter_free :: proc "c" (ctr: ^Counter) {
	context = runtime.default_context()
	free(ctr)
}
```
```
odin build pkg -build-mode:static -out:libapi.a -vet -strict-style
odin build pkg -build-mode:shared -out:libapi.dylib
```
- Both builds succeeded, and `nm -g libapi.a` listed `_r5_add`, `_r5_counter_new`, `_r5_counter_bump` and `_r5_counter_free` `[run]`.
- A C program with hand-written prototypes, compiled as `clang main.c libapi.a`, printed `5 2` and exited 0 `[run]`. The static library linked without extra runtime flags for this small case. Larger programs that use `fmt`, threads or `core:os` may need more `[unverified]`.
- Name the C symbols with `link_name` and a library prefix. Odin package names do not become symbol prefixes.
- Export an opaque handle and keep the layout private. Call `context = runtime.default_context()` in every exported procedure that allocates or prints.
- The handle above is one long-lived allocation, the named exception to "no default heap". For many objects per handle, store them in arrays inside the handle and let `counter_free` release one arena.
- Write the C header by hand and compile a C caller in a test. Header generation from Odin was not checked `[unverified]`.
- Only a C caller was run. Other languages bind the same symbols through their own C FFI `[unverified]`.

## odx projects
- `transmute` and `#no_bounds_check` are banned. Reinterpret with `cast` or restructure the data. An ignore needs the user's approval.
- C-ABI names must be snake_case, Ada_Case or SCREAMING_CASE. Keep the C symbol with `link_name` and rename the Odin field or procedure.
- odx checks only darwin_arm64 and linux_amd64. Windows-only foreign code is not checked.

## Checks before claiming a binding works
- `#assert` on every foreign struct size and offset, and one C-side `sizeof` helper compared at run time for new structs.
- Link and call each foreign procedure once from a test.
- `odin check` does not verify that a symbol exists. A wrong `link_name` fails at link time.
