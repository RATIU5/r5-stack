package kinds

import "core:testing"

@(test)
names :: proc(t: ^testing.T) {
	testing.expect_value(t, name_of(.A), "alpha")
	testing.expect_value(t, name_of(.B), "beta")
	testing.expect_value(t, name_of(.C), "gamma")
}
