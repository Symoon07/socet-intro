# uint8_t popcnt(uint32_t a);
# Takes in a 32 bit integer and returns the number of 1s in it
.global popcnt
popcnt:
    # TODO
    li t0, 0 # Count
    li t1, 0 # 0
loop:
    beq a0, t1, done
    andi t2, a0, 1
    add t0, t0, t2
    srli a0, a0, 1
    j loop
done:
    mv a0, t0
    ret

# uint8_t popcnt_secure(uint32_t a);
# Takes in a 32 bit integer and returns the number of 1s in it. A more secure
# version of `popcnt` which is roughly constant time for any input `a`
.global popcnt_secure
popcnt_secure:
    # TODO
    li t0, 0 # Count
    li t1, 0 # Current index
    li t2, 32 # Size
loop_secure:
    bge t1, t2, done
    andi t3, a0, 1
    add t0, t0, t3
    srli a0, a0, 1
    addi t1, t1, 1
    j loop_secure

