cmake_minimum_required(VERSION 3.20)
project(kwin-effect-redrog-glass CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(QT_MAJOR_VERSION 6)
set(QT_DEFAULT_MAJOR_VERSION 6)

find_package(ECM REQUIRED NO_MODULE)
list(APPEND CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Widgets DBus)
find_package(KF6 REQUIRED COMPONENTS Config CoreAddons WindowSystem)
find_package(epoxy REQUIRED)
list(APPEND CMAKE_MODULE_PATH /usr/lib/cmake/KWin)
find_package(Libdrm REQUIRED)
find_package(KWin REQUIRED COMPONENTS kwin)

kcoreaddons_add_plugin(redrogglass INSTALL_NAMESPACE "kwin/effects/plugins"
    SOURCES effect/main.cpp effect/redrogglass.cpp)
target_include_directories(redrogglass PRIVATE effect)
target_link_libraries(redrogglass PRIVATE KWin::kwin Qt6::Core Qt6::Gui KF6::ConfigCore)
