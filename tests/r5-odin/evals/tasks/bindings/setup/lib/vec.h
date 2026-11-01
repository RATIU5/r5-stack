#include <stddef.h>
#include <stdint.h>

typedef struct {
	int32_t count;
	double mean;
} Stats;

float vec_dot(const float *a, const float *b, size_t n);
Stats stats_of(const double *xs, size_t n);
