#include <stdint.h>

#ifndef ACCELERATOR_H
#define ACCELERATOR_H

typedef struct Accelerator Accelerator;

Accelerator *initAccelerator();

void accelerator_write(Accelerator *accelerator, uint32_t val);

uint32_t accelerator_read(Accelerator *accelerator);

#endif
