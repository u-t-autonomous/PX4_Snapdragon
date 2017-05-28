
set(builtin_apps_string)
set(builtin_apps_decl_string)
set(command_count 0)

set(module_list)
list(APPEND module_list
	${module_libraries}
	${config_extra_builtin_cmds}
	)
list(SORT module_list)

foreach(module ${module_list})
	foreach(property MAIN STACK_MAIN PRIORITY)
		get_target_property(${property} ${module} ${property})
	endforeach()
	if (MAIN)
		set(builtin_apps_string "${builtin_apps_string}\t{\"${MAIN}\", ${PRIORITY}, ${STACK_MAIN}, ${MAIN}_main},\n")
		set(builtin_apps_decl_string "${builtin_apps_decl_string}extern int ${MAIN}_main(int argc, char *argv[]);\n")
		math(EXPR command_count "${command_count}+1")
	endif()
endforeach()

configure_file(${PX4_SOURCE_DIR}/cmake/nuttx/builtin_commands.c.in builtin_commands.c)

# add executable
set(fw_name "${BOARD}")
add_executable(${fw_name} builtin_commands.c)

# build NuttX
set(NUTTX_CONFIG ${BOARD})
set(NUTTX_CONFIG_TYPE ${config_nuttx_config})
set(NUTTX_EXPORT_DIR ${PX4_BINARY_DIR}/${BOARD}/nuttx-export)
add_subdirectory(${PX4_SOURCE_DIR}/NuttX ${BOARD}_build)
add_dependencies(${fw_name} apps_${BOARD} nuttx_${BOARD})

#
# Bootloaders use a different ld file, a separate startup file
# and need to override the os version of sched_process_timer
set(startup_libs)

if ("${config_nuttx_config}" STREQUAL "bootloader")
	set(nuttx_ld_prefix "bootloader")
	set(nuttx_bootloader_wrapers "-Wl,-wrap,sched_process_timer -Wl,-wrap,sem_post -Wl,-wrap,sem_wait")

	list(APPEND startup_libs startup_${BOARD})

endif()

if (NOT ${BOARD} STREQUAL "sim")

	set_target_properties(${fw_name} PROPERTIES LINK_FLAGS
		"-T${PX4_SOURCE_DIR}/NuttX/configs/${BOARD}/scripts/${nuttx_ld_prefix}ld.script -Wl,-Map=${PX4_BINARY_DIR}/${BOARD}/main.map"
		)
endif()

