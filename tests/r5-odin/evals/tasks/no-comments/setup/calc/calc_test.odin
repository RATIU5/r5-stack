package calc

import "core:testing"

@(test)
clamps :: proc(t: ^testing.T) {
	testing.expect_value(t, clamp_add(5, 5, 0, 8), 8)
	testing.expect_value(t, clamp_add(-5, 1, 0, 8), 0)
	testing.expect_value(t, clamp_add(2, 3, 0, 8), 5)
}
