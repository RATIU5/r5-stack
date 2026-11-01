package bind

import "core:c"

foreign import vec "../lib/libvec.a"

Stats :: struct {
	count: c.int32_t,
	mean:  c.double,
}

@(default_calling_convention = "c")
foreign vec {
	vec_dot :: proc(a, b: [^]c.float, n: c.size_t) -> c.float ---
	stats_of :: proc(xs: [^]c.double, n: c.size_t) -> Stats ---
}

dot :: proc(a, b: []f32) -> f32 {
	return vec_dot(raw_data(a), raw_data(b), c.size_t(len(a)))
}

mean_of :: proc(xs: []f64) -> f64 {
	return stats_of(raw_data(xs), c.size_t(len(xs))).mean
}
