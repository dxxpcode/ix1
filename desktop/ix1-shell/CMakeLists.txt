cmake_minimum_required(VERSION 3.21)
project(ix1-shell LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick DBus)
qt_standard_project_setup()

qt_add_executable(ix1-shell
    src/main.cpp
    src/backend.cpp
    src/backend.h
    src/notifications.cpp
    src/notifications.h
)

target_link_libraries(ix1-shell PRIVATE
    Qt6::Quick
    Qt6::DBus
    pam
)

set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(ix1-shell
    URI Ix1Shell
    VERSION 1.0
    QML_FILES
        qml/Theme.qml
        qml/AppIcon.qml
        qml/Wallpaper.qml
        qml/Panel.qml
        qml/Dock.qml
        qml/Launcher.qml
        qml/QuickSettings.qml
        qml/Notifications.qml
        qml/LockScreen.qml
    RESOURCES
        qml/assets/wallpaper-graphite.png
        qml/assets/wallpaper-porcelain.png
        qml/assets/logo-dark.png
        qml/assets/logo-light.png
        qml/assets/icons/bars-dark.svg
        qml/assets/icons/bars-light.svg
        qml/assets/icons/browser-dark.svg
        qml/assets/icons/browser-light.svg
        qml/assets/icons/editor-dark.svg
        qml/assets/icons/editor-light.svg
        qml/assets/icons/files-dark.svg
        qml/assets/icons/files-light.svg
        qml/assets/icons/grid-dark.svg
        qml/assets/icons/grid-light.svg
        qml/assets/icons/monitor-dark.svg
        qml/assets/icons/monitor-light.svg
        qml/assets/icons/pulse-dark.svg
        qml/assets/icons/pulse-light.svg
        qml/assets/icons/settings-dark.svg
        qml/assets/icons/settings-light.svg
        qml/assets/icons/terminal-dark.svg
        qml/assets/icons/terminal-light.svg
)

install(TARGETS ix1-shell RUNTIME DESTINATION bin)
