#include <stdint.h>
#include <stdio.h>

#define STEP1 1
#define STEP2 0
#define STEP3 0

#define N 64

uint32_t input[N] = {
    0x00000000, 0xFFFFFFFF, 0x00BA6A24, 0xF4A0DCF9, 0xBBD0D09A, 0x22E8AE33,
    0x15E2D9A5, 0x67F95E5C, 0xBBD0D09A, 0x22E8AE33, 0x15E2D9A5, 0x67F95E5C,
    0xEE92150C, 0xA3304C3D, 0x744477C5, 0x01B67AB8, 0x19018474, 0x8057564A,
    0x159D27CA, 0xF93EF0C3, 0x08DA476D, 0x322426FA, 0x5E072FFD, 0xD41543DE,
    0x0E44E744, 0x21F0EDCC, 0xB918FDBD, 0x441A692A, 0x9F67451A, 0xCB7763FB,
    0x0559C0F8, 0x2F504328, 0xC66BA44D, 0x86B7C770, 0x1D2CA59C, 0x1BB35723,
    0x8A6EF954, 0xC2ACDB61, 0x7C93AAFF, 0x0F201FFF, 0xEFB54BC9, 0xA7120239,
    0xF5E2BCF6, 0x28FB7BAA, 0xB53F17BF, 0x00000200, 0xC7B77096, 0x213F0640,
    0xB53F17BF, 0x5B9A9C3C, 0xC7B77096, 0x213F0640, 0x0B3390A8, 0x04786A3D,
    0x62EA482E, 0x4D865305, 0x8197C0A6, 0x58700621, 0x558FDBD0, 0xD531E786,
    0xAD9EF39F, 0x00004300, 0x67162F16, 0x00000001,
};

uint32_t expected[N] = {
    0,  32, 11, 18, 16, 15, 16, 20, 16, 15, 16, 20, 14, 14, 16, 15,
    10, 13, 16, 19, 15, 14, 20, 16, 13, 16, 20, 12, 17, 22, 13, 12,
    16, 17, 15, 17, 17, 16, 21, 18, 20, 12, 21, 19, 22, 1, 18, 11,
    22, 17, 18, 11, 12, 14, 14, 13, 13, 10, 18, 17, 22, 3,  16, 1,
};

uint32_t popcnt_time[N] = {};

extern void asmHello();
extern uint8_t popcnt(uint32_t a);
extern uint8_t popcnt_secure(uint32_t a);

uint32_t time_variance() {
    uint32_t mean = 0;
    for (int i = 0; i < N; i++) {
        mean += popcnt_time[i];
    }
    mean /= N;

    uint32_t variance = 0;
    for (int i = 0; i < N; i++) {
        uint32_t s = (popcnt_time[i] - mean);
        variance += s * s;
    }
    variance /= N;
    return variance;
}

uint32_t get_mcycle() {
    uint32_t mcycle;
    asm volatile("csrr %0, mcycle" : "=r"(mcycle));
    return mcycle;
}

int main() {
    // Enable interrupts, but disable pesky timer interrupts
    asm volatile("csrc mie, %0" : : "r"(0x80));
    interrupt_enable();

#if STEP1
    asmHello();
#endif

#if STEP2
    print("Testing popcnt:\n");
    uint32_t popcnt_fails = 0;
    for (int i = 0; i < N; i++) {
        uint32_t start_cycles = get_mcycle();
        uint8_t output = popcnt(input[i]);
        popcnt_time[i] = get_mcycle() - start_cycles;
        if (output != expected[i]) {
            popcnt_fails++;
            print("Unexpected output for %x: Expected %d, got %d\n", input[i],
                  expected[i], output);
        }
    }
    if (popcnt_fails) {
        print("Total popcnt failures: %d\n", popcnt_fails);
    } else {
        print("All popcnt tests passed!\n");
        print("Variance of popcnt runtime cycles: %d\n", time_variance());

        print("Number of cycles to execute popcnt:\n");
        for (int i = 0; i < N / 8; i++) {
            for (int j = 0; j < N / 8; j++) {
                print("%d, ", popcnt_time[i * 8 + j]);
            }
            print("\n");
        }
    }

    print("\n");

    print("Testing popcnt_secure:\n");
    uint32_t popcnt_secure_fails = 0;
    for (int i = 0; i < N; i++) {
        uint32_t start_cycles = get_mcycle();
        uint8_t output = popcnt_secure(input[i]);
        popcnt_time[i] = get_mcycle() - start_cycles;
        if (output != expected[i]) {
            popcnt_secure_fails++;
            print("Unexpected output for %x: Expected %d, got %d\n", input[i],
                  expected[i], output);
        }
    }
    if (popcnt_secure_fails) {
        print("Total popcnt_secure failures: %d\n", popcnt_secure_fails);
    } else {
        print("All popcnt_secure tests passed!\n");
        print("Variance of popcnt_secure runtime: %d\n", time_variance());

        print("Number of cycles to execute popcnt_secure:\n");
        for (int i = 0; i < N / 8; i++) {
            for (int j = 0; j < N / 8; j++) {
                print("%d, ", popcnt_time[i * 8 + j]);
            }
            print("\n");
        }
    }
#endif

#if STEP3
#endif

    return popcnt_fails + popcnt_secure_fails;
}
