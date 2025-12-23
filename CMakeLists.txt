cmake_minimum_required(VERSION 3.10)
project(dfdutils C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Output directory used for all build artifacts
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

include_directories(${CMAKE_SOURCE_DIR})

# Optional VULKAN_SDK include directory
if(DEFINED ENV{VULKAN_SDK})
    include_directories($ENV{VULKAN_SDK}/include)
endif()

#
# --- Object files for switch generation ---
#
add_library(vk2dfd_obj OBJECT vk2dfd.c)
add_library(dfd2vk_obj OBJECT dfd2vk.c)

#
# --- DFD Utils library ---
#
add_library(dfdutils STATIC 
    createdfd.c
    colourspaces.c
    dfd.h
    interpretdfd.c
    printdfd.c
    queries.c
    vk2dfd.c
    vk2dfd.inl
    vulkan/vk_platform.h
    vulkan/vulkan_core.h)

#
# --- CHECK FOR PERL ---
#
find_package(Perl)
if (Perl_FOUND)
    message(STATUS "Perl found: ${PERL_EXECUTABLE}")


    #
    # --- GENERATE dfd2vk.inl ---
    #
    add_custom_command(
            OUTPUT ${CMAKE_SOURCE_DIR}/dfd2vk.inl
            COMMAND ${PERL_EXECUTABLE} ${CMAKE_SOURCE_DIR}/makedfd2vk.pl
            ${CMAKE_SOURCE_DIR}/vulkan/vulkan_core.h
            ${CMAKE_SOURCE_DIR}/dfd2vk.inl
            DEPENDS makedfd2vk.pl vulkan/vulkan_core.h
            COMMENT "Generating dfd2vk.inl using makedfd2vk.pl"
    )

    add_custom_target(dfd2vk_inl
            DEPENDS ${CMAKE_SOURCE_DIR}/dfd2vk.inl
    )

    #
    # --- GENERATE vk2dfd.inl ---
    #
    add_custom_command(
            OUTPUT ${CMAKE_SOURCE_DIR}/vk2dfd.inl
            COMMAND ${PERL_EXECUTABLE} ${CMAKE_SOURCE_DIR}/makevk2dfd.pl
            ${CMAKE_SOURCE_DIR}/vulkan/vulkan_core.h
            ${CMAKE_SOURCE_DIR}/vk2dfd.inl
            DEPENDS makevk2dfd.pl vulkan/vulkan_core.h
            COMMENT "Generating vk2dfd.inl using makevk2dfd.pl"
    )

    add_custom_target(vk2dfd_inl
            DEPENDS ${CMAKE_SOURCE_DIR}/vk2dfd.inl
    )

    add_custom_target(switches
            DEPENDS
            dfd2vk_inl
            vk2dfd_inl
    )

    add_dependencies(dfd2vk_inl dfd2vk_obj)
    add_dependencies(vk2dfd_inl vk2dfd_obj)
else()
    message(STATUS "Perl NOT found — using pre-existing inline switches.")
endif()

#
# --- Build testcreatedfd ---
#
add_executable(testcreatedfd
    createdfdtest.c
)
target_compile_options(testcreatedfd PRIVATE -W -Wall -pedantic -O2 -Wno-strict-aliasing -Wno-unused-parameter)
target_link_libraries(testcreatedfd PRIVATE dfdutils)

#
# --- Build testinterpretdfd ---
#
add_executable(testinterpretdfd
    interpretdfdtest.c
)
target_compile_options(testinterpretdfd PRIVATE -W -Wall -pedantic -O -Wno-unused-parameter)
target_link_libraries(testinterpretdfd PRIVATE dfdutils)

#
# --- Build testbidirectionalmapping ---
#
add_executable(testbidirectionalmapping
    testbidirectionalmapping.c
)
target_compile_options(testbidirectionalmapping PRIVATE -W -Wall -pedantic -g -Wno-unused-parameter)
target_link_libraries(testbidirectionalmapping PRIVATE dfdutils)

#
# --- DOXYGEN TARGET ---
#
find_package(Doxygen)
if(DOXYGEN_FOUND)
    add_custom_target(doc
        COMMAND ${DOXYGEN_EXECUTABLE} ${CMAKE_SOURCE_DIR}/dfdutils.doxy
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Running Doxygen to build documentation"
    )
else()
    message(WARNING "Doxygen not found. 'doc' target will not be available.")
endif()