# uint8_t popcnt(uint32_t a);
# Takes in a 32 bit integer and returns the number of 1s in it
.global popcnt
popcnt:
    mv t0, zero
    beqz a0, popcnt_done
popcnt_loop:
    andi t1, a0, 1
    add t0, t0, t1
    srli a0, a0, 1
    bnez a0, popcnt_loop
popcnt_done:
    mv a0, t0
    ret

# uint8_t popcnt_secure(uint32_t a);
# Takes in a 32 bit integer and returns the number of 1s in it. A more secure
# version of `popcnt` which is roughly constant time for any input `a`
.global popcnt_secure
popcnt_secure:
    li t0, 0
    li t1, 32
popcnt_secure_loop:
    andi t2, a0, 1
    add t0, t0, t2
    srli a0, a0, 1
    addi t1, t1, -1
    bnez t1, popcnt_secure_loop

    mv a0, t0
    ret

