# Odin syntax and idioms

Examples were checked with Odin dev-2026-10 using `odin check -vet -vet-cast -strict-style`, `odin run` and `odin test`. Statements marked (error) are compiler messages seen there. If in doubt, run a quick check on your compiler.

## Declarations
```odin
x := 1
y: int = 2
z: int
MAX :: 10
add :: proc(a, b: int) -> int {return a + b}
```
- `:=` declares and infers, `: T` zero-initializes, `::` is a constant or type or proc.
- Procs need `->` for results: `proc() int {` is a syntax error.
- No implicit numeric conversion: `int + f32` is "Mismatched types". Use `f32(a)` or `cast(f32)a`. `x: bool = 1` is an error.

## Types
```odin
Vec2 :: struct {x, y: f32}
Shape :: union {Circle, Rect}
Kind :: enum u8 {A = 1, B = 4, C}
Flags :: bit_set[Kind]
Meters :: distinct f32
Pair :: struct($K, $V: typeid) {k: K, v: V}
Handler :: #type proc(x: int) -> int
```
- `[N]T` array, `[]T` slice, `[dynamic]T`, `map[K]V`, `[^]T` multi-pointer, `^T` pointer, `p^` deref, `&x` address.
- Instantiate generics with `Pair(int, string){1, "a"}`. `Maybe(int)` unwraps with `v, ok := mb.?`.
- `[Dir]string{.N = "n", .S = "s"}` is an enum-indexed array when `Dir :: enum {N, S}` is contiguous. A gapped enum such as `Kind` above is an error unless written `#partial #sparse[Kind]string{.A = "a", .B = "b"}`.
- Struct field access through a pointer is `p.x`. There is no `->`.
- `bit_set` backed by an integer array, such as `bit_set[0 ..< 16; [2]u8]`, needs dev-2026-10. It is an error on dev-2026-09.
- `x: #soa[dynamic]Particle` with `append_soa(&ps, p)` stores struct-of-arrays.

## Control flow
```odin
for i in 0 ..< 3 {}
for i in 0 ..= 3 {}
for x, i in xs {}
for &x in xs {
	x *= 2
}
#reverse for x in xs {}
for cond {}
for {}
for j := 0; j < 2; j += 1 {}
if v, ok := m["a"]; ok {}
switch n {
case 3, 4:
case:
}
#partial switch kind {
case .B:
}
switch s in shape {
case Circle:
case Rect:
}
```
- One loop keyword: `for`. `while`, `i++`, `elif` are errors. `else if` is fine.
- Cases do not fall through. `case 3, 4:` shares code. `fallthrough` exists, but odx projects ban it. `case:` is default.
- `switch x in union_value` is a type switch. Do not use it on an enum.
- `defer` runs at the end of the enclosing scope, including a loop body, not the function.
- Ternary forms both work: `a if cond else b` and `cond ? a : b`.

## Errors
```odin
run :: proc() -> (total: int, err: Err) {
	a := step(1) or_return
	b := step(a) or_return
	return a + b, nil
}
n := parse("12") or_else -1
v := parse(s) or_continue
find :: proc(xs: []int, want: int) -> (index: int, found: bool) #optional_ok {
	for x, i in xs {
		if x == want {
			return i, true
		}
	}
	return
}
```
- Errors are values returned last. `or_return` propagates a non-nil/false last value, `or_else` supplies a default, `or_continue` and `or_break` act inside loops. There are no exceptions.
- `v, ok := x.(T)` and `v, ok := m[k]` use the comma-ok form.

## Memory and strings
```odin
xs := make([dynamic]int, context.allocator)
defer delete(xs)
append(&xs, 1, 2, 3)
p := new(Point)
defer free(p)
s := strings.clone("hi")
defer delete(s)
```
- `append` takes a pointer to the array. `delete` frees slices, strings, dynamic arrays, maps. `free` frees `new` results.
- A `string` is pointer plus length. `s[0]` is a `u8`, not a string (error if assigned to `string`).
- `cap` on a slice is an error (only dynamic arrays have capacity).
- `fmt` widths zero-pad by default: `%6d` prints `000042`, `%5.2f` of 3.14159 prints `03.14`. `%-6d` left-aligns with spaces.
- `make(map[string]int, context.allocator)` and `make(map[string]int, 16, context.allocator)` both compile.
- Use `strings.Builder` with `builder_init`, `write_string`, `write_int`, `to_string`, `builder_destroy`.
- Multi-line strings: backtick-delimited text spans lines. The triple-backtick form added in dev-2026-09 trims the leading and trailing newline.

## Calls and attributes
```odin
scale({1, 2, 3}, k = 3)
callback :: proc "c" (n: i32) -> i32 {
	context = runtime.default_context()
	return n
}
@(test)
add_works :: proc(t: ^testing.T) {testing.expect_value(t, 1 + 1, 2)}
```
- Default and named arguments exist. `proc "c"` has no `context`. Calling `fmt.println` in it is an error ("'context' has not been defined"); assign `context = runtime.default_context()` first.
- File tags: `#+vet explicit-allocators`, `#+build`. Conditional code: `when ODIN_OS == .Darwin {} else {}`.
- Array programming: `[3]f32 * f32` scales every element.

## Operators
- `~` is XOR (binary) and bitwise not (unary). `&~` is and-not. `%` is remainder (sign of dividend), `%%` is modulo.
- `'ab'` is an invalid rune literal.

## Constructs other languages emit that fail here
| Wrong | Odin | Evidence |
|---|---|---|
| `i++` | `i += 1` | Postfix '++' not supported |
| `while c {}` | `for c {}` | syntax error |
| `let` / `var` / `const x = 1` | `x := 1`, `X :: 1` | syntax error |
| `fn` / `func f()` | `f :: proc()` | syntax error |
| `int x = 3`, `x: int[3]` | `x: int = 3`, `x: [3]int` | 'int' is not an expression |
| `null`, `NULL` | `nil` | Undeclared name |
| `new Foo()` | `new(Foo)` | syntax error |
| `p->x` | `p.x` | Illegal use of -> |
| `try` / `catch` | multiple returns, `or_return` | syntax error |
| `Vec<int>` | `Vec(int)` | syntax error |
| `if (x := 1) {}` | `if x := 1; x > 0 {}` | syntax error |
| `cap(slice)` | `len(slice)` or a dynamic array | 'cap' is not supported |
| `x: int = 3.5` | `x: int = 3` or `f32` | truncated to int |
| `sizeof(T)`, `(int)x` | `size_of(T)`, `int(x)` | idiom |
| Rust `match`, `Option<T>` | `switch`, `Maybe(T)` | idiom |
| Go `for range` | `for x in xs` | idiom |
| Go `defer` at function end | `defer` at scope end | run result |

Rows marked "idiom" are not backed by an error message above; every other row comes from a compiler message or a run.
