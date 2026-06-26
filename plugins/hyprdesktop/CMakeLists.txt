cmake_minimum_required(VERSION 3.19)

project(hyprdesktop
    DESCRIPTION "Desktop-mode floating overlay plugin for Hyprland"
    LANGUAGES CXX
    VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 26)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

find_package(PkgConfig REQUIRED)
# Hyprland pulls in its transitive deps; pixman/drm/pangocairo are needed for
# the window-decoration (titlebar) rendering path.
pkg_check_modules(deps REQUIRED IMPORTED_TARGET
    hyprland
    pixman-1
    libdrm
    pangocairo)

file(GLOB SRC CONFIGURE_DEPENDS "src/*.cpp")
add_library(hyprdesktop SHARED ${SRC})

target_link_libraries(hyprdesktop PRIVATE PkgConfig::deps)
target_compile_options(hyprdesktop PRIVATE -Wall -Wextra -Wno-unused-parameter)

# Emit "hyprdesktop.so" (no "lib" prefix) — the name hyprctl/hyprpm load by.
set_target_properties(hyprdesktop PROPERTIES PREFIX "")

install(TARGETS hyprdesktop
    LIBRARY DESTINATION "$ENV{HOME}/.config/hypr/plugins")
