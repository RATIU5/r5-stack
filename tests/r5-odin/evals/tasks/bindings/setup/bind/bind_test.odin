package bind

import "core:testing"

@(test)
dot_works :: proc(t: ^testing.T) {
	testing.expect_value(t, dot([]f32{1, 2, 3}, []f32{4, 5, 6}), 32)
}

@(test)
mean_works :: proc(t: ^testing.T) {
	testing.expect_value(t, mean_of([]f64{1, 2, 3, 4}), 2.5)
}
