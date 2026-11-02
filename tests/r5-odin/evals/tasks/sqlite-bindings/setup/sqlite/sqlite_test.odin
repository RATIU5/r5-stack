package sqlite

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:testing"

SETUP :: "create table people(id integer, name text); insert into people values (1, 'ada'), (2, 'grace');"

free_rows :: proc(rows: []Row, allocator: mem.Allocator) {
	for row in rows {
		delete(row.name, allocator)
	}
	delete(rows, allocator)
}

@(test)
reads_rows_and_frees_cleanly :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
	allocator := mem.tracking_allocator(&track)

	rows, err := query_people(SETUP, "select id, name from people order by id", allocator)
	testing.expect_value(t, err, Error.None)
	testing.expect_value(t, len(rows), 2)
	if len(rows) == 2 {
		testing.expect_value(t, rows[0].id, 1)
		testing.expect_value(t, rows[0].name, "ada")
		testing.expect_value(t, rows[1].name, "grace")
	}
	free_rows(rows, allocator)
	testing.expect_value(t, len(track.bad_free_array), 0)
	testing.expect_value(t, len(track.allocation_map), 0)
}

@(test)
copies_text_out_of_sqlite :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
	allocator := mem.tracking_allocator(&track)

	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	strings.write_string(&b, "create table people(id integer, name text);")
	for i in 0 ..< 1000 {
		fmt.sbprintf(&b, "insert into people values (%d, 'n%d');", i, i)
	}
	rows, err := query_people(strings.to_string(b), "select id, name from people order by id", allocator)
	testing.expect_value(t, err, Error.None)
	testing.expect_value(t, len(rows), 1000)
	matches := 0
	for row, i in rows {
		if row.name == fmt.tprintf("n%d", i) {
			matches += 1
		}
	}
	testing.expect_value(t, matches, len(rows))
	free_rows(rows, allocator)
	testing.expect_value(t, len(track.bad_free_array), 0)
	testing.expect_value(t, len(track.allocation_map), 0)
}

@(test)
empty_result_is_fine :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	allocator := mem.tracking_allocator(&track)

	rows, err := query_people(SETUP, "select id, name from people where id > 100", allocator)
	testing.expect_value(t, err, Error.None)
	testing.expect_value(t, len(rows), 0)
	delete(rows, allocator)
	testing.expect_value(t, len(track.allocation_map), 0)
}

@(test)
reports_bad_sql_without_leaking :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	allocator := mem.tracking_allocator(&track)

	_, err := query_people(SETUP, "select nope from nowhere", allocator)
	testing.expect_value(t, err, Error.Prepare_Failed)
	testing.expect_value(t, len(track.allocation_map), 0)
	_, err2 := query_people("not sql at all", "select 1", allocator)
	testing.expect_value(t, err2, Error.Exec_Failed)
	testing.expect_value(t, len(track.allocation_map), 0)
}

@(test)
counts_rows_through_a_callback :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	allocator := mem.tracking_allocator(&track)

	n, err := count_rows(SETUP, "select * from people", allocator)
	testing.expect_value(t, err, Error.None)
	testing.expect_value(t, n, 2)
	_, err2 := count_rows(SETUP, "select nope from nowhere", allocator)
	testing.expect_value(t, err2, Error.Prepare_Failed)
	testing.expect_value(t, len(track.allocation_map), 0)
}
