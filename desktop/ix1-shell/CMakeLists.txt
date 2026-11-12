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
)

install(TARGETS ix1-shell RUNTIME DESTINATION bin)
