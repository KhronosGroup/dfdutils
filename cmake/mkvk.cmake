# Copyright 2015-2020 The Khronos Group Inc.
# SPDX-License-Identifier: Apache-2.0

# Code generation scripts that require a Vulkan SDK installation

set(skip_mkvk_message "-> skipping mkvk target (this is harmless; only needed when re-generating of vulkan headers and dfdutils is required)")

find_package(Perl)

if(NOT PERL_FOUND)
    message(STATUS "Perl not found ${skip_mkvk_message}")
    return()
endif()

get_target_property(Vulkan_INCLUDE_DIR Vulkan::Headers INTERFACE_INCLUDE_DIRECTORIES)
message("Vulkan include dir: ${Vulkan_INCLUDE_DIR}")

list(APPEND mkvkformatfiles_input
    "${Vulkan_INCLUDE_DIR}/vulkan/vulkan_core.h"
    "${PROJECT_SOURCE_DIR}/cmake/mkvkformatfiles")
list(APPEND mkvkformatfiles_output
    "${GENERATED_DIR}/vkformat_enum.h"
    "${GENERATED_DIR}/vkformat_check.c"
    "${GENERATED_DIR}/vkformat_str.c")

# What a shame! We have to duplicate most of the build commands because
# if(CMAKE_HOST_WIN32) can't appear inside add_custom_command.
if(CMAKE_HOST_WIN32)
    add_custom_command(OUTPUT ${mkvkformatfiles_output}
        COMMAND ${CMAKE_COMMAND} -E make_directory "${GENERATED_DIR}"
        COMMAND "${BASH_EXECUTABLE}" -c "Vulkan_INCLUDE_DIR=${Vulkan_INCLUDE_DIR} ${PROJECT_SOURCE_DIR}/cmake/mkvkformatfiles ${GENERATED_DIR}"
        COMMAND "${BASH_EXECUTABLE}" -c "unix2dos ${GENERATED_DIR}/vkformat_enum.h"
        COMMAND "${BASH_EXECUTABLE}" -c "unix2dos ${GENERATED_DIR}/vkformat_check.c"
        COMMAND "${BASH_EXECUTABLE}" -c "unix2dos ${GENERATED_DIR}/vkformat_str.c"
        DEPENDS ${mkvkformatfiles_input}
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        COMMENT "Generating VkFormat-related source files"
        VERBATIM
    )
else()
    add_custom_command(OUTPUT ${mkvkformatfiles_output}
        COMMAND ${CMAKE_COMMAND} -E make_directory "${GENERATED_DIR}"
        COMMAND Vulkan_INCLUDE_DIR=${Vulkan_INCLUDE_DIR} ${PROJECT_SOURCE_DIR}/cmake/mkvkformatfiles ${GENERATED_DIR}
        DEPENDS ${mkvkformatfiles_input}
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        COMMENT "Generating VkFormat-related source files"
        VERBATIM
    )
endif()

add_custom_target(mkvkformatfiles
    DEPENDS ${mkvkformatfiles_output}
    SOURCES ${mkvkformatfiles_input}
)

list(APPEND makevkswitch_input
    "${GENERATED_DIR}/vkformat_enum.h"
    "${PROJECT_SOURCE_DIR}/makevkswitch.pl")
set(makevkswitch_output
    "${GENERATED_DIR}/vk2dfd.inl")
if(CMAKE_HOST_WIN32)
    add_custom_command(
        OUTPUT ${makevkswitch_output}
        COMMAND ${CMAKE_COMMAND} -E make_directory "${GENERATED_DIR}"
        COMMAND "${PERL_EXECUTABLE}" makevkswitch.pl ${GENERATED_DIR}/vkformat_enum.h ${GENERATED_DIR}/vk2dfd.inl
        COMMAND "${BASH_EXECUTABLE}" -c "unix2dos ${GENERATED_DIR}/vk2dfd.inl"
        DEPENDS ${makevkswitch_input}
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        COMMENT "Generating VkFormat/DFD switch body"
        VERBATIM
    )
else()
    add_custom_command(
        OUTPUT ${makevkswitch_output}
        COMMAND ${CMAKE_COMMAND} -E make_directory "${GENERATED_DIR}"
        COMMAND "${PERL_EXECUTABLE}" makevkswitch.pl ${GENERATED_DIR}/vkformat_enum.h ${GENERATED_DIR}/vk2dfd.inl
        DEPENDS ${makevkswitch_input}
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        COMMENT "Generating VkFormat/DFD switch body"
        VERBATIM
    )
endif()

add_custom_target(makevkswitch
    DEPENDS ${makevkswitch_output}
    SOURCES ${makevkswitch_input}
)


list(APPEND makedfd2vk_input
    "${GENERATED_DIR}/vkformat_enum.h"
    "makedfd2vk.pl")
list(APPEND makedfd2vk_output
    "${GENERATED_DIR}/dfd2vk.inl")

if(CMAKE_HOST_WIN32)
    add_custom_command(
        OUTPUT ${makedfd2vk_output}
        COMMAND ${CMAKE_COMMAND} -E make_directory "${GENERATED_DIR}"
        COMMAND "${PERL_EXECUTABLE}" makedfd2vk.pl ${GENERATED_DIR}/vkformat_enum.h ${GENERATED_DIR}/dfd2vk.inl
        COMMAND "${BASH_EXECUTABLE}" -c "unix2dos ${GENERATED_DIR}/dfd2vk.inl"
        DEPENDS ${makedfd2vk_input}
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        COMMENT "Generating DFD/VkFormat switch body"
        VERBATIM
    )
else()
    add_custom_command(
        OUTPUT ${makedfd2vk_output}
        COMMAND ${CMAKE_COMMAND} -E make_directory "${GENERATED_DIR}"
        COMMAND "${PERL_EXECUTABLE}" makedfd2vk.pl ${GENERATED_DIR}/vkformat_enum.h ${GENERATED_DIR}/dfd2vk.inl
        DEPENDS ${makedfd2vk_input}
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        COMMENT "Generating DFD/VkFormat switch body"
        VERBATIM
    )
endif()

add_custom_target(makedfd2vk
    DEPENDS ${makedfd2vk_output}
    SOURCES ${makedfd2vk_input}
)

add_custom_target(mkvk SOURCES ${CMAKE_CURRENT_LIST_FILE})

add_dependencies(mkvk
    mkvkformatfiles
    makevkswitch
    makedfd2vk
)