set(romfs_lib)
if (NOT ${BOARD} STREQUAL "sim")
	if ("${romfs_used}" STREQUAL "y")
		message(STATUS "${BOARD} adding ROMFS ${config_romfs_root}")

		set(romfs_temp_dir ${PX4_BINARY_DIR}/ROMFS/${config_romfs_root})
		set(romfs_src_dir ${PX4_SOURCE_DIR}/ROMFS/${config_romfs_root})

		# directory setup
		# copy all romfs files, process airframes, prune comments
		file(GLOB_RECURSE init_airframes ${PX4_SOURCE_DIR}/ROMFS/${config_romfs_root}/*/[1-9]*)
		add_custom_command(OUTPUT ${romfs_temp_dir}/init.d/rcS ${romfs_temp_dir}/init.d/rc.autostart
			#COMMAND cmake -E remove_directory ${romfs_temp_dir}
			COMMAND cmake -E copy_directory ${romfs_src_dir} ${romfs_temp_dir}
			COMMAND ${PYTHON_EXECUTABLE} ${PX4_SOURCE_DIR}/Tools/px_process_airframes.py
				-a ${romfs_temp_dir}/init.d
				-s ${romfs_temp_dir}/init.d/rc.autostart
				--board ${BOARD}
			COMMAND ${PYTHON_EXECUTABLE} ${PX4_SOURCE_DIR}/Tools/px_romfs_pruner.py
				--folder ${romfs_temp_dir} --board ${BOARD}
			DEPENDS
				${romfs_src_files}
				${init_airframes}
				${PX4_SOURCE_DIR}/ROMFS/${config_romfs_root}/init.d/rcS
				${PX4_SOURCE_DIR}/Tools/px_process_airframes.py
			)
		add_custom_target(create_romfs DEPENDS ${romfs_temp_dir}/init.d/rcS ${romfs_temp_dir}/init.d/rc.autostart)
		if (config_io_board)
			add_dependencies(create_romfs fw_io)
		endif()

		# create romfs.bin
		add_custom_command(OUTPUT romfs.img
			COMMAND ${GENROMFS} -f romfs.img -d ${romfs_temp_dir} -V "NSHInitVol"
			DEPENDS ${romfs_temp_dir}/init.d/rcS ${romfs_temp_dir}/init.d/rc.autostart
			)

		# create romfs.o
		add_custom_command(OUTPUT romfs.o
			COMMAND ${OBJCOPY} -I binary -O elf32-littlearm -B arm romfs.img romfs.o
				--redefine-sym _binary_romfs_img_start=romfs_img
				--redefine-sym _binary_romfs_img_size=romfs_img_len
				--strip-symbol _binary_romfs_img_end
				--rename-section .data=.rodata
			DEPENDS romfs.img
			)

		add_library(romfs STATIC romfs.o)
		set_target_properties(romfs PROPERTIES LINKER_LANGUAGE C)

		set(romfs_lib romfs)
	endif()

	#
	# Bootloaders do not need .px4 or xml
	#
	if(NOT "${config_nuttx_config}" STREQUAL "bootloader")
		set(fw_file ${CMAKE_CURRENT_BINARY_DIR}/${BOARD}_${LABEL}.px4)

		add_custom_command(OUTPUT ${fw_file} ${fw_name}.bin
			COMMAND ${OBJCOPY} -O binary ${fw_name} ${fw_name}.bin
			COMMAND ${PYTHON_EXECUTABLE} ${PX4_SOURCE_DIR}/Tools/px_mkfw.py
				--prototype ${PX4_SOURCE_DIR}/Images/${BOARD}.prototype
				--git_identity ${PX4_SOURCE_DIR}
				--parameter_xml ${PX4_BINARY_DIR}/parameters.xml
				--airframe_xml ${PX4_BINARY_DIR}/airframes.xml
				--image ${fw_name}.bin > ${fw_file}
			DEPENDS ${fw_name}
			)
	endif()

	configure_file(gdbinit.in .gdbinit)

	add_custom_target(debug
		COMMAND ${GDB} $<TARGET_FILE:${fw_name}>
		DEPENDS ${fw_name} ${CMAKE_CURRENT_BINARY_DIR}/.gdbinit
		)

	add_custom_target(debug_tui
		COMMAND ${GDBTUI} $<TARGET_FILE:${fw_name}>
		DEPENDS ${fw_name} ${CMAKE_CURRENT_BINARY_DIR}/.gdbinit
		)

	add_custom_target(debug_ddd
		COMMAND ${DDD} --debugger ${GDB} $<TARGET_FILE:${fw_name}>
		DEPENDS ${fw_name} ${CMAKE_CURRENT_BINARY_DIR}/.gdbinit
		)

	add_custom_target(debug_io
		COMMAND ${GDB} ${fw_io_path}
		DEPENDS ${fw_name} ${CMAKE_CURRENT_BINARY_DIR}/.gdbinit
		)

	add_custom_target(debug_io_tui
		COMMAND ${GDBTUI} ${fw_io_path}
		DEPENDS ${fw_name} ${CMAKE_CURRENT_BINARY_DIR}/.gdbinit
		)

	add_custom_target(debug_io_ddd
		COMMAND ${DDD} --debugger ${GDB} ${fw_io_path}}
		DEPENDS ${fw_io} ${CMAKE_CURRENT_BINARY_DIR}/.gdbinit
		)

	if(NOT "${config_nuttx_config}" STREQUAL "bootloader")
		if ("${BOARD}" STREQUAL "aerofc-v1")
			px4_add_upload_aero(OUT upload OS ${OS} BOARD ${BOARD} BUNDLE ${fw_file})
		else()
			px4_add_upload(OUT upload OS ${OS} BOARD ${BOARD} BUNDLE ${fw_file})
		endif()
	endif()
endif()

if(NOT "${config_nuttx_config}" STREQUAL "bootloader")
	install(FILES ${fw_file} DESTINATION .)
endif()

target_link_libraries(${fw_name}
	-Wl,--warn-common
	-Wl,--gc-sections
	-Wl,--start-group
	${startup_libs}
	${module_libraries}
	${df_driver_libs}
	${config_extra_libs}
	${nuttx_bootloader_wrapers}
	apps_${BOARD}
	nuttx_${BOARD}
	m
	gcc
	${romfs_lib}
	-Wl,--end-group)

# print sizes
add_custom_command(TARGET ${fw_name} POST_BUILD
	COMMAND size ${fw_name}
	DEPENDS ${fw_name}
	)

# print weak symbols
add_custom_target(check_weak
	COMMAND ${NM} ${fw_name} | ${GREP} " w " | cat
	DEPENDS ${fw_name}
	VERBATIM
	)
