cmake_minimum_required(VERSION 3.12)

include(cmake/HunterGate.cmake)
HunterGate(
    URL "https://github.com/cpp-pm/hunter/archive/v0.23.305.tar.gz"
    SHA1 "fc8d7a6dac2fa23681847b3872d88d3839b657b0"
)

project(dfdutils VERSION 0.0.0)

hunter_add_package(KhronosDataFormat)
find_package(KhronosDataFormat CONFIG REQUIRED)

hunter_add_package(Vulkan-Headers)
find_package(VulkanHeaders CONFIG REQUIRED)

set(GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")

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
target_link_libraries(dfdutils PRIVATE Vulkan::Headers)
target_link_libraries(dfdutils PUBLIC Khronos::KhronosDataFormat)
target_include_directories(dfdutils PRIVATE ${GENERATED_DIR})
target_include_directories(dfdutils PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}>)

set(VERSION_CONFIG "${GENERATED_DIR}/${PROJECT_NAME}ConfigVersion.cmake")
set(PROJECT_CONFIG "${GENERATED_DIR}/${PROJECT_NAME}Config.cmake")

set(CONFIG_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")

set(TARGETS_EXPORT_NAME "${PROJECT_NAME}Targets")
set(NAMESPACE "${PROJECT_NAME}::")

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
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
)

install(
    FILES "${PROJECT_CONFIG}" "${VERSION_CONFIG}"
    DESTINATION "${CONFIG_INSTALL_DIR}"
)

install(
    EXPORT "${TARGETS_EXPORT_NAME}"
    NAMESPACE "${NAMESPACE}"
    DESTINATION "${CONFIG_INSTALL_DIR}"
)