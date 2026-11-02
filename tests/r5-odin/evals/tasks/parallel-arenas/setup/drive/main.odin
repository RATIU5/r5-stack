package main

import "../par"
import "core:fmt"
import "core:time"

CHUNK :: 500000
CHUNKS :: 32

main :: proc() {
	data := make([]u32, CHUNK)
	for j in 0 ..< CHUNK {
		data[j] = u32(j % 65536)
	}
	chunks := make([][]u32, CHUNKS)
	for i in 0 ..< CHUNKS {
		chunks[i] = data
	}

	t0 := time.tick_now()
	one := par.process(chunks, 1)
	d1 := time.duration_milliseconds(time.tick_since(t0))
	t1 := time.tick_now()
	four := par.process(chunks, 4)
	d4 := time.duration_milliseconds(time.tick_since(t1))

	fmt.println("sum", four.sum)
	fmt.println("max", four.max)
	fmt.println("count", four.count)
	fmt.println("same_as_one_worker", one == four)
	fmt.println("speedup_x100", int(100 * d1 / max(d4, 0.001)))
}
