package pair

Error :: enum {
	None,
	Too_Big,
}

make_pair :: proc(n: int, allocator := context.allocator) -> (a, b: []int, err: Error) {
	if n > 8 {
		err = .Too_Big
		return
	}
	a = make([]int, n, allocator)
	b = make([]int, n * 2, allocator)
	return
}
