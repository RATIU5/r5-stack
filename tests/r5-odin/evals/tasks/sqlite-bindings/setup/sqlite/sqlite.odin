package sqlite

Error :: enum {
	None,
	Open_Failed,
	Exec_Failed,
	Prepare_Failed,
}

Row :: struct {
	id:   i64,
	name: string,
}

query_people :: proc(setup_sql, select_sql: string, allocator := context.allocator) -> (rows: []Row, err: Error) {
	return
}

count_rows :: proc(setup_sql, select_sql: string, allocator := context.allocator) -> (n: int, err: Error) {
	return
}
