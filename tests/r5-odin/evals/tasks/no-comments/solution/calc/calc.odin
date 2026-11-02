package calc

// existing note
clamp_add :: proc(a, b, lo, hi: int) -> int {
	return clamp(a + b, lo, hi)
}
