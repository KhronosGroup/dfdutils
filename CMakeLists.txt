cmake_minimum_required(VERSION 3.12)

option(BUILD_TESTS "Build test executables" OFF)
option(BUILD_DOCS "Build documentation" OFF)
option(HUNTER_ENABLED "Use the Hunter package manager" OFF)
option(BUILD_FOR_LIBKTX "Build dfdutils for use in KTX-Software" OFF)

if(HUNTER_ENABLED)
    include(cmake/HunterGate.cmake)
    HunterGate(
        URL "https://github.com/cpp-pm/hunter/archive/v0.23.309.tar.gz"
        SHA1 "15e84e1f23eb079360db727d373dab82890420b7"
    )
endif()

project(dfdutils VERSION 0.0.0)
set(VULKAN_HEADERS_VERSION "1.2.182" CACHE STRING "Version of Vulkan Headers to use (patch in third_party/ must apply).")

if(HUNTER_ENABLED)
    hunter_add_package(KhronosDataFormat)
    find_package(KhronosDataFormat CONFIG REQUIRED)

    hunter_add_package(Vulkan-Headers)
    find_package(VulkanHeaders CONFIG REQUIRED)

    get_target_property(DataFormat_INCLUDE_DIR Khronos::KhronosDataFormat INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(Vulkan_INCLUDE_DIR Vulkan::Headers INTERFACE_INCLUDE_DIRECTORIES)
else()
    include(FetchContent)
    FetchContent_Declare(
        khronosdataformat
        URL https://github.com/KhronosGroup/DataFormat/archive/1f8c8529b712e4b2b17bde798636d9ea550af3ed.tar.gz
    )
    FetchContent_Populate(khronosdataformat)
    file(INSTALL "${khronosdataformat_SOURCE_DIR}/headers/khr_df.h" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/third_party/KHR")
    set(DataFormat_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/third_party")

    FetchContent_Declare(
        vulkanheaders
        URL https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/v${VULKAN_HEADERS_VERSION}.tar.gz
    )
    FetchContent_Populate(vulkanheaders)
    file(INSTALL "${vulkanheaders_SOURCE_DIR}/include/vulkan" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/third_party")
    set(Vulkan_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/third_party")
endif()

set(GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake/modules/")

include(cmake/mkvk.cmake)

add_library(dfdutils STATIC)

set(DFDUTILS_HDR_FILES
    dfd.h
    ${GENERATED_DIR}/vkformat_enum.h
)

set(DFDUTILS_SRC_FILES
    colourspaces.c
    createdfd.c
    ${GENERATED_DIR}/dfd2vk.inl
    interpretdfd.c
    printdfd.c
    queries.c
    vk2dfd.c
    ${GENERATED_DIR}/vk2dfd.inl
    ${GENERATED_DIR}/vkformat_check.c
    ${GENERATED_DIR}/vkformat_str.c
)

# Introduce variables:
# * CMAKE_INSTALL_LIBDIR
# * CMAKE_INSTALL_BINDIR
# * CMAKE_INSTALL_INCLUDEDIR
include(GNUInstallDirs)

target_sources(dfdutils PRIVATE ${DFDUTILS_SRC_FILES} ${DFDUTILS_HDR_FILES})
if(HUNTER_ENABLED)
    target_link_libraries(dfdutils PRIVATE Vulkan::Headers)
    target_link_libraries(dfdutils PUBLIC Khronos::KhronosDataFormat)
endif()
target_include_directories(dfdutils PUBLIC
    $<BUILD_INTERFACE:${GENERATED_DIR}>)
target_include_directories(dfdutils PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/KhronosGroup>)
add_dependencies(dfdutils mkvk)
if(BUILD_FOR_LIBKTX)
    target_compile_definitions(dfdutils PUBLIC LIBKTX)
endif()

# Tests

if(BUILD_TESTS)
    add_executable(testcreatedfd test/createdfdtest.c)
    target_link_libraries(testcreatedfd PRIVATE dfdutils)

    add_executable(testinterpretdfd test/interpretdfdtest.c)
    target_link_libraries(testinterpretdfd PRIVATE dfdutils)

    add_executable(testbidirectionalmapping test/testbidirectionalmapping.c)
    target_link_libraries(testbidirectionalmapping PRIVATE dfdutils)
endif()

# Docs
if(BUILD_DOCS)
    find_package(Doxygen)
    if(DOXYGEN_FOUND)
        # set input and output files
        set(DOXYGEN_IN ${CMAKE_CURRENT_SOURCE_DIR}/dfdutils.doxy)
        set(DOXYGEN_OUT ${CMAKE_CURRENT_BINARY_DIR}/generated/Doxyfile)

        # request to configure the file
        configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)
        message("Doxygen build started")

        # note the option ALL which allows to build the docs together with the application
        add_custom_target(doc ALL
            COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Generating API documentation with Doxygen"
            VERBATIM
        )
    else(DOXYGEN_FOUND)
        message(FATAL_ERROR "Doxygen needs to be installed to generate the doxygen documentation")
    endif(DOXYGEN_FOUND)
endif()

# Installation

set(VERSION_CONFIG "${GENERATED_DIR}/${PROJECT_NAME}ConfigVersion.cmake")
set(PROJECT_CONFIG "${GENERATED_DIR}/${PROJECT_NAME}Config.cmake")

set(CONFIG_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")

set(TARGETS_EXPORT_NAME "${PROJECT_NAME}Targets")
set(NAMESPACE "KhronosGroup::")

include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${VERSION_CONFIG}" COMPATIBILITY ExactVersion
)

configure_package_config_file(
    "cmake/Config.cmake.in"
    "${PROJECT_CONFIG}"
    INSTALL_DESTINATION "${CONFIG_INSTALL_DIR}"
)

install(
    TARGETS dfdutils
    EXPORT "${TARGETS_EXPORT_NAME}"
    INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)

install(
    FILES ${DFDUTILS_HDR_FILES}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/KHR
)

if(NOT HUNTER_ENABLED)
    install(
        FILES "${GENERATED_DIR}/KHR/khr_df.h"
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/KHR
    )
    target_include_directories(dfdutils PUBLIC
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
endif()

install(
    FILES "${PROJECT_CONFIG}" "${VERSION_CONFIG}"
    DESTINATION "${CONFIG_INSTALL_DIR}"
)

install(
    EXPORT "${TARGETS_EXPORT_NAME}"
    NAMESPACE "${NAMESPACE}"
    DESTINATION "${CONFIG_INSTALL_DIR}"
)

if(BUILD_DOCS)
    install(
        DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/generated/doc/
        DESTINATION ${CMAKE_INSTALL_DOCDIR}
    )
endif()
