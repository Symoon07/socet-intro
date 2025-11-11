#include "accelerator.h"

#define BASE 0xD0000000

struct Accelerator {
    volatile uint32_t in;
    volatile uint32_t out;
};

Accelerator *initAccelerator() { return (Accelerator *)BASE; }

void accelerator_write(Accelerator *accelerator, uint32_t val) {
    accelerator->in = val;
}

uint32_t accelerator_read(Accelerator *accelerator) {
    return accelerator->out;
}