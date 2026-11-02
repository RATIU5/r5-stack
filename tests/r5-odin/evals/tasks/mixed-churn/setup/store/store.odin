package store

Id :: distinct u32

Store :: struct {}

store_init :: proc(s: ^Store, capacity: int, allocator := context.allocator) {
}

store_destroy :: proc(s: ^Store) {
}

store_add :: proc(s: ^Store, data: []byte) -> (id: Id, ok: bool) {
	return
}

store_get :: proc(s: ^Store, id: Id) -> (data: []byte, ok: bool) {
	return
}

store_remove :: proc(s: ^Store, id: Id) -> bool {
	return false
}
