package par

import "core:mem"
import "core:testing"

sequential :: proc(chunks: [][]u32) -> Stats {
	stats: Stats
	for chunk in chunks {
		for v in chunk {
			s := u64(v) * u64(v)
			stats.sum += s
			stats.max = max(stats.max, s)
			stats.count += 1
		}
	}
	return stats
}

make_chunks :: proc(count: int, allocator := context.allocator) -> [][]u32 {
	chunks := make([][]u32, count, allocator)
	for i in 0 ..< count {
		chunks[i] = make([]u32, (i * 7) % 50, allocator)
		for j in 0 ..< len(chunks[i]) {
			chunks[i][j] = u32(i * 100 + j)
		}
	}
	return chunks
}

free_chunks :: proc(chunks: [][]u32, allocator := context.allocator) {
	for c in chunks {
		delete(c, allocator)
	}
	delete(chunks, allocator)
}

@(test)
matches_the_sequential_result :: proc(t: ^testing.T) {
	chunks := make_chunks(37)
	defer free_chunks(chunks)
	want := sequential(chunks)
	for workers in ([?]int{1, 2, 3, 8, 50}) {
		testing.expect_value(t, process(chunks, workers), want)
	}
}

@(test)
empty_input :: proc(t: ^testing.T) {
	testing.expect_value(t, process(nil, 4), Stats{})
	chunks := make_chunks(0)
	defer free_chunks(chunks)
	testing.expect_value(t, process(chunks, 3), Stats{})
}

@(test)
more_workers_than_chunks :: proc(t: ^testing.T) {
	chunks := make_chunks(2)
	defer free_chunks(chunks)
	testing.expect_value(t, process(chunks, 16), sequential(chunks))
}

@(test)
leaves_nothing_allocated_behind :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	chunks := make_chunks(20)
	defer free_chunks(chunks)
	context.allocator = mem.tracking_allocator(&track)
	process(chunks, 4)
	testing.expect_value(t, len(track.allocation_map), 0)
}
