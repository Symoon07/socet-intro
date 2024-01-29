#include <stdint.h>

#include "riscv.h"
#include "format.h"
#include "pal.h"

#define ITERATION (1000)
#define TOTAL_DURATION (20 * ITERATION)

CLINTRegBlk *clint = (CLINTRegBlk *)CLINT_BASE;
GPIORegBlk *gpio = (GPIORegBlk *)GPIO_BASE;

volatile uint32_t end_time = 0;
volatile bool done_flag = false;

static uint32_t
__attribute__((noinline)) read_mtime() {
    return clint->mtime;
}

static uint32_t
__attribute__((noinline)) read_mtimecmp() {
    return clint->mtimecmp;
}

static void
__attribute__((noinline)) write_mtimecmp(uint32_t value) {
    clint->mtimecmp = value;
}

static void
__attribute__((noinline)) setup_gpio() {
    gpio->ddr = 0xFFFFFFFF;
    gpio->data = 0x0;
}

static void
__attribute__((noinline)) toggle_gpio() {
    gpio->data ^= 0xFFFFFFFF;
}

void __attribute__((interrupt)) mtime_handler() {
    // TODO: Fill in your ISR here!
    // Tasks:
    // if mtime has exceeded end_time,
    // set the done_flag to true, and disable interrupts
    // Otherwise, update mtimecmp to be mtimecmp + ITERATION
}

int main() {
    // TODO: Read the value of mtime to get the start time. Compute
    // the ending time as start time + DURATION, and set the variable
    // end_time to that value.

    // Write mtimecmp with start time + ITERATION

    // TODO: Call enable_interrupts() to start allowing interrupts!
    
    // TODO: Wait in main (loop) until done_flag is true
    return 0;
}