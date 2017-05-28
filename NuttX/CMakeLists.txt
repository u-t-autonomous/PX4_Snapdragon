cmake_minimum_required(VERSION 3.2)

if(NOT NUTTX_CONFIG)
	message(FATAL_ERROR "NUTTX_CONFIG must be set (eg px4fmu-v2)")
endif()

if(NOT NUTTX_CONFIG_TYPE)
	message(FATAL_ERROR "NUTTX_CONFIG_TYPE must be set (eg nsh or bootloader)")
endif()

set(NUTTX_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(NUTTX_EXPORT_DIR ${CMAKE_BINARY_DIR}/${NUTTX_CONFIG}/nuttx-export)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${NUTTX_EXPORT_DIR}/libs)

# TODO - move processor handling into toolchain file
set(cpu_flags)
if (${config_nuttx_hw} STREQUAL "m7")
	set(CMAKE_SYSTEM_PROCESSOR "cortex-m7")
	list(APPEND cpu_flags
		-mcpu=cortex-m7
		-mthumb
		-mfpu=fpv5-sp-d16
		-mfloat-abi=hard
		)
elseif (${config_nuttx_hw} STREQUAL "m4")
	set(CMAKE_SYSTEM_PROCESSOR "cortex-m4")
	list(APPEND cpu_flags
		-mcpu=cortex-m4
		-mthumb
		-march=armv7e-m
		-mfpu=fpv4-sp-d16
		-mfloat-abi=hard
		)
elseif (${config_nuttx_hw} STREQUAL "m3")
	set(CMAKE_SYSTEM_PROCESSOR "cortex-m3")
	list(APPEND cpu_flags
		-mcpu=cortex-m3
		-mthumb
		-march=armv7-m
		)
endif()

set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../cmake/toolchains/Toolchain-arm-none-eabi.cmake")

project(NuttX_${NUTTX_CONFIG} LANGUAGES ASM C CXX)

message(STATUS "NuttX: " ${NUTTX_CONFIG} " " ${NUTTX_CONFIG_TYPE} " " ${CMAKE_SYSTEM_PROCESSOR})

set_directory_properties(PROPERTIES
	INCLUDE_DIRECTORIES ""
	LINK_DIRECTORIES ""
	COMPILE_DEFINITIONS ""
	)

include_directories(SYSTEM ${NUTTX_EXPORT_DIR}/include)

add_compile_options(
	-Wall
	-Wdouble-promotion
	-Werror
	-Wextra
	-Wframe-larger-than=1024
	-Wlogical-op
	-Wpacked
	-Wpointer-arith
	-Wshadow

	-Wno-cpp
	-Wno-sign-compare
	-Wno-unused-parameter

	-fdata-sections
	-ffunction-sections
	-fno-builtin-printf
	-fno-common
	-fno-strength-reduce
	-fno-strict-aliasing
	-fomit-frame-pointer
	-funsafe-math-optimizations

	-Os
	-g

	${cpu_flags}
	)

set(c_flags
	-std=c99
	-Wmissing-parameter-type
	-Wnested-externs
	-Wstrict-prototypes

	-Wno-implicit-function-declaration
	-Wno-missing-field-initializers
	-Wno-nested-externs
	-Wno-type-limits

	# TODO: remove
	-Wno-unused-variable
	-Wno-missing-prototypes
	)
set(CMAKE_C_FLAGS "")
add_compile_options("$<$<COMPILE_LANGUAGE:C>:${c_flags}>")

set(CMAKE_CXX_FLAGS "")
set(cxx_flags
	-std=c++11
	-fno-exceptions
	-fno-rtti
	)
add_compile_options("$<$<COMPILE_LANGUAGE:CXX>:${cxx_flags}>")

set(asm_flags ${c_flags}
	-D__ASSEMBLY__
	)
add_compile_options("$<$<COMPILE_LANGUAGE:ASM>:${asm_flags}>")

include(nuttx_tools.cmake)

add_subdirectory(apps)
add_subdirectory(nuttx)
