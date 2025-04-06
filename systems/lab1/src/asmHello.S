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
