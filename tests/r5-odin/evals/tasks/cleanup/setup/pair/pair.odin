package pair

Error :: enum {
	None,
	Too_Big,
}

make_pair :: proc(n: int, allocator := context.allocator) -> (a, b: []int, err: Error) {
	return
}
