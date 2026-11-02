package textutil

import "core:strings"

join_lines :: proc(lines: []string, allocator := context.allocator) -> string {
	return strings.join(lines, "\n", allocator)
}
