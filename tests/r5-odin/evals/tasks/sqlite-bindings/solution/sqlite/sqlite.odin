package sqlite

import "base:runtime"
import "core:c"
import "core:strings"

foreign import lib "system:sqlite3"

Db :: distinct rawptr
Stmt :: distinct rawptr

SQLITE_OK :: 0
SQLITE_ROW :: 100

Exec_Callback :: #type proc "c" (user: rawptr, columns: c.int, values: [^]cstring, names: [^]cstring) -> c.int

@(default_calling_convention = "c")
foreign lib {
	sqlite3_open :: proc(filename: cstring, db: ^Db) -> c.int ---
	sqlite3_close :: proc(db: Db) -> c.int ---
	sqlite3_exec :: proc(db: Db, sql: cstring, callback: Exec_Callback, user: rawptr, errmsg: ^cstring) -> c.int ---
	sqlite3_prepare_v2 :: proc(db: Db, sql: cstring, nbyte: c.int, stmt: ^Stmt, tail: ^cstring) -> c.int ---
	sqlite3_step :: proc(stmt: Stmt) -> c.int ---
	sqlite3_finalize :: proc(stmt: Stmt) -> c.int ---
	sqlite3_column_int64 :: proc(stmt: Stmt, col: c.int) -> i64 ---
	sqlite3_column_text :: proc(stmt: Stmt, col: c.int) -> cstring ---
}

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

open_with :: proc(setup_sql: string, allocator: runtime.Allocator) -> (db: Db, err: Error) {
	if sqlite3_open(":memory:", &db) != SQLITE_OK {
		sqlite3_close(db)
		return nil, .Open_Failed
	}
	setup := strings.clone_to_cstring(setup_sql, allocator)
	defer delete(setup, allocator)
	if sqlite3_exec(db, setup, nil, nil, nil) != SQLITE_OK {
		sqlite3_close(db)
		return nil, .Exec_Failed
	}
	return db, nil
}

query_people :: proc(setup_sql, select_sql: string, allocator := context.allocator) -> (rows: []Row, err: Error) {
	db := open_with(setup_sql, allocator) or_return
	defer sqlite3_close(db)

	query := strings.clone_to_cstring(select_sql, allocator)
	defer delete(query, allocator)
	stmt: Stmt
	if sqlite3_prepare_v2(db, query, -1, &stmt, nil) != SQLITE_OK {
		return nil, .Prepare_Failed
	}
	defer sqlite3_finalize(stmt)

	list := make([dynamic]Row, 0, 16, allocator)
	for sqlite3_step(stmt) == SQLITE_ROW {
		name := strings.clone_from_cstring(sqlite3_column_text(stmt, 1), allocator)
		append(&list, Row{id = sqlite3_column_int64(stmt, 0), name = name})
	}
	return list[:], nil
}

count_callback :: proc "c" (user: rawptr, columns: c.int, values: [^]cstring, names: [^]cstring) -> c.int {
	(cast(^int)user)^ += 1
	return 0
}

count_rows :: proc(setup_sql, select_sql: string, allocator := context.allocator) -> (n: int, err: Error) {
	db := open_with(setup_sql, allocator) or_return
	defer sqlite3_close(db)

	query := strings.clone_to_cstring(select_sql, allocator)
	defer delete(query, allocator)
	if sqlite3_exec(db, query, count_callback, &n, nil) != SQLITE_OK {
		return 0, .Prepare_Failed
	}
	return n, nil
}
