package pool

Handle :: struct {
	index, gen: u32,
}

Pool :: struct {}

pool_init :: proc(p: ^Pool, capacity: int, allocator := context.allocator) {
}

pool_destroy :: proc(p: ^Pool) {
}

pool_add :: proc(p: ^Pool, value: int) -> (h: Handle, ok: bool) {
	return
}

pool_remove :: proc(p: ^Pool, h: Handle) -> bool {
	return false
}

pool_get :: proc(p: ^Pool, h: Handle) -> (value: int, ok: bool) {
	return
}

pool_len :: proc(p: ^Pool) -> int {
	return 0
}
