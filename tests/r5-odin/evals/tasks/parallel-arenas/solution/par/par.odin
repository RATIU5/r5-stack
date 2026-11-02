package par

import "core:thread"
import vmem "core:mem/virtual"

Stats :: struct {
	sum:   u64,
	max:   u64,
	count: int,
}

Job :: struct {
	chunks:  [][]u32,
	worker:  int,
	workers: int,
	result:  Stats,
}

run_job :: proc(t: ^thread.Thread) {
	job := cast(^Job)t.data
	arena: vmem.Arena
	if vmem.arena_init_growing(&arena) != nil {
		return
	}
	defer vmem.arena_destroy(&arena)
	allocator := vmem.arena_allocator(&arena)

	for i := job.worker; i < len(job.chunks); i += job.workers {
		squares := make([dynamic]u64, 0, 0, allocator)
		for v in job.chunks[i] {
			append(&squares, u64(v) * u64(v))
		}
		for s in squares {
			job.result.sum += s
			job.result.max = max(job.result.max, s)
			job.result.count += 1
		}
		vmem.arena_free_all(&arena)
	}
}

process :: proc(chunks: [][]u32, workers: int) -> Stats {
	n := max(workers, 1)
	jobs := make([]Job, n)
	defer delete(jobs)
	threads := make([]^thread.Thread, n)
	defer delete(threads)

	for i in 0 ..< n {
		jobs[i] = Job {
			chunks  = chunks,
			worker  = i,
			workers = n,
		}
		threads[i] = thread.create(run_job)
		threads[i].data = &jobs[i]
		thread.start(threads[i])
	}

	stats: Stats
	for i in 0 ..< n {
		thread.join(threads[i])
		thread.destroy(threads[i])
		stats.sum += jobs[i].result.sum
		stats.max = max(stats.max, jobs[i].result.max)
		stats.count += jobs[i].result.count
	}
	return stats
}
