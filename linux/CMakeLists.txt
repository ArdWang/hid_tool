# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10...3.20)

# Project-level configuration.
set(PROJECT_NAME "hid_tool")
project(${PROJECT_NAME} LANGUAGES C)

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.10...3.20)

# Add hidapi subdirectory (embedded source, no git submodule required)
get_filename_component(THIS_FILE_DIR "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(PLUGIN_ROOT_DIR "${THIS_FILE_DIR}/.." ABSOLUTE)
add_subdirectory("${PLUGIN_ROOT_DIR}/third_party/hidapi" "${CMAKE_CURRENT_BINARY_DIR}/hidapi")

# Find required packages
find_package(PkgConfig REQUIRED)
pkg_check_modules(UDEV REQUIRED IMPORTED_TARGET libudev)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "hid_tool_plugin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "hid_tool_plugin.cc"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  ${PLUGIN_SOURCES}
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)
target_link_libraries(${PLUGIN_NAME} PRIVATE hidapi::hidapi)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::UDEV)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(hid_tool_bundled_libraries
  ""
  PARENT_SCOPE
)