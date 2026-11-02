package par

Stats :: struct {
	sum:   u64,
	max:   u64,
	count: int,
}

process :: proc(chunks: [][]u32, workers: int) -> Stats {
	stats: Stats
	for chunk in chunks {
		squares := make([dynamic]u64)
		for v in chunk {
			append(&squares, u64(v) * u64(v))
		}
		for s in squares {
			stats.sum += s
			stats.max = max(stats.max, s)
			stats.count += 1
		}
		delete(squares)
	}
	return stats
}
