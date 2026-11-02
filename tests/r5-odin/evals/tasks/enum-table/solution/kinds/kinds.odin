package kinds

Kind :: enum u8 {
	A = 1,
	B = 4,
	C,
}

name_of :: proc(k: Kind) -> string {
	table := #sparse[Kind]string {
		.A = "alpha",
		.B = "beta",
		.C = "gamma",
	}
	return table[k]
}
