#include "vec.h"

float vec_dot(const float *a, const float *b, size_t n) {
	float s = 0;
	for (size_t i = 0; i < n; i++) s += a[i] * b[i];
	return s;
}

Stats stats_of(const double *xs, size_t n) {
	Stats r = {(int32_t)n, 0};
	double s = 0;
	for (size_t i = 0; i < n; i++) s += xs[i];
	if (n) r.mean = s / (double)n;
	return r;
}
