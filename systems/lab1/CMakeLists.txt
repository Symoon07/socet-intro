

set(CMAKE_C_COMPILER riscv64-unknown-elf-gcc)
set(CMAKE_CXX_COMPILER riscv64-unknown-elf-g++)

cmake_minimum_required(VERSION 3.13)
project(aftx07-tests)

enable_language(ASM)
include(CMakePrintHelpers)

set(COMMON_COMPILE_OPTIONS
    -march=rv32imc_zicsr_zifencei
    -mabi=ilp32
    -mcmodel=medany
    -static
    -nostdlib
    -nostartfiles
    -ffreestanding
    -ffunction-sections
    -fdata-sections
    -Wall
    -Wextra
    -pedantic
    -Os
    -Wl,--gc-sections
)

set(LINK_OPTIONS
    "-T${CMAKE_CURRENT_SOURCE_DIR}/link.ld"
    -Wl,--gc-sections
    -Wl,--warn-constructors
)

add_compile_options(${COMMON_COMPILE_OPTIONS})
add_link_options(${COMMON_COMPILE_OPTIONS} ${LINK_OPTIONS})

file(GLOB LIB_SOURCE aft-femtokernel/arch/aftx07/*.S aft-femtokernel/kernel/*.c)
file(GLOB LIB_HEADER aft-femtokernel/include/*.h)

cmake_print_variables(LIB_SOURCE)

file(GLOB APP_SOURCE src/*.c src/*.S)

set(targetname "main")
add_executable(${targetname} ${APP_SOURCE} ${LIB_SOURCE} ${LIB_HEADER})
target_include_directories(${targetname} PUBLIC aft-femtokernel/include)
set_target_properties(
    ${targetname}
    PROPERTIES
        SUFFIX ".elf"
)

add_custom_command(
    TARGET ${targetname}
    POST_BUILD
    COMMAND riscv64-unknown-elf-objcopy -O binary ${targetname}.elf ${targetname}.bin
    COMMAND riscv64-unknown-elf-objcopy -O binary ${targetname}.elf meminit.bin
    COMMAND riscv64-unknown-elf-objdump -d ${targetname}.elf > ${targetname}.dump
    COMMENT "Generating binary file and objdump"
)
