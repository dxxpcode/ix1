cmake_minimum_required(VERSION 3.21)
project(ix1-installer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
qt_standard_project_setup()

# Shared design-system kit (Theme, GradientText, ShimmerText, CheckMark,
# fonts, icons, logos) — one physical source in ../ix1-ui, compiled into
# this module like a locally owned file.
include(${CMAKE_CURRENT_SOURCE_DIR}/../ix1-ui/ix1-ui.cmake)

qt_add_executable(ix1-installer
    src/main.cpp
    src/backend.cpp
    src/backend.h
)

target_link_libraries(ix1-installer PRIVATE Qt6::Quick)

qt_add_qml_module(ix1-installer
    URI Ix1Installer
    VERSION 1.0
    QML_FILES
        ${IX1_UI_QML_FILES}
        qml/Main.qml
        qml/DestinationPage.qml
        qml/AccountPage.qml
        qml/DeployPage.qml
    RESOURCES
        ${IX1_UI_RESOURCES}
)

install(TARGETS ix1-installer RUNTIME DESTINATION bin)
