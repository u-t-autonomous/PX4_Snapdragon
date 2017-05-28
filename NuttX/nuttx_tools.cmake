
set(NUTTX_FAKE_DIR ${CMAKE_CURRENT_BINARY_DIR}/nuttx)

set(chip_dir)

if (${CMAKE_SYSTEM_PROCESSOR} STREQUAL "cortex-m7")
	set(chip_dir "stm32f7")
elseif (${CMAKE_SYSTEM_PROCESSOR} STREQUAL "cortex-m4")
	set(chip_dir "stm32")
elseif (${CMAKE_SYSTEM_PROCESSOR} STREQUAL "cortex-m3")
	set(chip_dir "stm32")
endif()

# setup export directory
set(nuttx_export_link_stamp ${CMAKE_CURRENT_BINARY_DIR}/nuttx_mkexport.stamp)
add_custom_command(OUTPUT ${nuttx_export_link_stamp}

	COMMAND rm -rf ${NUTTX_EXPORT_DIR}
	COMMAND mkdir -p ${NUTTX_EXPORT_DIR}/include ${NUTTX_EXPORT_DIR}/libs

	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/include/* ${NUTTX_EXPORT_DIR}/include/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/include/nuttx/lib/math.h ${NUTTX_EXPORT_DIR}/include/

	COMMAND mkdir -p ${NUTTX_EXPORT_DIR}/include/arch/board/
	COMMAND cp -arlf ${NUTTX_DIR}/configs/${NUTTX_CONFIG}/include/* ${NUTTX_EXPORT_DIR}/include/arch/board/

	# arch/arm/include/ -> include/arch/

	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/arch/arm/include/*.h ${NUTTX_EXPORT_DIR}/include/arch/

	COMMAND mkdir -p ${NUTTX_EXPORT_DIR}/include/arch/armv7-m/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/arch/arm/include/armv7-m/*.h ${NUTTX_EXPORT_DIR}/include/arch/armv7-m/

	COMMAND mkdir -p ${NUTTX_EXPORT_DIR}/include/arch/${chip_dir}/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/arch/arm/include/${chip_dir}/*.h ${NUTTX_EXPORT_DIR}/include/arch/${chip_dir}/

	# rename ${chip_dir} to chip
	COMMAND mkdir -p ${NUTTX_EXPORT_DIR}/include/arch/chip/chip
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/arch/arm/include/${chip_dir}/*.h ${NUTTX_EXPORT_DIR}/include/arch/chip/

	COMMAND mkdir -p  ${NUTTX_EXPORT_DIR}/arch/armv7-m
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/arch/arm/src/armv7-m/*.h ${NUTTX_EXPORT_DIR}/arch/armv7-m/

	COMMAND mkdir -p  ${NUTTX_EXPORT_DIR}/arch/common
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/arch/arm/src/common/*.h ${NUTTX_EXPORT_DIR}/arch/common/

	# rename ${chip_dir} to chip
	COMMAND mkdir -p ${NUTTX_EXPORT_DIR}/arch/chip/chip
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/arch/arm/src/${chip_dir}/*.h ${NUTTX_EXPORT_DIR}/arch/chip/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/arch/arm/src/${chip_dir}/chip/*.h ${NUTTX_EXPORT_DIR}/arch/chip/chip/

	# clock environ group init irq mqueue paging pthread sched semaphore signal task timer wdog
	COMMAND mkdir -p ${NUTTX_EXPORT_DIR}/arch/os/
	COMMAND cd ${NUTTX_EXPORT_DIR}/arch/os/ && mkdir clock environ group init irq mqueue paging pthread sched semaphore signal task timer wdog
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/sched/clock/*.h ${NUTTX_EXPORT_DIR}/arch/os/clock/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/sched/environ/*.h ${NUTTX_EXPORT_DIR}/arch/os/environ/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/sched/group/*.h ${NUTTX_EXPORT_DIR}/arch/os/group/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/sched/init/*.h ${NUTTX_EXPORT_DIR}/arch/os/init/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/sched/irq/*.h ${NUTTX_EXPORT_DIR}/arch/os/irq/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/sched/mqueue/*.h ${NUTTX_EXPORT_DIR}/arch/os/mqueue/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/sched/paging/*.h ${NUTTX_EXPORT_DIR}/arch/os/paging/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/sched/pthread/*.h ${NUTTX_EXPORT_DIR}/arch/os/pthread/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/sched/sched/*.h ${NUTTX_EXPORT_DIR}/arch/os/sched/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/sched/semaphore/*.h ${NUTTX_EXPORT_DIR}/arch/os/semaphore/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/sched/signal/*.h ${NUTTX_EXPORT_DIR}/arch/os/signal/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/sched/task/*.h ${NUTTX_EXPORT_DIR}/arch/os/task/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/sched/timer/*.h ${NUTTX_EXPORT_DIR}/arch/os/timer/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/sched/wdog/*.h ${NUTTX_EXPORT_DIR}/arch/os/wdog/

	# copy configure.sh, version.sh, CONFIG
	COMMAND mkdir -p ${NUTTX_FAKE_DIR}/tools ${NUTTX_FAKE_DIR}/configs ${NUTTX_FAKE_DIR}/../apps
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/tools/configure.sh ${NUTTX_FAKE_DIR}/tools/
	COMMAND cp -arlf ${NUTTX_DIR}/nuttx/tools/version.sh ${NUTTX_FAKE_DIR}/tools/
	COMMAND cp -arlf ${NUTTX_DIR}/configs/${NUTTX_CONFIG} ${NUTTX_FAKE_DIR}/configs/

	COMMAND cmake -E touch ${nuttx_export_link_stamp}
	)
add_custom_target(nuttx_mkexport_${NUTTX_CONFIG} DEPENDS ${nuttx_export_link_stamp})

# TODO: glob all export files
#set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES hello.bin)


# nuttx configure
add_custom_command(OUTPUT ${NUTTX_FAKE_DIR}/.config
	COMMAND sh configure.sh ${NUTTX_CONFIG}/${NUTTX_CONFIG_TYPE}
	DEPENDS nuttx_mkexport_${NUTTX_CONFIG} ${NUTTX_DIR}/configs/${NUTTX_CONFIG}/${NUTTX_CONFIG_TYPE}/defconfig
	COMMENT "Configuring NuttX for ${NUTTX_CONFIG} with ${NUTTX_CONFIG_TYPE}"
	WORKING_DIRECTORY ${NUTTX_FAKE_DIR}/tools
	)
add_custom_target(nuttx_configure_${NUTTX_CONFIG} DEPENDS ${NUTTX_FAKE_DIR}/.config)

# mkconfig
add_custom_command(OUTPUT ${NUTTX_EXPORT_DIR}/include/nuttx/config.h ${CMAKE_CURRENT_BINARY_DIR}/mkconfig
	COMMAND gcc -Wall -DHAVE_STRTOK_C=1 -o ${CMAKE_CURRENT_BINARY_DIR}/mkconfig ${NUTTX_DIR}/nuttx/tools/mkconfig.c ${NUTTX_DIR}/nuttx/tools/cfgdefine.c
	COMMAND ${CMAKE_CURRENT_BINARY_DIR}/mkconfig ${NUTTX_FAKE_DIR} > ${NUTTX_EXPORT_DIR}/include/nuttx/config.h
	DEPENDS ${NUTTX_FAKE_DIR}/.config ${nuttx_export_link_stamp}
	)
set_source_files_properties(${NUTTX_EXPORT_DIR}/include/nuttx/config.h PROPERTIES GENERATED TRUE)
add_custom_target(nuttx_mkconfig_${NUTTX_CONFIG} DEPENDS ${NUTTX_EXPORT_DIR}/include/nuttx/config.h)

# mkversion
add_custom_command(OUTPUT ${NUTTX_FAKE_DIR}/.version ${CMAKE_CURRENT_BINARY_DIR}/mkversion ${NUTTX_EXPORT_DIR}/include/nuttx/version.h
	COMMAND ${NUTTX_FAKE_DIR}/tools/version.sh -v 0.0 -b 0 ${NUTTX_FAKE_DIR}/.version
	COMMAND gcc -Wall -DHAVE_STRTOK_C=1 -o ${CMAKE_CURRENT_BINARY_DIR}/mkversion ${NUTTX_DIR}/nuttx/tools/mkversion.c ${NUTTX_DIR}/nuttx/tools/cfgdefine.c
	COMMAND ${CMAKE_CURRENT_BINARY_DIR}/mkversion ${NUTTX_FAKE_DIR} > ${NUTTX_EXPORT_DIR}/include/nuttx/version.h
	DEPENDS ${NUTTX_FAKE_DIR}/.config ${nuttx_export_link_stamp}
	)
set_source_files_properties(${NUTTX_EXPORT_DIR}/include/nuttx/version.h PROPERTIES GENERATED TRUE)
add_custom_target(nuttx_mkversion_${NUTTX_CONFIG} DEPENDS ${NUTTX_EXPORT_DIR}/include/nuttx/version.h)

add_custom_target(nuttx_setup_${NUTTX_CONFIG} DEPENDS nuttx_mkconfig_${NUTTX_CONFIG} nuttx_mkversion_${NUTTX_CONFIG})
