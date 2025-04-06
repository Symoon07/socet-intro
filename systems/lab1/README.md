# Systems Lab 1
## Before Starting
This lab is primarily a *software* lab, specifically about writing C and RISC-V assembly code. This document assumes some familiarity with C, but none with RISC-V. In this first section, we will introduce many of the instructions that you will use. However, the definitive instruction listing can be found at the [RISC-V Website](https://riscv.org/technical/specifications/).


### Basics of RISC-V
RISC-V is an open standard for an instruction set architecture (ISA). RISC-V has 32 general-purpose registers, and register 0 (x0, zero) is hard-wired to 0. The registers can be referred to as xN, for the Nth register, or by their [ABI Names](https://riscv.org/wp-content/uploads/2015/01/riscv-calling.pdf). For these examples, we will use the ABI names, since they are more descriptive and easier to read.

> Note: An Application Binary Interface (ABI) describes a protocol, or contract, for how code should inter-operate. Things like the calling convention (where data is located when you call a function, where return values should live, whose responsibility it is to save register values), sizes of different types (how many bits is an `int`? Depends on which computer you're using!), alignment requirements (e.g. an alignment of 4 means that the address is a multiple of 4), and more. You don't need to be familiar with any particular ABI details for this lab, but the word will come up when doing this kind of programming!

**Definitions**:
1. Caller: The piece of code that calls a function
2. Callee: The function that was called
3. Caller-saved: Registers whose values are not guaranteed to be preserved across function calls. That is, if you call a function, caller-saved registers may be modified by the callee. If the caller requires those values to be saved, it must store them into memory somewhere (typically on the stack) before calling the function, and load them back into the registers after the function returns.
4. Callee-saved: Registers whose values *must* be preserved accross function calls. This means that if the callee wants to make use of these registers, they must save their value (typically on the stack) before using them, and restore their value before returning.

A quick summary of ABI register names:
- zero (x0): hard-wired zero
- ra (x1): return address (e.g. for function calls)
- sp (x2): stack pointer (callstack)
- gp (x3): global pointer, used for accessing global variables in compiled code from higher-level languages
- tp (x4): thread pointer, pointer to thread-local data
- t0-t6 (x5-x7, x28-x31): temporary registers, caller-saved
- s0-s11 (x8-x9, x18-x27): saved registers, callee-saved. x8 is also the (optional) frame pointer.
- a0-a7: argument registers. Hold arguments for function calls. a0 and a1 also serve to hold return values from a function.

For the full details, see the [RISC-V UABI Documents](https://github.com/riscv-non-isa/riscv-elf-psabi-doc/blob/master/riscv-abi.adoc), specifically the "calling convention" document.


### Interrupts and Exceptions
An interrupt is a hardware-initiated transfer of control that is usually *asychronous*; that is, it can happen at any time, and the currently-executing application has no knowledge of when an interrupt will occur. When an interrupt occurs, the CPU will jump to a pre-defined address (an *interrupt vector*), save the PC of the location where it was when the interrupt happened (i.e. where to return to after the interrupt handler is done) based on the condition that caused it, and begin executing code here (the *interrupt handler*). 

Interrupts can be caused by various hardware peripherals, and in some architectures (RISC-V included) by a CPU directly. For example, things like:
- A hardware timer running out
- A CPU core interrupting another CPU core
- An external peripheral (e.g. USB) completing an action

In RISC-V, interrupt handling is split between the CPU and the *interrupt controller*, a dedicated piece of hardware that manages interrupts and notifies the CPU of interrupt conditions.

> Note: An *exception* is similar to an interrupt, only it is *synchronous* with the executing application. An exception is typically due to an error condition with the running program, such as a program attempting to access a bad memory location (segfault), executing an illegal instruction, a page fault, or even a *syscall*. Exceptions are handled in the same way as interrupts in RISC-V and many other ISAs.

On the CPU side, there are a number of *Control & Status Registers* (CSRs) that govern interrupt handling. Here is a subset of these registers:
- `mtvec`: Holds the base address of the interrupt *vector table*
- `mstatus.mie`: Holds control bits for many CPU functions. The `mie` bit determines whether interrupts are enabled/disabled globally.
- `mie`: Has a bit per interrupt source, that determines whether the specific interrupt is enabled or not. This is useful for filtering out sources of interrupts that you are not interested in. 
- `mip`: A bit per interrupt source, indicates that an interrupt is *pending*, e.g. the condition has occurred but has not been acknowledged
- `mepc`: The address you were executing at before the interrupt happened. This is where the CPU will return to when you exit the interrupt handler
- `mcause`: A unique value that tells you what caused the interrupt

To set up interrupts on a RISC-V CPU, you must set up `mtvec`, `mie`, and `mstatus.mie`. We won't go over the exact process in detail, but if you're interested, take a look at the code in `sw-tests/support`, which sets up interrupts.
> Note: Exceptions are always active (they do not require an enable bit). This is because most exceptions indicate an error condition that must be dealt with, such as an attempt to access a protected memory range, or executing an illegal instruction.

### RISC-V privilege basics 

The '`m`' prefix on these registers indicates the *privilege level* of the CPU. Machine ("M")-mode is the highest privilege, where firmware like a BIOS would run, and gives full access to the hardware. RISC-V also supports 2 more basic modes: Supervisor ("S") mode has less privilege than M-Mode, and is typically where a desktop OS kernel would run. S-mode comes with its own set of CSRs, most notably CSRs that control *virtual memory*. User "U"-mode is where applications can run and has the least privilege.

The privilege mode controls what instructions can be run by the executing code, which CSRs can be accessed, and even which memory regions can be accessed. For example, an application running in U-mode cannot alter the `mtvec` register to redirect interrupts to a new location: only M-mode software can do this, providing a level of security from malicious (or poorly-written) applications.

The privilege mode can be escalated using the `ecall` instruction, which causes a *synchronous* exception that goes to the next-highest mode. Symmetrically, each privilege mode (besides "U") has a special instruction `xret`, where `x` is the current mode (e.g. `mret` for M-mode) that lowers the privilege back to what it was before the last interrupt/exception and resumes the application at the address in the corresponding `xepc` register.
> It might seem strange that an instruction can escalate privilege mode; after all, if you can just upgrade your privilege, what is being protected?
>
> However, because `ecall` causes an *exception*, program control is transferred to an exception handler owned by software running in the next-higher privilege mode (e.g. OS, hypervisor, firmware); that is, the attacker can escalate the privilege mdoe, but cannot choose which code runs, and therefore cannot access any protected resource without permission from the OS.

For example, consider an application running in U-mode, and an OS running in S-mode. If the application requires access to a particular resource (e.g. more memory), it must use a *syscall*, which would be implemented by loading some arguments into the registers, then using `ecall` to enter the OS in S-mode. After doing the requested work, the OS will use the `sret` instruction to resume the application in U-mode.

## Writing code for AFTx07
For this lab, you will write code that runs on AFTx07 (the latest SoCET chip). The chip will be simulated using Verilator.

### Step 1: Set up AFTx07
To get started, clone the AFTx07 repository and follow its build instructions. If your account is set up properly, this should be as simple as:

1. Set up the Python virtual environment according to the README.md
2. Run `setup.sh` to download the needed libraries and submodules
3. Run `build.sh` to build the Verilator simulation
4. Run `./aft_out/sim-verilator/Vaftx07` to run the simulation. Note that the simulation needs a file named `meminit.bin` in the current directory. If you don't provide that, it will just run forever doing nothing, since the RAM is full of 0s.

There are many software tests you can run by navigating to the `sw-tests` directory, building them with CMake, and copying the resulting `.bin` files to the proper location.

### Step 2: Simple Assembly
The file "src/asmHello.S" contains the code listed below. Open it up and fill in the "TODO" part with whatever message you want to write.
```asm
.extern print # declare external symbol to be resolved at link time

.global asmHello
asmHello:
    addi sp, sp, -16
    sw ra, 0(sp)
    la t0, message
    la t1, name
    call print
    lw ra, 0(sp)
    li a0, 0
    addi sp, sp, 16
    ret

.data
message:
.string "Hello, world! My name is: %s\n"
name:
.string "" # TODO: Your name here
```

Now, run `make` to build the code. It will produce an executable (ELF) file named "step2", 

You should see a lot of text fly by. This is invoking the compiler `gcc` to build the supporting library code, and your assembly code.
> Note: The GNU assembler is called `as`. However, `gcc` is smart enough to invoke `as` automatically for assembly files, so you can just compile everything with `gcc` and let it figure out what to do.

> All of the gcc/binutils programs for our RISC-V toolchain (programs that let you compile and inspect binaries) are prefixed by `riscv64-unknown-elf-`, e.g. `riscv64-unknown-elf-gcc`. This prefix indicates the *cross compiler toolchain* being used; that is, we're compiling code not for our native machine, but for a RISC-V machine. You can read more about these "target triples" on the [OSDev website](https://wiki.osdev.org/Target_Triplet).

After the `make` command completes, you should see a number of build artifacts. The `.elf` files are the binaries in ELF format, which is the default output of the compiler. This is the executable format for Linux machines (similar to EXE files on Windows and Mach-O for macOS). The `.bin` files also are program binaries, but they contain *only* the program data as raw binary. We have AFTx07 set up to use raw binaries right now, which is why this is needed. Make sure that the files `lab3_2.elf` and `lab3_2.bin` are in this directory.

Next, rename `lab3_2.bin` to `meminit.bin`. Run the simulation with: `$AFTDEV_ROOT/aft_out/sim-verilator/Vaftx07` where `$AFTDEV_ROOT` is the top-level directory of AFT-dev. You should see your message printed to the screen!

> Note: You'll see some other prints. There is a small "kernel" that runs before your `main` code runs, which will set up some basic things on the system, and also provides the `print` function you used.

Let's look at what this did step-by-step.

Line 1: `.extern print` declares an external symbol named "print". This is just like the C statement `extern void print(const char *, ...)`, only in ASM, we don't have that type information. This line declares a symbol named `print` which is external to this file, so the linker knows to go look for this symbol elsewhere.

Line 2-3: `.global main` indicates that the symbol `main` should be made globally available; that is, if another piece of code wants to reference `main`, the linker will use this symbol. If you don't mark something as `.global`, other files cannot see that symbol. This is like if assembly labels were `static` variables/functions in C. 

Line 4-5: This part uses `addi sp, sp, -16` to allocate space on the stack (by moving the stack pointer), then saves the value of `ra` onto the stack using `sw ra, 0(sp)`. We plan on modifying `ra` later (thus losing our return address), so we need to save it now.

Line 6-7: The `la rX, symbol` instruction loads the address of a symbol into a register. These lines set `a0` and `a1` to the addresses of our message and name strings, respectively. (To be clear: `t0` and `t1` hold *pointers*, e.g. `char *` in C).
> Note: `la` is a so-called "pseudo-instruction", that was added to make programmer's lives easier. `la rX, symbol` loads the effective address of a given symbol into the register `rX`. Some architectures have the ability to load full-sized constants into registers (e.g. x86-64), but on RISC-V, this often must be done with a multi-instruction sequence. For example, to load the constant `0x80000001` into a register in RISC-V, you might do:
> ```
> lui r1, 0x80000 # "load-upper-immediate", set upper 20b of r1 to 0x80000, lower 12 to 0
> addi r1, r1, 1  # "add immediate", add "1" to the contents of r1
> ```
> However, if we only wanted to load `0x80000000`, it could be done with a single `lui`. RISC-V assembly has a pseudo-instruction `li` (load immediate), that the assembler will expand to the shortest possible sequence of instructions to build the immediate value. However, for symbols, we don't know their value until link time, so we cannot use `li`. The `la` instruction, on the other hand, defers the instruction selection for building this constant to link-time. Based on where the address is located in memory, the linker can choose whether it needs 2 instructions, or only a single instruction to build the desired constant value. The linker can also shuffle things around to optimize this process by locating things such that they can be reached with a single instruction from where they are used. This process is called *linker relaxation*. If you are interested, there's a [great blog post](https://www.sifive.com/blog/all-aboard-part-3-linker-relaxation-in-riscv-toolchain) from SiFive talking about this process.

Line 8: `call print` will call the print function that we declared `.extern`
> Note: `call` is a pseudo-instruction that expands to `jal ra, print`. `jal` is "jump-and-link", which makes the CPU jump to a specified address (`print`'s address), and save PC + 4 into the target register. In this case, the target register is `ra`, the ABI return address register. Saving PC + 4 allows us to resume from the instruction after the function call when we eventually return.

Line 9: `li a0, 0` loads 0 into the a0 register. This is setting up the return value of 0 for returning from `main`. If we don't do this, the calling code will think there is a problem (like in C, returning a non-zero code indicates an error occurred), and print a message like `Test Failed`.

Line 10-11: This section restores our old value of `ra`, in preparation to return from `main`. First, we reload `ra` with `lw ra, 0(sp)`. Then, we de-allocate our stack space by bumping the stack pointer back up, using `addi sp, sp, 16`.

Line 12: `ret`, the `return` instruction. This will return from our `main` function. Note that this is where execution resumes after the `print` function call returns.
> Note: `ret` is another pseudo-instruction, that expands to `jr ra`. `jr` (Jump-Register) sets the program counter to the contents of the specified register. Here it uses `ra`, the ABI return address register.

Before continuing, let's inspect the output of the compiler. To do this, run the following command to disassemble the code:
```
riscv64-unknown-elf-objdump -d step2.elf
```
You will see a lot of output. This is a *disassembly*, or human-readable printing of the machine code generated after compiling/assembling the input files. One thing of note here is that addresses are also assigned for all the code and data: this was done during the *linking* step. Try to find the code you wrote, which should be under the label `main`. You should be able to see what the linker replaced your `la` instructions with!

> Question 1: Find our code in the output under the `main` label. What did the `la` instructions become after compiling? Look in the disassembly.

### Step 3: Making a syscall interface
In this section, you will make an interface for syscalls and implement a simple syscall to demonstrate. This will involve mixing C and assembly code together.

Specifically, you will implement a syscall that sets a timer. Normally, unprivileged user code cannot interact with the `mtime` system timer, so we will provide M-mode firmware that sets a timer, and a function to request a timer be set on behalf of the U-mode code.


#### Step 3a: Setting a timer in C
Assembly is, of course, not an easy way for programmers to write code. In this section, we will write C code that runs on AFTx07. We'll be using a timer interrupt to print a message periodically for a certain amount of time. 

The starter code can be found in `step3.c`.

The starter code has some helper functions for dealing with memory-mapped I/O, that you'll see next week. The goal of this lab is to toggle the GPIO periodically, and print a message each time. 

To do this, you will use the RISC-V `mtime` interrupt. RISC-V cores implementing the privileged instrution set will have a few memory-mapped registers: `mtime`, a 64b register that tracks time, and an `mtimecmp` register per core. `mtime` counts up, and when the value of `mtime` reaches or exceeds `mtimecmp`, a timer interrupt is sent to the corresponding core.

The startup code in `sw-tests` sets up the RISC-V core in *vectored* mode, which allows programmers to set up a different interrupt handler for each interrupt source, and receiving a particular interrupt will cause the core to jump to a corresponding location. The startup code also defines all the interrupt handlers, with *weak* definitions: that is, if the programmer does not re-define the function, it uses a default implementation provided; if the function is re-defined by the programmer, the default implementation is discarded and the re-definition is used instead.

> Note: The above is a simplified description of vectored mode. In more detail: the `mtvec` register is set to the address of a *vector table* in memory, which is a list of jump instructions that will go to different handlers. When an interrupt is received, the CPU jumps to the address `mtvec + interrupt-number x 4`. This address will contain a jump instruction to go to a specific interrupt handler. This is in contrast to direct mode, where the CPU jumps to a single location, and the handler uses a `if`/`switch` statements to handle different interrupt conditions.

The given functions are as follows:
`read_mtime()` - returns 32b "mtime" value
`read_mtimecmp()` - returns 32b "mtimecmp" value
`write_mtimecmp(uint32_t value)` - writes "value" into "mtimecmp"
`setup_gpio()` - sets up the GPIO in output mode, initializes the output data to 0
`toggle_gpio()` - flips the value in the GPIO

> Task: Fill in `lab3_3.c` to implement a periodic GPIO blink, and print a message each time. Include the value of `mtime` in your message so you can see that it works!

#### Step 3b: The syscall interface
For this part, you will create a few functions to implement the syscall. The overall idea is this:
`timer_set(uint64_t millis) -> syscall(uint32_t num, uint64_t arg) -> exception_handler`. The function `timer_set` is a higher-level API that programmers can use to set a timer for a specified number of milliseconds. The `syscall` function makes a syscall using the `ecall` instruction, providing the syscall number (e.g. what should be done) and an argument in registers `a0` and `a1`.
Finally, the `exception_handler` function will call an M-mode function that sets the timer.

### Step 4: RTL Diagram
For the next lab, you will be designing a small hardware accelerator or peripheral for AFTx07. For this lab's last task, draw the RTL diagram for your chosen design. You are welcome to take one of the following 2 ideas, or propose your own:

#### Divisible-by-5 checker
Re-use the code from lab 2's FSM to perform divisibility checks on a 32b integer. This will require the following registers to be added:

- A data register (for 32b input)
- Result register (1/0 for divisible-by-5)
- Control register (writing a 1 starts the operation)
- Status register (0 for busy, 1 for done)

The usage would look like this:

1. Write a 32b value into the data register
2. Write a '1' into the control register to start
3. Wait for the status register to become '1'
4. Read the result register to see the output

This will require some extra hardware in addition to your FSM to create the registers, count how many bits have been shifted in, and actually perform the shifting.

#### Bit-manipulation
Implement a hardware accelerator for complex bit manipulation operations. You will need the following registers:

1. Data register (for 32b input)
2. Result register (32b output)
3. Operation register (for selecting an operation)
4. Status register (0/1 for busy/complete). Depending on your implementation, this may always be a 1 (e.g. if the computation is combinational logic).

You should support at least the following operations:

1. Count-leading-zeros: starting with the MSB, count the number of '0' bits until the first '1'. The result will be in the range 0-32.
2. Count-trailing-zeros: starting with the LSB, count the number of '0' bits until the first '1'. The result will be in the range 0-32.
3. Population count: count the number of '1' bits in the input. The result will be in the range 0-32
4. Parity check: count the number of '1' bits in the input. If this count is even, output a '1', otherwise output a '0'. The result will be either 0 or 1.

For the operation register, you will need to assign values to the different operations, e.g. 0 = CLZ, 1 = CTZ, etc. For values that fall outside the legal range, you can return '0'.

#### Other ideas
- Simple PWM controller with fixed period, configurable duty cycle, enable/disable
- Hardware Multiply-And-Accumulate (MAC). Computes a = a + (b x c). Have a "reset" that sets a = 0, then perform MAC operations on 2 input data values and accumulate in the "a" register. Make sure to have a reasonable multiplier design! (*not* purely combinational)

#### Your idea
If you have an idea you want to try, please reach out! You can do things like create devices with custom interrupts, have I/O pins on the chip, or even create a design that acts as a bus manager!
