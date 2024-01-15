# Digital Design Lab 4


## Before you start
### Definitions
- Driver: Piece of software responsible for interacting with a hardware device, and providing a higher-level API to programmers. Example: A UART driver with a "send" API that sends a whole string of characters.


### Review: MMIO
Memory-Mapped I/O (MMIO) is a paradigm for interacting with I/O devices where devices are assigned a range of addresses, and reads/writes to these addresses will be interpreted by the devices as various commands. This allows CPUs (and any other bus manager) to easily perform I/O operations via typical load/store instructions, rather than requiring special-purpose instructions. As an example, the next section will walk through a simple GPIO driver, exposing an API that lets users set certain pins to specific values.

### `volatile`
In C, the `volatile` keyword is a *type qualifier* that informs the compiler a specific value may change *outside of the control of the program*. This means that a compiler may not make certain assumptions about the data: for example, it cannot perform *register allocation*, where a frequently-accessed variable is kept in a register to reduce the amount of loads/stores, and instead must load and store data explicitly, every time. This keyword is intended to support MMIO, as I/O devices require load/store operations to work correctly, and the values read from the same location may change over time even without the program interfering (e.g. a timer counting up each cycle). 

Here's a short example of using a volatile variable:
```c
volatile uint32_t *my_accelerator_address = 0xCAFE0000;
uint32_t current_value = *my_accelerator_address; // Reads data from the device
*my_accelerator_address = 0xAABBCCDD;             // Writes data into the device
```
**Warning**: `volatile` has an *extremely* narrow use case! In particular, it should never be used for thread synchronization, *even for interrupt handlers on the same device* (you need atomics).

### A GPIO Driver
As an example, let's look through a simple GPIO driver for AFTx07. First, here is the *memory map* for the GPIO. Note that the addresses are *offsets* from a base address, e.g. the `data` register is at address `BASE + 0x0`. For AFTx07, `BASE` is `0x80000000`.

| Offset | Register | Description |
---------|----------|--------------
0x0      |  `data`  |  Current state of GPIO pins, 1 bit per pin
0x4      |  `ddr`   | Data Direction: `0` indicates input, `1` indicates output, 1 bit per pin
0x8      |  `ier`   | Interrupt Enable Register: Setting bit `n` to `1` enables interrupts on pin `n`. Must be used with corresponding `per`/`ner` bit to allow an interrupt!
0xC      |  `per`   | Positive Edge Register: Setting bit `n` to `1` enables a rising-edge interrupt for pin `n`
0x10     |  `ner`   | Negative Edge Register: Similar to `per`, but for falling-edge inputs
0x14     |  `icr`   | Interrupt Clear Register: Writing a `1` to bit `n` of this register clears the corresponding pending interrupt. Hardware will reset the value to 0 after clearing the pending interrupt.
0x18     |  `isr`   | Interrupt Status Register: A set bit `n` indicates that an interrupt is pending for pin `n`


There are many ways to write a driver, depending on the API you wish to present to the user. One goal (often) of a driver is to hide some implementation details and require users to go through your API (encapsulation), so for this design, we will use a C-struct + an *opaque pointer* to hide the definition of the struct from the users, indicating that they should not rely on the specific implementation, but rather make use of our API functions.

This will be split between a header file `gpio.h` and an implementation file `gpio.c`. Often, driver source code for embedded systems will be part of the SDK and users will compile it themselves, but you could also distribute pre-compiled libraries to link into user applications, and provide only the header files as source code. These files are provided to you: look through them as you read the rest of this section.

This part of the document will go over a few of the parts of the code in-depth.

####


## Final Assignment: An AFTx07 peripheral
Now that you've learned about MMIO and interacted with existing peripherals, you could create your own hardware peripheral to add into the chip. The process is fairly straightforward.

### Step 0: Decide on the function
This can be something as simple as a small arithmetic operation, to as large as you would like. Ultimately, it just needs to provide some feedback so that you can verify it works by writing software for it. Some simple suggestions might be a large mathematical operation, large bit manipulation unit (e.g. population count, count leading/trailing zeros, parity, etc.), or even a simple encryption scheme. 

### Step 1: Decide on the interface
First, decide on the interface for you hardware. How many control/status/data registers does it need, and what do they do? Common things to provide registers for would be: input data, output data, a "control" register that selects what operation (if multiple) and tells the computation to start, and a status register to show that the computation is done. You will also need to define the offsets. For simplicity, make all your register start at multiples of 4B (word size).

At this point, you can create a C header file for interacting with your peripheral. Define a `struct` that captures all your registers. 


### Step 2: RTL + TB
Using the SoCET library's `bus_protocol_if`, you can design a peripheral easily (hooking it up to the AHB/APB bus has been automated, provided you use this interface). You can read how `bus_protocol_if` works on this [wiki page](https://wiki.itap.purdue.edu/display/ecedesign/Bus+Components), which includes signal descriptions and a timing diagram.

Implement your module's RTL, and make the control/status/data registers accessible via the `bus_protocol_if`. 

### Step 3: Integration
For integration, you will need to make a FuseSoC core file for your module, and add it as a dependency of AFTx07.core. From there, you will need to edit the top level aftx07.sv, adding:
- An instance of your module
- An instance of `bus_protocol_if` to connect to it
- An address in the `AHB_MAP` (and corresponding index) to allocate to your device
- Use the `ADD_AHB` macro to attach your module to the AHB bus at the address you specified

At this point, you should be able to build AFTx07 with your hardware on-board!

### Step 4: Software tests
Finally, write a test in C that uses your peripheral. To demonstrate its functionality, you will need to either show by printing out a changed value (if you did a computation), or in waveforms (if you have I/O).